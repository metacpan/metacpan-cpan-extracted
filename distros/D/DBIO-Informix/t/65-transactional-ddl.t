use strict;
use warnings;
use Test::More;

use DBIO::Optional::Dependencies ();
use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Storage::DBI;
use DBIO::Informix::Storage;
use DBIO::Informix::Deploy;

# ADR 0026 (karr k23) -- the transactional_ddl capability DBIO::Informix::Storage
# declares, and the branch of DBIO::Deploy::Base::_execute_ddl it selects.
#
# Informix runs DDL inside a transaction of a LOGGED database and takes it back
# on rollback. Measured against Informix 15.0.1 (the live block below repeats
# the essential part): CREATE TABLE, DROP TABLE, ALTER TABLE ADD / DROP / MODIFY
# of a column, ADD / DROP CONSTRAINT FOREIGN KEY, CREATE [UNIQUE] INDEX, DROP
# INDEX, CREATE VIEW, RENAME COLUMN and RENAME TABLE were each issued after
# BEGIN WORK and all of them were undone by ROLLBACK WORK. Core's own text puts
# Informix with the engines that commit implicitly on DDL; that is not what the
# server does.
#
# The declaration is static, 1. The one database where it does not hold is an
# UNLOGGED one (CREATE DATABASE without WITH LOG), and there BEGIN WORK itself
# is refused (SQL -256 "Transaction not available") and a connection with
# AutoCommit off cannot even be made -- so no DBIO transaction exists there,
# DDL or otherwise, and nothing about the declaration makes it worse.
#
# The first half is offline: the declaration is a class fact, and the second
# drives core's real _execute_ddl against the mock storage.

# --- 1. the declaration ------------------------------------------------------
#
# Declaredness first, then value: an undeclared capability answers 0 through
# core's determination just like a declared 0, and a class-method read of an
# undeclared one dies for want of a $dbh.

isnt (
  DBIO::Informix::Storage->get_inherited('_use_transactional_ddl'),
  undef,
  'this driver STATES its transactional_ddl answer, rather than resting on '
. 'core\'s default of 0',
);

is (
  DBIO::Informix::Storage->_use_transactional_ddl,
  1,
  '... and the answer is 1 -- DDL in a logged Informix database is part of '
. 'the transaction and is rolled back with it',
);

is (
  DBIO::Informix::Storage->can('_determine_supports_transactional_ddl'),
  DBIO::Storage::DBI->can('_determine_supports_transactional_ddl'),
  '... with no driver-local determination behind it: the answer is a class '
. 'fact, not a server probe',
);

# --- 2. the branch that declaration selects in core --------------------------

{
  package T::Ifx::TxnDdl::Dbh;
  use base 'DBIO::Test::Storage::FakeDbh';

  sub do {
    my ($self, $sql) = @_;
    push @{ $self->{_ddl} ||= [] }, $sql;
    return 1;
  }

  sub ddl_seen { @{ $_[0]->{_ddl} ||= [] } }
}

my $schema  = DBIO::Test->init_schema(
  no_deploy    => 1,
  storage_type => 'DBIO::Informix::Storage',
);
my $storage = $schema->storage;
$storage->{_fake_dbh} = T::Ifx::TxnDdl::Dbh->new;
my $dbh = $storage->_dbh;

my $deploy = DBIO::Informix::Deploy->new(schema => $schema);

is ($storage->_use_transactional_ddl, 1,
  'the storage instance answers 1 too, with nothing connected');

{
  $storage->reset_captured;

  my @warn;
  {
    local $SIG{__WARN__} = sub { push @warn, $_[0] };
    $deploy->_execute_ddl($dbh, "CREATE TABLE a (id INTEGER);\nCREATE TABLE b (id INTEGER)");
  }

  is_deeply (
    [ $dbh->ddl_seen ],
    [ 'CREATE TABLE a (id INTEGER)', 'CREATE TABLE b (id INTEGER)' ],
    'both statements ran, in order',
  );

  is_deeply (
    [ map { $_->{sql} } grep { $_->{op} =~ /^txn_/ } $storage->captured_queries ],
    [ 'BEGIN', 'COMMIT' ],
    '... inside one transaction, so a failing statement takes the earlier '
  . 'ones back',
  );

  ok (
    ! scalar( grep { /non-transactional DDL/ } @warn ),
    '... and core does not emit its "non-transactional DDL" notice, which '
  . 'would be false for this engine',
  );
}

# --- 3. live: a failing deploy leaves nothing behind -------------------------

SKIP: {
  my ($dsn, $user, $pass) = @ENV{map { "DBIO_TEST_INFORMIX_$_" } qw/DSN USER PASS/};

  skip 'Set $ENV{DBIO_TEST_INFORMIX_DSN}, _USER and _PASS to run the live half', 4
    unless $dsn;

  skip 'Test needs ' . DBIO::Optional::Dependencies->req_missing_for('test_rdbms_informix'), 4
    unless DBIO::Optional::Dependencies->req_ok_for('test_rdbms_informix');

  my $live = DBIO::Test::Schema->clone(storage_type => '+DBIO::Informix::Storage')
    ->connect($dsn, $user, $pass);
  my $ldbh = $live->storage->dbh;

  my $exists = sub {
    my ($n) = $ldbh->selectrow_array(
      'SELECT COUNT(*) FROM systables WHERE tabname = ?', undef, $_[0]);
    return $n;
  };
  my $cleanup = sub { eval { $ldbh->do("DROP TABLE $_") } for qw(naehte_ddl_a naehte_ddl_b) };
  $cleanup->();
  END { $cleanup->() if $ldbh }

  my $ldeploy = DBIO::Informix::Deploy->new(schema => $live);

  my @warn;
  local $SIG{__WARN__} = sub { push @warn, $_[0] };

  ok (
    !eval {
      $ldeploy->_execute_ddl($ldbh,
        "CREATE TABLE naehte_ddl_a (id INTEGER);\n"
      . "ALTER TABLE naehte_ddl_a ADD (extra INTEGER);\n"
      . "NO SUCH STATEMENT;");
      1
    },
    'live: a deploy whose third statement fails raises',
  );
  is ($exists->('naehte_ddl_a'), 0,
    '... and the table its first statement created is gone: the batch was '
  . 'one transaction and the server rolled the DDL back');

  $ldeploy->_execute_ddl($ldbh,
    "CREATE TABLE naehte_ddl_a (id INTEGER);\nCREATE TABLE naehte_ddl_b (id INTEGER)");
  is_deeply ([ $exists->('naehte_ddl_a'), $exists->('naehte_ddl_b') ], [1, 1],
    'live: a deploy that succeeds commits both tables');

  ok (! scalar(grep { /non-transactional DDL/ } @warn),
    'live: no "non-transactional DDL" notice');
}

done_testing;
