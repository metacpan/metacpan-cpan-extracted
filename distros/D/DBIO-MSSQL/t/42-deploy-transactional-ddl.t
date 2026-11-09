#!/usr/bin/env perl
# t/42-deploy-transactional-ddl.t -- the transactional_ddl capability
# DBIO::MSSQL::Storage declares (karr k23, handoff from core karr k130).
#
# Offline. No DSN, no server, no DBIO_TEST_* anything: the declaration is a
# class-level fact, the statement inventory is a pure string question, and the
# deploy path is driven against a recording handle rather than an engine. That
# is deliberate rather than a shortcut -- no SQL Server was available when this
# was written, so nothing here claims to have been measured. What a live run
# would add is named in DBIO::MSSQL::Storage.
#
# Unlike the sqlite/duckdb siblings this driver answers 1, so the plain value
# assertions below already fail with nothing declared (core's default is 0).
# What they still cannot see is WHERE the 1 comes from, and on this driver that
# is the whole risk: DBIO::MSSQL::Storage::Sybase is
#
#   use base qw/ DBIO::Sybase::Storage  DBIO::MSSQL::Storage /;  # mro c3
#
# so the Sybase TRANSPORT class sits ahead of the MSSQL ENGINE class in the C3
# linearisation, and Class::Accessor::Grouped::get_inherited walks exactly that
# linearisation (via mro::get_linear_isa). Sybase ASE is an implicit-commit
# engine and dbio-sybase declares 0 for it; today that 0 lives on
# DBIO::Sybase::Storage::ASE, which is NOT in this class's chain. Were it ever
# to move up to DBIO::Sybase::Storage it would silently shadow the 1 here for
# every DBD::Sybase connection -- a transport fact overriding an engine fact,
# with no error anywhere. Part A therefore pins the DECLARING CLASS, not just
# the value, so that arrives as a red test naming the offender.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use mro;

use DBIO::Test;
use DBIO::SQL::Util ();
use DBIO::MSSQL::Storage;
use DBIO::MSSQL::Storage::ODBC;
use DBIO::MSSQL::DDL;
use DBIO::MSSQL::Diff;
use DBIO::MSSQL::Deploy;

# --- A. the declaration, and where it lives ---------------------------------

# set_inherited stores a class-level declaration in $Class::__cag_<field>, and
# get_inherited returns the first DEFINED one along mro::get_linear_isa. So the
# list of classes actually holding that variable is both the proof that this
# driver declared the value itself and the proof that nothing ahead of it in
# either transport's chain overrides it.
sub declaring_classes {
  my ($class) = @_;
  no strict 'refs';
  return [ grep { defined ${ $_ . '::__cag__use_transactional_ddl' } }
             @{ mro::get_linear_isa($class) } ];
}

is( DBIO::MSSQL::Storage->_use_transactional_ddl, 1,
  'transactional_ddl is 1 -- the deploy loop is bracketed in txn_do' );

isnt( DBIO::MSSQL::Storage->get_inherited('_use_transactional_ddl'), undef,
  '... and the driver states it, rather than inheriting core\'s default' );

is_deeply( declaring_classes('DBIO::MSSQL::Storage'),
  [ 'DBIO::MSSQL::Storage' ],
  '... on the transport-neutral base, because it is an engine fact' );

# Both rebless targets must see the same answer: the DSN picks the transport,
# and the transport has no vote on whether SQL Server can roll DDL back.
for my $class (qw(
  DBIO::MSSQL::Storage::ODBC
  DBIO::MSSQL::Storage::Sybase
  DBIO::MSSQL::Storage::Sybase::NoBindVars
)) {
  SKIP: {
    skip "$class not loadable (DBIO::Sybase is an optional dep)", 2
      unless eval "require $class; 1";

    is( $class->_use_transactional_ddl, 1, "$class sees 1" );

    is_deeply( declaring_classes($class), [ 'DBIO::MSSQL::Storage' ],
      "... reading it from DBIO::MSSQL::Storage, unshadowed" );
  }
}

