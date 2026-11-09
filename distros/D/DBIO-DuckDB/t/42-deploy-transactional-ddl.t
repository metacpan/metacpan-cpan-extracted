#!/usr/bin/env perl
# t/42-deploy-transactional-ddl.t — the transactional_ddl capability
# DBIO::DuckDB::Storage declares (karr #13, handoff from core karr #130).
#
# Offline: in-memory DuckDB only, no DSN, no server, no DBIO_TEST_* anything.
#
# Asserting the VALUE alone would prove nothing. Core's default for an
# undeclared capability is 0 as well (DBIO::Storage::DBI::Capabilities defines
# _determine_supports_transactional_ddl => 0), so the first assertion below
# stays green with nothing declared at all. The get_inherited assertion is the
# tripwire: it is defined only for a value this class set itself.
#
# The rest of the file is why the 1 is there, because on DuckDB it is a
# decision and not an engine limit -- the engine has transactional DDL and this
# driver uses it, ending the orphan transactions the DBI driver underneath
# cannot (ADR 0005). Part B pins the engine fact the 1 rests on, and part C
# pins what the rollback override buys: a failed apply rolls back whole AND
# the connection survives, so the re-run core documents as the recovery works.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBI;

use DBIO::Test::Schema;
use DBIO::DuckDB::Storage;
use DBIO::DuckDB::Deploy;

# --- A. the declaration -----------------------------------------------------

is(DBIO::DuckDB::Storage->_use_transactional_ddl, 1,
  'transactional_ddl is 1 -- the deploy loop is bracketed in txn_do');

isnt(DBIO::DuckDB::Storage->get_inherited('_use_transactional_ddl'), undef,
  "... and the driver states it, rather than inheriting core's default");

# --- B. the engine fact the 1 is NOT about ----------------------------------
#
# DuckDB really does run DDL in a transaction. If any of these go red the
# reasoning in DBIO::DuckDB::Storage is out of date in the other direction and
# the declaration is no longer a decision but a limit -- which is a different
# comment and a different ticket.

my $probe = DBI->connect('dbi:DuckDB:dbname=:memory:', '', '',
  { RaiseError => 1, PrintError => 0, AutoCommit => 1 });

$probe->do('CREATE TABLE keeper (a INTEGER)');
$probe->do('CREATE INDEX keeper_ix ON keeper (a)');

$probe->do('BEGIN TRANSACTION');
$probe->do('CREATE TABLE rolled (a INTEGER)');
$probe->do('CREATE SEQUENCE rolled_seq START 1');
$probe->do('ALTER TABLE keeper ADD COLUMN b VARCHAR');
$probe->do('DROP INDEX keeper_ix');
$probe->do('ROLLBACK');

is scalar $probe->selectrow_array(
  q{SELECT count(*) FROM duckdb_tables() WHERE table_name = 'rolled'}), 0,
  'CREATE TABLE inside a transaction is taken back by ROLLBACK';

is scalar $probe->selectrow_array(
  q{SELECT count(*) FROM duckdb_sequences() WHERE sequence_name = 'rolled_seq'}), 0,
  '... CREATE SEQUENCE too';

is scalar $probe->selectrow_array(
  q{SELECT count(*) FROM duckdb_columns()
     WHERE table_name = 'keeper' AND column_name = 'b'}), 0,
  '... ALTER TABLE ADD COLUMN too';

is scalar $probe->selectrow_array(
  q{SELECT count(*) FROM duckdb_indexes() WHERE index_name = 'keeper_ix'}), 1,
  '... and a dropped index comes back';

# The whole shape of this driver's install DDL commits as one transaction,
# sequence live afterwards -- so the batch _execute_ddl would bracket is not
# the problem either.
lives_ok {
  $probe->do('BEGIN TRANSACTION');
  $probe->do('CREATE SEQUENCE batch_seq START 1');
  $probe->do(q{CREATE TABLE batch (
    id INTEGER DEFAULT nextval('batch_seq'), name VARCHAR, PRIMARY KEY (id))});
  $probe->do('CREATE INDEX batch_name_ix ON batch (name)');
  $probe->do('COMMIT');
  $probe->do(q{INSERT INTO batch (name) VALUES ('x')});
} 'the install shape -- CREATE SEQUENCE + CREATE TABLE + CREATE INDEX -- commits as one';

is scalar $probe->selectrow_array('SELECT id FROM batch'), 1,
  '... with the sequence live afterwards';

$probe->disconnect;

