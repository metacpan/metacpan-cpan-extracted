#!/usr/bin/env perl
# t/131-error-values-language-live.t -- LIVE. The values of a statement stay
# out of the exceptions the storage throws when the server reports in another
# language than English, over each access path.
#
# WHY this matters: SQL Server writes its messages in the language of the
# session (SET LANGUAGE, the login's or the server's default) and quotes the
# offending value in them, also when the value was a bind -- 'Fehler beim
# Konvertieren des varchar-Werts "ab" in den int-Datentyp.', 'Valeur de clé
# dupliquée : (ab).'. The family's rule is that a message names keys, columns
# and options, never values (core ADR 0075), whatever the language. The
# English wording of the sentence rules does not hold there; the masking goes
# by the number of the message and the marks the server quotes with (t/132
# without a server). Each form is provoked under Deutsch and Francais through
# the storage API; the exception text must not hold the value -- short ones
# too, which the bound-value pass does not look for -- and the names (table,
# constraint, column) and the "with N bind value(s)" must still be there. The
# statement that DBIO appends ("[for Statement ...]") is the statement's and
# is not looked at.
#
# Access paths (each skips without its environment):
#   DBD::ODBC                   DBIO_TEST_MSSQL_ODBC_DSN / _USER / _PASS
#   DBD::Sybase                 DBIO_TEST_MSSQL_DSN / _USER / _PASS
#   DBD::Sybase, no placeholders (NoBindVars)
#
# Only objects named dbio_fl_* are made, and they are dropped again.

use strict;
use warnings;

use Test::More;
use lib 't/lib';
use MssqlServerLanguage ();
use DBI;
use DBIO::Optional::Dependencies ();
use DBIO::Schema;

my %ENV_PREFIX = (
  'DBD::Sybase' => 'DBIO_TEST_MSSQL',
  'DBD::ODBC'   => 'DBIO_TEST_MSSQL_ODBC',
);

my %CONNECT;
for my $dbd (keys %ENV_PREFIX) {
  my ($dsn, $user, $pass) = @ENV{ map { "$ENV_PREFIX{$dbd}_$_" } qw/DSN USER PASS/ };
  $CONNECT{$dbd} = [ $dsn, $user, $pass ] if $dsn and defined $user and defined $pass;
}

plan skip_all => 'Set $ENV{DBIO_TEST_MSSQL_DSN} or $ENV{DBIO_TEST_MSSQL_ODBC_DSN}, with _USER and _PASS, to run this test'
  unless %CONNECT;