# --- B. the statement inventory the 1 rests on ------------------------------
#
# The capability is a promise about the statements THIS driver emits, not about
# Transact-SQL in general. Core provides a per-statement escape hatch for the
# odd statement that cannot be in a transaction (_ddl_statement_is_transactional,
# ADR 0026 addendum, added for PostgreSQL's ALTER TYPE ... ADD VALUE). This
# driver does not override it, and the two sweeps below are the reason.
#
# The first is Microsoft's closed exception list, verbatim from the "Transaction
# locking and row versioning guide" -- "You can use all Transact-SQL statements
# in an explicit transaction, except for the following statements" -- plus
# RESUMABLE = ON ("The DDL command with RESUMABLE = ON can't be executed inside
# an explicit transaction") and memory-optimized tables ("cannot be created or
# dropped in the context of a user transaction"). ONLINE = ON is deliberately
# NOT in here: it is cautioned, not forbidden, and asserting otherwise would
# encode a folk rule as an engine fact.
my $forbidden = qr{
    ^ \s* (?: CREATE | ALTER | DROP ) \s+ DATABASE \b
  | ^ \s* (?: BACKUP | RESTORE | RECONFIGURE ) \b
  | ^ \s* (?: CREATE | ALTER | DROP ) \s+ FULLTEXT \b
  | \b sp_(?: fulltext | dboption )
  | \b RESUMABLE \s* = \s* ON \b
  | \b MEMORY_OPTIMIZED \s* = \s* ON \b
}xi;

# The second is the statements that ARE allowed inside a transaction and are
# documented not to be taken back by its ROLLBACK. Those are the dangerous ones
# for a capability like this: they would not raise, they would just quietly
# leave the batch non-atomic after the declaration promised it was.
my $not_rolled_back = qr{
    ^ \s* UPDATE \s+ STATISTICS \b
  | ^ \s* ALTER \s+ INDEX \b .* \b REORGANIZE \b
}xis;

use lib 't/lib';
use K71Fixtures qw(without_artist_constraint);

# the unique constraint 'artist' of core's Artist is refused by install_ddl
# (named like its table, Msg 2714; t/100): not what this file is about
my $schema  = without_artist_constraint(DBIO::Test->init_schema(
  storage_type => 'DBIO::MSSQL::Storage', no_deploy => 1));
my $storage = $schema->storage;

# Every shape the driver can put on the wire through _execute_ddl: install_ddl
# supplies CREATE TABLE and CREATE VIEW, the diff below supplies the rest.
my $diff = DBIO::MSSQL::Diff->new(
  source => {
    tables       => { gone => { table_name => 'gone' },
                      keep => { table_name => 'keep' } },
    columns      => { gone => [ { column_name => 'id', data_type => 'int' } ],
                      keep => [ { column_name => 'id',  data_type => 'int', is_pk => 1 },
                                { column_name => 'old', data_type => 'text' },
                                { column_name => 'w',   data_type => 'int' } ] },
    indexes      => { keep => { ix_stale => { columns => ['w'] } } },
    foreign_keys => { keep => [ { constraint_name => 'fk_stale', from_columns => ['w'],
                                  to_table => 'other', to_columns => ['id'] } ] },
  },
  target => {
    tables       => { keep  => { table_name => 'keep' },
                      fresh => { table_name => 'fresh' } },
    columns      => { keep  => [ { column_name => 'id',  data_type => 'int', is_pk => 1 },
                                 { column_name => 'w',   data_type => 'bigint', not_null => 1 },
                                 { column_name => 'new', data_type => 'varchar', size => 20 } ],
                      fresh => [ { column_name => 'id', data_type => 'int',
                                   is_pk => 1, is_identity => 1, not_null => 1 } ] },
    indexes      => { keep => { ix_new => { is_unique => 1, kind => 'nonclustered',
                                            columns => ['new'] } } },
    foreign_keys => { keep => [ { constraint_name => 'fk_new', from_columns => ['w'],
                                  to_table => 'other', to_columns => ['id'] } ] },
  },
);

my @stmts = grep { /\S/ && !/^\s*--/ }
  DBIO::SQL::Util::_split_statements(
    DBIO::MSSQL::DDL->install_ddl($schema) . "\n" . $diff->as_sql );

