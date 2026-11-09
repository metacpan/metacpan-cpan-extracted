#!/usr/bin/env perl
# t/44-txn-rollback.t — the _exec_txn_rollback override (karr #15, ADR 0005).
#
# DBD::DuckDB 0.16's rollback issues ROLLBACK and then immediately reopens a
# transaction (BEGIN TRANSACTION), and the AutoCommit STORE branch that would
# close it again is unreachable code. A txn_do that rolls back therefore used
# to leave the connection inside a transaction DBI believes is closed, and the
# next txn_begin died. The override closes the orphan.
#
# Offline: in-memory DuckDB only, no DSN, no server, no DBIO_TEST_* anything.

use strict;
use warnings;
use Test::More;
use Test::Exception;
use DBI;

use DBIO::Test::Schema;
use DBIO::DuckDB::Storage;

sub connect_memory {
  my $schema = DBIO::Test::Schema->clone;
  $schema->storage_type('+DBIO::DuckDB::Storage');
  $schema = $schema->connect('dbi:DuckDB:dbname=:memory:', '', '',
    { RaiseError => 1, PrintError => 0, AutoCommit => 1 });
  $schema->storage->dbh;   # resolve the driver
  return $schema;
}

# A txn_do that rolls back must leave the connection usable.
{
  my $schema  = connect_memory();
  my $storage = $schema->storage;

  dies_ok {
    $storage->txn_do(sub {
      $storage->dbh->do('CREATE TABLE rolled (a INTEGER)');
      die 'boom';
    });
  } 'a txn_do whose block dies throws';

  is scalar $storage->dbh->selectrow_array(
    q{SELECT count(*) FROM duckdb_tables() WHERE table_name = 'rolled'}), 0,
    '... and the failed work is rolled back';

  lives_ok {
    $storage->txn_do(sub {
      $storage->dbh->do('CREATE TABLE fresh (a INTEGER)');
    });
  } '... and the connection survives -- the next txn_do runs';

  lives_ok {
    $storage->txn_do(sub {
      $storage->dbh->do('INSERT INTO fresh VALUES (1)');
    });
  } '... and the commit path is unaffected';

  is scalar $storage->dbh->selectrow_array('SELECT count(*) FROM fresh'), 1,
    'committed work is visible';

  $storage->disconnect;
}

done_testing;