# The one thing a bracket would cost on the engine side. DuckDB refuses to
# alter a column an index depends on and documents the remedy as "drop the
# index, alter the table, and then recreate the index"
# (duckdb.org/docs/stable/sql/statements/alter_table) -- and that remedy only
# works outside a transaction, because the type-change check does not see the
# uncommitted DROP INDEX. DBIO::DuckDB::Diff cannot emit this pair today
# (indexes are diffed after columns), so this costs nothing yet; it is pinned
# because it is the reason not to reorder the phases under a wrap.

sub indexed_table {
  my $dbh = DBI->connect('dbi:DuckDB:dbname=:memory:', '', '',
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
  $dbh->do('CREATE TABLE dep (a INTEGER)');
  $dbh->do('CREATE INDEX dep_ix ON dep (a)');
  return $dbh;
}

{
  my $dbh = indexed_table();
  lives_ok {
    $dbh->do('DROP INDEX dep_ix');
    $dbh->do('ALTER TABLE dep ALTER COLUMN a TYPE BIGINT');
  } "DuckDB's documented drop-index-then-alter remedy works statement at a time";
  $dbh->disconnect;
}

{
  my $dbh = indexed_table();
  throws_ok {
    $dbh->do('BEGIN TRANSACTION');
    $dbh->do('DROP INDEX dep_ix');
    $dbh->do('ALTER TABLE dep ALTER COLUMN a TYPE BIGINT');
    $dbh->do('COMMIT');
  } qr/index depends on it/i,
    '... and fails inside a transaction -- the type-change check does not see '
  . 'the uncommitted DROP INDEX, so a wrap would foreclose that remedy';
  eval { $dbh->do('ROLLBACK') };
  $dbh->disconnect;
}

# --- C. what the rollback override buys: recovery from a failed apply --------
#
# Same batch twice against two identical in-memory databases: once with the
# capability forced true on the storage (tier 1), and once with the force
# cleared so the class declaration answers again (tier 2).
#
# Bracketed, DBIO::Deploy::Base::_execute_ddl wraps the batch in
# $storage->txn_do and DuckDB rolls it back -- the atomicity is real. The
# rollback override (_exec_txn_rollback, ADR 0005) then closes the orphan
# transaction DBD::DuckDB's rollback reopens, so the connection comes back
# usable. Core's documented recovery for a failed apply is re-running the
# upgrade against the same connection, and that is exactly what the override
# keeps working.

sub connect_memory {
  my $schema = DBIO::Test::Schema->clone;
  $schema->storage_type('+DBIO::DuckDB::Storage');
  $schema = $schema->connect('dbi:DuckDB:dbname=:memory:', '', '',
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
  $schema->storage->dbh;   # resolve the driver before touching capabilities
  return $schema;
}

# Second statement collides with the first, so the batch always throws.
my $failing_batch = "CREATE TABLE half (x INTEGER);\nCREATE TABLE half (y INTEGER);\n";

sub leftover_half {
  my ($schema) = @_;
  return scalar $schema->storage->dbh->selectrow_array(
    q{SELECT count(*) FROM duckdb_tables() WHERE table_name = 'half'});
}

{
  my $schema  = connect_memory();
  my $storage = $schema->storage;
  my $deploy  = DBIO::DuckDB::Deploy->new(schema => $schema);

  $storage->_use_transactional_ddl(1);
  is $storage->_use_transactional_ddl, 1, 'capability forced true for the bracketed path';

  dies_ok { $deploy->_execute_ddl($storage->dbh, $failing_batch) }
    'bracketed: the failing batch throws';

  is leftover_half($schema), 0,
    '... and rolls back whole -- DuckDB really does have transactional DDL';

  lives_ok { $deploy->_execute_ddl($storage->dbh, "CREATE TABLE fresh (x INTEGER);\n") }
    '... and the connection survives -- the rollback override closes the orphan '
  . 'transaction, so the re-run core documents as the recovery runs';

  $schema->storage->disconnect;
}

{
  my $schema  = connect_memory();
  my $storage = $schema->storage;
  my $deploy  = DBIO::DuckDB::Deploy->new(schema => $schema);

  # undef deletes the tier-1 slot rather than tombstoning it, handing the
  # question back to the class declaration.
  $storage->_use_transactional_ddl(undef);
  is $storage->_use_transactional_ddl, 1,
    'clearing the force falls through to the class declaration, not to a tombstone';

  dies_ok { $deploy->_execute_ddl($storage->dbh, $failing_batch) }
    'bracketed: the identical batch throws too';

  is leftover_half($schema), 0,
    '... and rolls back whole -- the class declaration brackets the deploy loop';

  lives_ok { $deploy->_execute_ddl($storage->dbh, "CREATE TABLE fresh (x INTEGER);\n") }
    '... and the connection survives, so re-running the upgrade works -- '
  . 'which is the recovery the override protects';

  $schema->storage->disconnect;
}

done_testing;