# The shapes this driver can emit, each asserted present so the two sweeps
# below cannot be vacuously green on an inventory that quietly lost one.
for my $shape (
  [ 'CREATE TABLE'                => qr/^CREATE TABLE\b/i ],
  [ 'CREATE VIEW'                 => qr/^CREATE VIEW\b/i ],
  [ 'CREATE INDEX'                => qr/^CREATE (?:UNIQUE )?(?:(?:NON)?CLUSTERED )?INDEX\b/i ],
  [ 'DROP TABLE'                  => qr/^DROP TABLE\b/i ],
  [ 'DROP INDEX'                  => qr/^DROP INDEX\b/i ],
  [ 'ALTER TABLE ADD <column>'    => qr/^ALTER TABLE \S+ ADD (?!CONSTRAINT)/i ],
  [ 'ALTER TABLE DROP COLUMN'     => qr/^ALTER TABLE \S+ DROP COLUMN\b/i ],
  [ 'ALTER TABLE ALTER COLUMN'    => qr/^ALTER TABLE \S+ ALTER COLUMN\b/i ],
  [ 'ALTER TABLE ADD CONSTRAINT'  => qr/^ALTER TABLE \S+ ADD CONSTRAINT\b/i ],
  [ 'ALTER TABLE DROP CONSTRAINT' => qr/^ALTER TABLE \S+ DROP CONSTRAINT\b/i ],
) {
  my ($name, $re) = @$shape;
  ok scalar(grep { $_ =~ $re } @stmts), "inventory contains $name";
}

is_deeply [ grep { $_ =~ $forbidden } @stmts ], [],
  'no emitted statement is one SQL Server refuses inside an explicit transaction';

is_deeply [ grep { $_ =~ $not_rolled_back } @stmts ], [],
  '... nor one it accepts there but commits independently of the rollback';

is_deeply [ grep { !$storage->_ddl_statement_is_transactional($_) } @stmts ], [],
  '... so the driver leaves core\'s per-statement escape hatch unoverridden';

# --- C. what the 1 does on the real deploy path -----------------------------
#
# Driven through DBIO::Deploy::Base::_execute_ddl itself -- the code the
# capability actually steers -- against a recording $dbh rather than a server.
# The handle is installed as the storage's own, so core's _storage_owns_dbh
# (refaddr($storage->_dbh) == refaddr($dbh)) is satisfied and the bracketing
# branch is the one under test. BEGIN/COMMIT/ROLLBACK are recorded by
# DBIO::Test::Storage's _exec_txn_* into the same captured_queries log the
# statements go into, so every assertion below reads ONE ordered stream.

{
  package TxnDdl::RecordingDbh;

  sub new {
    my ($class, $storage) = @_;
    return bless {
      storage => $storage, fail => undef,
      AutoCommit => 1, Active => 1, RaiseError => 1, PrintError => 0,
      CachedKids => {}, Driver => { Name => 'Recording' },
    }, $class;
  }

  sub FETCH      { $_[0]->{ $_[1] } }
  sub STORE      { $_[0]->{ $_[1] } = $_[2] }
  sub ping       { 1 }
  sub disconnect { 1 }
  sub begin_work { 1 }
  sub commit     { 1 }
  sub rollback   { 1 }
  # a read, not on the wire: the collation of the live database (karr k77)
  sub selectrow_array { 'SQL_Latin1_General_CP1_CI_AS' }

  sub do {
    my ($self, $sql) = @_;
    push @{ $self->{storage}->_captured_queries },
      { op => 'ddl', sql => $sql, bind => [] };
    die "engine rejected: $sql\n" if $self->{fail} and $sql =~ $self->{fail};
    return 1;
  }
}

my $rec = TxnDdl::RecordingDbh->new($storage);
$storage->{_fake_dbh} = $rec;

my $deploy = DBIO::MSSQL::Deploy->new(schema => $schema);
my $batch  = "CREATE TABLE a (x int);\nCREATE TABLE b (y int);\n";

sub wire {
  my @q = $storage->captured_queries;
  $storage->_captured_queries([]);
  return map { $_->{sql} } @q;
}

is $storage->_use_transactional_ddl, 1,
  'the storage instance answers with the class declaration, unforced';

