use strict;
use warnings;
use Test::More;

use DBIO::Test::Future ();
use DBIO::Deploy::Base;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# A comment in DDL text is treated on the async road as it is on the sync one
# (karr k326).
#
# DBIO::SQL::Util::_split_statements reads DDL as SQL: it takes a comment in
# front of a statement off it and does not deliver a piece that holds nothing
# but comments. The sync road, DBIO::Deploy::Base::_execute_ddl, runs what the
# splitter delivers and has no filter of its own. The async road had one at
# both of its places -- deploy_async on a transactional engine and
# _execute_ddl_async, which deploy_async on a non-transactional engine goes
# through -- that dropped what began with "--". Behind this splitter it could
# drop nothing any more, and it is gone.
#
# The claim: for the same DDL text, the statements that reach the wire on the
# async road are the statements that reach the handle on the sync road -- no
# comment piece among them, no statement lost to a comment in front of it or
# inside it, none cut at a semicolon that ends nothing. And a text that holds
# no statement at all is nothing to do on both roads, and no error.
#
# No database: a fake handle on the sync side, a fake wire on the async side.
# Against DBIO::Test::Future and, where installed, Future.pm.

# --- the sync side -----------------------------------------------------------
{
  package K55::DBH;
  sub new { bless { stmts => [] }, $_[0] }
  sub do  { push @{ $_[0]->{stmts} }, $_[1]; 1 }
}

# Not transactional: declares no capability at all.
{
  package K55::Storage;
  sub new  { bless { dbh => $_[1] }, $_[0] }
  sub dbh  { $_[0]->{dbh} }
  sub _dbh { $_[0]->{dbh} }
}

# Transactional. The bracket is written into the handle's log, so the sync log
# reads like the async wire, where BEGIN and COMMIT are statements.
{
  package K55::TxnStorage;
  our @ISA = ('K55::Storage');
  sub _use_transactional_ddl { 1 }
  sub txn_do {
    my ($self, $code) = @_;
    push @{ $self->{dbh}{stmts} }, 'BEGIN';
    my @r = $code->();
    push @{ $self->{dbh}{stmts} }, 'COMMIT';
    return @r;
  }
}

{
  package K55::Schema;
  sub new     { bless { storage => $_[1] }, $_[0] }
  sub storage { $_[0]->{storage} }
}

{
  package K55::Deploy;
  use base 'DBIO::Deploy::Base';
}

# --- the async side ----------------------------------------------------------
{
  package K55::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K55::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { K55::Conn->new(++$_[0]->{_next_id}) }
  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

{
  package K55::Owner;
  sub new { bless { txn => $_[1] }, $_[0] }
  sub _use_transactional_ddl { $_[0]->{txn} }
}

{
  package K55::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class { $_[0]->{fc} }
  sub _install_ddl { $_[0]->{ddl} }

  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= K55::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => $self->future_class,
    );
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{sent} }, $sql;
    return $self->future_class->done;
  }
}

my @warnings;
local $SIG{__WARN__} = sub {
  # The one-shot notice both roads give on a non-transactional engine.
  return if $_[0] =~ /^non-transactional DDL on K55::/;
  push @warnings, $_[0];
};

sub new_backend {
  my ($fc, $txn_engine, $ddl) = @_;
  my $backend = K55::Backend->new(undef);
  $backend->{fc}     = $fc;
  $backend->{_owner} = K55::Owner->new($txn_engine);   # held weakly by the backend
  $backend->_owner_storage($backend->{_owner});
  $backend->{sent} = [];
  $backend->{ddl}  = $ddl;
  return $backend;
}

# What the sync road hands to the handle, and what it returns.
sub sync_road {
  my ($storage_class, $ddl) = @_;
  my $dbh    = K55::DBH->new;
  my $deploy = K55::Deploy->new(schema => K55::Schema->new($storage_class->new($dbh)));
  my $ret    = eval { $deploy->_execute_ddl($dbh, $ddl) };
  return ($dbh->{stmts}, defined $ret ? $ret : "died: $@");
}

# What an async Future came to: its values, or how it failed.
sub settled {
  my ($f) = @_;
  return 'no Future' unless ref $f and $f->can('is_ready');
  return 'pending'   unless $f->is_ready;
  my @got;
  return "failed: $@" unless eval { @got = $f->get; 1 };
  return \@got;
}