if ($CONNECT{'DBD::Sybase'}) {
  if (not DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_sybase')) {
    diag 'DBD::Sybase is not looked at: test needs '
       . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_sybase');
    delete $CONNECT{'DBD::Sybase'};
  }
  elsif (not eval { require DBIO::Sybase::Storage; 1 }) {
    die $@ unless $@ =~ m{\ACan't locate DBIO/Sybase/Storage\.pm };
    diag 'DBD::Sybase is not looked at: DBIO::Sybase is not installed';
    delete $CONNECT{'DBD::Sybase'};
  }
}

if ($CONNECT{'DBD::ODBC'}
    and not DBIO::Optional::Dependencies->req_ok_for('test_rdbms_mssql_odbc')) {
  diag 'DBD::ODBC is not looked at: test needs '
     . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_mssql_odbc');
  delete $CONNECT{'DBD::ODBC'};
}

plan skip_all => 'Neither access path has what it needs installed' unless %CONNECT;

local $ENV{DBIO_MSSQL_FREETDS_LOWVER_NOWARN} = 1;
local $SIG{__WARN__} = sub {
  warn $_[0] unless $_[0] =~ /compiled against buggy FreeTDS version/;
};

{
  package T::FL::Result::T;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_fl_t');
  __PACKAGE__->add_columns(
    id => { data_type => 'integer', is_auto_increment => 1 },
    n  => { data_type => 'integer', is_nullable => 1 },
    ti => { data_type => 'tinyint', is_nullable => 1 },
    s  => { data_type => 'varchar', size => 5, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('id');
}

{
  package T::FL::Result::K;
  use base 'DBIO::Core';
  __PACKAGE__->table('dbio_fl_k');
  __PACKAGE__->add_columns(
    k => { data_type => 'varchar', size => 40 },
    u => { data_type => 'varchar', size => 40, is_nullable => 1 },
  );
  __PACKAGE__->set_primary_key('k');
}

{
  package T::FL::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('MSSQL');
  __PACKAGE__->register_class(T => 'T::FL::Result::T');
  __PACKAGE__->register_class(K => 'T::FL::Result::K');
}

my %ADMIN;
sub admin {
  my $dbd = shift;
  return $ADMIN{$dbd} ||= do {
    my $dbh = DBI->connect(@{ $CONNECT{$dbd} }, {
      RaiseError => 1, PrintError => 0, AutoCommit => 1,
    });
    $dbh->do('SET LOCK_TIMEOUT 10000');
    $dbh;
  };
}

my @TABLES = qw(dbio_fl_t dbio_fl_k);

sub drop_tables {
  my $dbd = shift;
  admin($dbd)->do("IF OBJECT_ID('$_', 'U') IS NOT NULL DROP TABLE $_") for @TABLES;
}

sub create_tables {
  my $dbd = shift;
  drop_tables($dbd);
  admin($dbd)->do($_) for (
    'CREATE TABLE dbio_fl_t (id INT IDENTITY PRIMARY KEY, n INT NULL, ti TINYINT NULL, s VARCHAR(5) NULL)',
    'CREATE TABLE dbio_fl_k (k VARCHAR(40) NOT NULL, u VARCHAR(40) NULL,'
  . ' CONSTRAINT pk_dbio_fl_k PRIMARY KEY (k), CONSTRAINT uq_dbio_fl_k_u UNIQUE (u))',
  );
}

my $MORE = qr/with \d+ bind values?\b/;

# The marks the languages quote a value with. A value the server quotes is in
# one of them; a bare word is not looked for (it is part of any text).
sub quoted { my $v = shift; qr/(?:["'\x{AB}\x{201E}\x{201C}\x{201D}(]\s*\Q$v\E\s*["'\x{BB}\x{201C}\x{201D})])/ }

# name, code (gets the schema), values that must not stand in the text as the
# server quotes them, patterns the text must keep
my @CASES = (
  [ 'conversion failed, short value', sub { $_[0]->resultset('T')->create({ n => 'ab' }) },
    ['ab'], [$MORE, qr/varchar/, qr/\bint\b/] ],
  [ 'conversion failed, one character', sub { $_[0]->resultset('T')->create({ n => 'x' }) },
    ['x'], [$MORE, qr/varchar/] ],
  [ 'conversion failed, value with an apostrophe', sub { $_[0]->resultset('T')->create({ n => "a'b" }) },
    ["a'b"], [$MORE, qr/varchar/] ],
  [ 'overflow', sub { $_[0]->resultset('T')->create({ ti => '3000000000' }) },
    ['3000000000'], [$MORE, qr/INT1|tinyint/i] ],  # NoBindVars: the number is in the statement, a plain overflow,
  [ 'primary key twice', sub { my $rs = $_[0]->resultset('K'); $rs->create({ k => 'ab' }); $rs->create({ k => 'ab' }) },
    ['ab'], [$MORE, qr/pk_dbio_fl_k/, qr/dbio_fl_k/, qr/number=2627|SQL-23000/] ],
  [ 'primary key twice, a longer value', sub { my $rs = $_[0]->resultset('K'); $rs->create({ k => 'geheim42' }); $rs->create({ k => 'geheim42' }) },
    ['geheim42'], [$MORE, qr/pk_dbio_fl_k/, qr/number=2627|SQL-23000/] ],
  [ 'unique constraint twice', sub { my $rs = $_[0]->resultset('K'); $rs->create({ k => 'a1', u => 'cd' }); $rs->create({ k => 'a2', u => 'cd' }) },
    ['cd'], [$MORE, qr/uq_dbio_fl_k_u/, qr/dbio_fl_k/] ],
  [ 'truncated', sub { $_[0]->resultset('T')->create({ s => 'qrstuvwx' }) },
    ['qrstu', 'qrstuvwx'], [$MORE, qr/dbio_fl_t/, qr/number=2628|SQL-42000/] ],
  [ 'syntax error near a value', sub { $_[0]->resultset('T')->search(\[ 's = ? ?', 'ok1234', 'zz' ])->all },
    ['zz'], [qr/with 2 bind values/] ],
  [ 'JSON character', sub { $_[0]->resultset('T')->search(\[ "JSON_VALUE(?, '\$.a') IS NULL", 'g' ])->all },
    ['g'], [$MORE] ],
);

# [ label, SET LANGUAGE name (the alias, ASCII), @@LANGID ]
my @LANGUAGES = ( [ 'Deutsch', 'German', 1 ], [ 'Francais', 'French', 2 ] );

my @WAYS;
push @WAYS, [ 'DBD::ODBC',                  'DBD::ODBC',   0 ] if $CONNECT{'DBD::ODBC'};
push @WAYS, [ 'DBD::Sybase',                'DBD::Sybase', 0 ] if $CONNECT{'DBD::Sybase'};
push @WAYS, [ 'DBD::Sybase (NoBindVars)',   'DBD::Sybase', 1 ] if $CONNECT{'DBD::Sybase'};

END {
  for my $dbd (keys %ADMIN) { eval { drop_tables($dbd) } }
}

for my $way (@WAYS) {
  my ($label, $dbd, $nobindvars) = @$way;

  for my $lang (@LANGUAGES) {
    my ($lname, $alias, $langid) = @$lang;
    create_tables($dbd);

    # on_connect_do runs after every (re)connect, behind the setting of
    # DBIO_TEST_SERVER_LANGUAGE: this test names its language itself
    my $schema = T::FL::Schema->connect(@{ $CONNECT{$dbd} }, { on_connect_do => "SET LANGUAGE $alias" });
    $schema->storage->_use_typeless_placeholders(0) if $nobindvars;
    $schema->storage->dbh;

    is $schema->storage->dbh->selectrow_array('SELECT @@LANGID'), $langid,
      "$label: the session reports in $lname";

    for my $case (@CASES) {
      my ($name, $code, $gone, $keep) = @$case;
      admin($dbd)->do("DELETE FROM $_") for @TABLES;

      my $err;
      eval { $code->($schema); 1 } and $err = undef or $err = $@;
      unless ($err) {
        fail "$label, $lname: $name: the statement is refused";
        next;
      }

      my $text = "$err";
      diag "$label, $lname: $name\n" . substr($text, 0, 700) if $ENV{DBIO_TEST_FW_DUMP};
      # the statement DBIO appends is the statement's
      (my $head = $text) =~ s/\s*\[for Statement ".*\z//s;

      my @leaks = grep { $head =~ quoted($_) } @$gone;
      push @leaks, grep { index($head, $_) >= 0 } grep { length > 4 } @$gone;
      ok !@leaks, "$label, $lname: $name: no value in the exception"
        or diag "leaked: @leaks\n---\n$head\n";

      for my $k (@$keep) {
        # a message whose words cannot be told from the value loses its
        # text and keeps its number (t/132): the names are then not there
        next if $head =~ /text withheld/ and $k !~ /number=|SQL-/ and $k ne $MORE;
        like $text, $k, "$label, $lname: $name: still says $k";
      }
    }
    $schema->storage->disconnect;
  }

  drop_tables($dbd);
}

done_testing;