wire();
$deploy->_execute_ddl($storage->_dbh, $batch);
is_deeply [ wire() ],
  [ 'BEGIN', 'CREATE TABLE a (x int)', 'CREATE TABLE b (y int)', 'COMMIT' ],
  'the batch runs inside one transaction on the storage\'s own handle';

$rec->{fail} = qr/TABLE b/;
wire();
dies_ok { $deploy->_execute_ddl($storage->_dbh, $batch) }
  'a statement the engine rejects still propagates';
is_deeply [ wire() ],
  [ 'BEGIN', 'CREATE TABLE a (x int)', 'CREATE TABLE b (y int)', 'ROLLBACK' ],
  '... and the bracket takes the earlier statement back -- the atomicity the 1 buys';

# The counterexample: the identical failing batch with the capability forced
# off is what this driver did before the declaration, and what it would do
# again if somebody "tidied" the 1 away. Tier 1 (the per-storage force) shadows
# the class declaration.
{
  $storage->_use_transactional_ddl(0);
  is $storage->_use_transactional_ddl, 0, 'capability forced off for the counterexample';

  wire();
  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, @_ };
    eval { $deploy->_execute_ddl($storage->_dbh, $batch) };
  }

  is_deeply [ wire() ],
    [ 'CREATE TABLE a (x int)', 'CREATE TABLE b (y int)' ],
    'unbracketed: no BEGIN, no ROLLBACK, so the first CREATE TABLE stays applied';

  ok scalar(grep { /non-transactional DDL on DBIO::MSSQL::Deploy/ } @warnings),
    '... and core says so once -- the F02 notice the declaration removes';
}

# undef DELETES the tier-1 slot rather than tombstoning it (ADR 0041 / core karr
# k137). Were it a tombstone, get_inherited's exists() test would keep reading
# the instance hash and a caller who cleared the force would land on core's
# conservative 0 -- silently losing the declaration for the life of the storage.
$storage->_use_transactional_ddl(undef);
is $storage->_use_transactional_ddl, 1,
  'clearing the force falls back to the class declaration, not to a tombstone';

# --- D. the two paths the bracket must NOT reach ----------------------------
#
# D1. DBIO::MSSQL::Deploy is a DBIO::Deploy::Base::TempDatabase, so _execute_ddl
# is ALSO called with a foreign handle: _deploy_and_introspect_temp opens its
# own raw DBI connection (AutoCommit => 1) to the throwaway database and
# deploys the install DDL into that. Bracketing there would open a transaction
# on the LIVE connection around DDL running on another one -- no atomicity
# bought, and a failure would roll back whatever the caller had open there.
# Core fixed this in 0.900004 (core karr k131) and this driver's declaration is
# only safe because of it, so the guarantee is pinned rather than assumed.

{
  $rec->{fail} = undef;
  my $foreign = TxnDdl::RecordingDbh->new($storage);

  is $storage->_use_transactional_ddl, 1, 'capability still on for the foreign-handle case';

  wire();
  $deploy->_execute_ddl($foreign, $batch);

  is_deeply [ wire() ],
    [ 'CREATE TABLE a (x int)', 'CREATE TABLE b (y int)' ],
    'a handle the storage does not own is never bracketed, capability or not';
}

# D2. CREATE DATABASE and DROP DATABASE are the two statements SQL Server would
# actually refuse in an explicit transaction, and they are absent from part B's
# inventory because they never travel the batch path at all: _create_temp_db /
# _drop_temp_db issue them through $dbh->do directly, on a handle in
# AutoCommit mode (they refuse one with AutoCommit off, t/115). That is what keeps them irrelevant to this capability, so it
# is asserted rather than reasoned about.

{
  wire();
  my $temp_db = $deploy->_create_temp_db($rec);
  like $temp_db, qr/^_dbio_tmp_\d+_\d+$/, '_create_temp_db names a throwaway database';
  is_deeply [ wire() ], [ "CREATE DATABASE $temp_db COLLATE SQL_Latin1_General_CP1_CI_AS" ],
    'CREATE DATABASE (with the collation of the live database) goes straight to the handle -- no BEGIN, and not via _execute_ddl';

  $deploy->_drop_temp_db($rec, $temp_db);
  is_deeply [ wire() ], [ "DROP DATABASE $temp_db" ],
    '... and so does DROP DATABASE';
}

done_testing;