my $T = 'CREATE TABLE t (id int)';

# [ label, the DDL text, the statements it holds ]
my @DDL = (
  [ 'a piece that is only a line comment',
    '-- nur ein Kommentar;',
    [] ],
  [ 'a piece that is only a block comment',
    '/* nur ein Kommentar */;',
    [] ],
  [ 'a text of nothing but comments and whitespace',
    "-- a\n\n   /* b */\n-- c;\n  \n\t/* d */ ;\n",
    [] ],
  [ 'a statement with a comment line in front of it',
    "-- users\n$T;",
    [ $T ] ],
  [ 'a statement with a comment inside it',
    "CREATE TABLE c (\n  id int -- the key\n);",
    [ "CREATE TABLE c (\n  id int -- the key\n)" ] ],
  [ "MySQL's executable comment",
    '/*!40101 SET x=1 */;',
    [ '/*!40101 SET x=1 */' ] ],
  [ 'a semicolon inside a string literal',
    "CREATE TABLE s (id int, s text DEFAULT 'a;b');",
    [ "CREATE TABLE s (id int, s text DEFAULT 'a;b')" ] ],
  [ 'statements with comment pieces between and behind them',
    "CREATE TABLE a (id int);\n-- a comment;\n/* audit */\nCREATE TABLE b (id int);\n-- done\n",
    [ 'CREATE TABLE a (id int)', 'CREATE TABLE b (id int)' ] ],
);

my @future_classes = ('DBIO::Test::Future');
if (eval { require Future; 1 }) { push @future_classes, 'Future' }
else { note 'Future.pm not installed: run against DBIO::Test::Future only' }

for my $case (@DDL) {
  my ($what, $ddl, $statements) = @$case;
  my $nothing   = !@$statements;
  my $bracketed = $nothing ? [] : [ 'BEGIN', @$statements, 'COMMIT' ];

  # The sync road is the measure: first that it does what the claim says ...
  my ($sync, $sync_ret)         = sync_road('K55::Storage',    $ddl);
  my ($sync_txn, $sync_txn_ret) = sync_road('K55::TxnStorage', $ddl);

  is_deeply $sync, $statements,
    "sync, $what: " . ($nothing ? 'no statement reaches the handle' : 'the statement reaches the handle, whole and without the comment in front');
  is_deeply $sync_txn, $bracketed,
    "sync on a transactional engine, $what: " . ($nothing ? 'no statement and no transaction' : 'the same, in one transaction');
  is_deeply [ $sync_ret, $sync_txn_ret ], [ 1, 1 ], "sync, $what: returns 1 and does not die";

  # ... then that each place of the async road does the same.
  for my $fc (@future_classes) {
    {
      my $l = "$fc, _execute_ddl_async, $what";
      my $backend = new_backend($fc, 0);
      my $f = eval { $backend->_execute_ddl_async(K55::Conn->new(7), $ddl) };
      is_deeply settled($f), [], "$l: resolves, with nothing";
      is_deeply $backend->{sent}, $sync, "$l: sends what the sync road ran";
    }

    {
      my $l = "$fc, deploy_async on a non-transactional engine, $what";
      my $backend = new_backend($fc, 0, $ddl);
      my $f = eval { $backend->deploy_async('schema') };
      is_deeply settled($f), [], "$l: resolves, with nothing";
      is_deeply $backend->{sent}, $sync, "$l: sends what the sync road ran";
      # Nothing to do is found out on the connection, which goes back.
      is_deeply $backend->pool->{release_log}, [1], "$l: the connection it took went back once";
    }

    {
      my $l = "$fc, deploy_async on a transactional engine, $what";
      my $backend = new_backend($fc, 1, $ddl);
      my $f = eval { $backend->deploy_async('schema') };
      is ref settled($f), 'ARRAY', "$l: resolves";
      is_deeply settled($f), [], "$l: ... with nothing, there being nothing to do" if $nothing;
      is_deeply $backend->{sent}, $sync_txn, "$l: sends what the sync road ran, bracket included";
      # Nothing to do is found out before a connection is asked for.
      is_deeply $backend->pool->{release_log}, ($nothing ? undef : [1]),
        "$l: " . ($nothing ? 'no connection was taken' : 'the connection it took went back once');
    }
  }

  is_deeply [ splice @warnings ], [], "$what: nothing warned on either road";
}

done_testing;
