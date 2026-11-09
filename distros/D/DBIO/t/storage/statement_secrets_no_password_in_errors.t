# ABSTRACT: An error about a connect action quotes none of its secrets
use strict;
use warnings;

use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Util qw(mask_connect_secrets);

# karr k343 (maintainer's decision 2026-10-16): the statements of connect
# actions (on_connect_do, on_connect_call, PRAGMA key, ATTACH ... token=) and
# the errors that quote them never carry their secrets. SQLite quotes the
# token it choked on, `unrecognized token: "'SEKRET"`; DuckDB's ATTACH address
# carries token= in the statement.
#
# What this file claims:
#   1. a statement that is refused through _do_query -- on_connect_do or
#      on_connect_call -- throws a text without the secret: the value of
#      PRAGMA key = '...' / key='...', of token= in an ATTACH, and the
#      database's own quote of a part of it;
#   2. the exception keeps its class (DBIO::Exception::Server) and the rest of
#      the text -- the key, the statement's other words -- stays readable;
#   3. masking is idempotent;
#   4. a statement without a secret, and a placeholder bound to a column
#      called key, are left as they are (a statement text that names
#      password = ? is masked, as documented in
#      t/schema/stacktrace_own_builder.t).
#
# THE SUBSTITUTION: the mock storage runs no statement, so its dbh_do hands the
# callback a handle whose do() fails the way DBI does with a HandleError
# installed: through $storage->_dbi_handle_error, with the text a database
# would write. Nothing else is replaced.

{
  package T::K343Dbh;
  sub new { my ($c, $storage, $error) = @_; bless { storage => $storage, error => $error }, $c }
  sub do {
    my ($self, $sql) = @_;
    $self->{storage}->_dbi_handle_error($self->{error}->($sql), undef);
  }

  package T::K343Storage;
  our @ISA = ('DBIO::Test::Storage');
  sub dbh_do {
    my ($self, $code, @args) = @_;
    $code->($self, $self->{_k343_dbh}, @args);
  }
}

sub storage_failing {
  my ($error) = @_;
  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = $schema->storage;
  bless $storage, 'T::K343Storage';
  $storage->{_k343_dbh} = T::K343Dbh->new($storage, $error);
  return $storage;
}

my $secret = 'SEKRET-pass 42';

# 1. PRAGMA key with a syntax error: SQLite quotes the token
{
  my $storage = storage_failing(sub {
    qq{DBD::SQLite::db do failed: unrecognized token: "'$secret"}
  });
  $storage->on_connect_do([ qq{PRAGMA key = '$secret} ]);
  throws_ok { $storage->_run_connection_actions }
    'DBIO::Exception::Server', 'the refused statement throws a server exception';
  my $text = "$@";
  unlike $text, qr/SEKRET/, 'PRAGMA key: the token is not in the error';
  unlike $text, qr/pass 42/, '... not the part after the whitespace';
  like $text, qr/unrecognized token/, '... and the error stays readable';
}

# 1b. the same through do_sql, the quoted and closed form, key=
{
  my $storage = storage_failing(sub {
    qq{near "x": syntax error [for Statement "$_[0]"]}
  });
  throws_ok { $storage->_do_query(qq{PRAGMA key='$secret' x}) }
    'DBIO::Exception::Server', 'the closed form throws';
  my $text = "$@";
  unlike $text, qr/SEKRET|pass 42/, 'key=: neither the statement quoted whole';
  like $text, qr/PRAGMA key='\*\*\*'? x|PRAGMA key=\*\*\*/, '... the key stays, the value is the mask';
}

# 1c. the function form
{
  my $storage = storage_failing(sub { qq{unrecognized token: "'$secret"} });
  throws_ok { $storage->_do_query(qq{PRAGMA key('$secret'}) } 'DBIO::Exception';
  unlike "$@", qr/SEKRET|pass 42/, 'PRAGMA key(...): masked';
}

# 2. ATTACH with token= in the address
{
  my $storage = storage_failing(sub {
    qq{IO Error: cannot attach "md:app?token=eyJhbGci.OiJ9-xyz" [$_[0]]}
  });
  throws_ok { $storage->_do_query(q{ATTACH 'md:app?token=eyJhbGci.OiJ9-xyz' AS app}) }
    'DBIO::Exception::Server', 'ATTACH refused';
  unlike "$@", qr/eyJhbGci/, 'ATTACH: the token is not in the error';
  like "$@", qr/token=\*\*\*/, '... the key stays';
  like "$@", qr/cannot attach/, '... and so does the rest';
}

# 2b. a connect_call that runs its statement through _do_query
{
  my $storage = storage_failing(sub { qq{unrecognized token: "'$secret"} });
  $storage->on_connect_call([ [ do_sql => qq{PRAGMA key = '$secret} ] ]);
  throws_ok { $storage->_run_connection_actions } 'DBIO::Exception';
  unlike "$@", qr/SEKRET|pass 42/, 'on_connect_call do_sql: masked';
}

# 2c. the pool runner of an async connection, a plain die
{
  my $storage = storage_failing(sub { die 'unused' });
  local $storage->{_pool_connect_runner} = sub { die qq{unrecognized token: "'$secret"\n} };
  throws_ok { $storage->_do_query(qq{PRAGMA key = '$secret}) } qr/unrecognized token/;
  unlike "$@", qr/SEKRET|pass 42/, 'pool runner die: masked';
}

# 3. idempotence
{
  my $sql  = q{PRAGMA key = 'hunter two'};
  my $once = DBIO::Util::mask_statement_secrets(qq{unrecognized token: "'hunter two" in $sql}, $sql);
  unlike $once, qr/hunter/, 'first pass masks';
  is DBIO::Util::mask_statement_secrets($once, $sql), $once, 'second pass changes nothing';
  is mask_connect_secrets($once), $once, 'nor does mask_connect_secrets';
}

# 4. normal text stays readable
{
  my $sql = q{SELECT * FROM users WHERE name = ? AND id = $1 ORDER BY key};
  is mask_connect_secrets($sql), $sql, 'an ordinary statement is untouched';
  my $bound = q{UPDATE users SET a = 1 WHERE key = ?};
  like DBIO::Util::mask_statement_secrets("failed: $bound", $bound), qr/failed: UPDATE users SET a = 1 WHERE/,
    'a placeholder is no secret value: the text around it stays';
  is DBIO::Util::mask_statement_secrets($sql, $sql), $sql, '... for a statement as well';

  my $plain = q{no such table: users};
  is DBIO::Util::mask_statement_secrets($plain, q{SELECT 1 FROM users}), $plain, 'an error without a secret is untouched';
}

done_testing;
