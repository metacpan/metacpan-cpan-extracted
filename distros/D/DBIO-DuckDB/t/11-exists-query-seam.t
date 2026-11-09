#!/usr/bin/env perl
# t/11-exists-query-seam.t — the ADR 0037 EXISTS seam as DuckDB resolves it.
#
# Two claims, both static class facts, so this test never opens a database:
#
#   1. DBIO::DuckDB::Storage declares supports_exists_query. Without it
#      results_exist and its two siblings throw instead of running.
#   2. It declares that capability WITHOUT overriding _exists_value_sql,
#      because core's base rendering is already valid DuckDB:
#        SELECT CASE WHEN EXISTS <inner> THEN 1 ELSE 0 END
#      DuckDB allows EXISTS as a boolean value expression and allows a
#      SELECT with no FROM -- its own documented example is both at once
#      (https://duckdb.org/docs/stable/sql/expressions/subqueries).
#
# The absence of an override is asserted explicitly rather than left
# implicit: an override added later without a reason would silently change
# every results_exist statement this driver emits, and this test is where
# that has to be argued.

use strict;
use warnings;
use Test::More;
use DBIO::DuckDB::Storage;
use DBIO::Test::Schema;

# --- 1. the capability is declared ------------------------------------

ok( DBIO::DuckDB::Storage->_use_supports_exists_query,
  'DBIO::DuckDB::Storage declares supports_exists_query (ADR 0037)' );

# --- 2. core's rendering is inherited, not overridden ------------------

is( DBIO::DuckDB::Storage->can('_exists_value_sql'),
    DBIO::Storage::DBI->can('_exists_value_sql'),
  '_exists_value_sql resolves to core, i.e. the driver does not override it' );

ok !defined( *{DBIO::DuckDB::Storage::_exists_value_sql}{CODE} ),
  'no _exists_value_sql in the driver symbol table either';

# The rendering itself, pinned byte-for-byte. DuckDB needs no dummy table
# (contrast Oracle FROM DUAL, DB2 FROM SYSIBM.SYSDUMMY1, Firebird
# FROM RDB$DATABASE), so the statement ends after END.
is( DBIO::DuckDB::Storage->_exists_value_sql('(SELECT 42 FROM "artist")'),
  'SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist") THEN 1 ELSE 0 END',
  'base CASE WHEN EXISTS rendering, no FROM clause appended' );

# --- 3. resolved on a storage that never connects ----------------------
# ADR 0037 section 5: the seam must answer from class facts alone. A DuckDB
# storage that was given its DSN but never connected answers without a $dbh
# -- if it ever connected here, $rs->results_exist_as_query would open a
# connection just to pick a spelling, which is the defect the hook exists to
# remove.

my $storage = DBIO::DuckDB::Storage->new;
$storage->connect_info(['dbi:DuckDB:dbname=:memory:']);

is $storage->_exists_value_sql('(SELECT 42)'),
  'SELECT CASE WHEN EXISTS (SELECT 42) THEN 1 ELSE 0 END',
  'never-connected storage answers with the DuckDB driver rendering';

is $storage->_dbh, undef,
  'and did so without connecting';

# Which driver a DuckDB DSN leads to is a function, not a storage that turns
# into the driver's once asked (core ADR 0067; the generic storage no longer
# reblesses from the DSN).
SKIP: {
  skip 'core predates ADR 0067 (no DBIO->driver_for)', 1
    unless DBIO->can('driver_for');

  is( DBIO->driver_for('dbi:DuckDB:dbname=:memory:'), 'DuckDB',
    'DBIO->driver_for names DuckDB for a DuckDB DSN' );
}

# --- 4. the whole ResultSet path, still offline ------------------------
# results_exist_as_query is the public surface: core parenthesises what
# the hook returned and adds nothing else. The shared test schema keeps no
# driver in its class; this use declares DuckDB on a clone.

my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('+DBIO::DuckDB::Storage');
$schema = $schema->connect('dbi:DuckDB:dbname=:memory:');

my $query  = $schema->resultset('Artist')->search({ name => 'foo' })
                    ->results_exist_as_query;

is ${$query}->[0],
  '( SELECT CASE WHEN EXISTS (SELECT 42 FROM "artist" "me" WHERE ( "name" = ? )) THEN 1 ELSE 0 END )',
  'results_exist_as_query renders the CASE form for DuckDB';

is scalar @{ ${$query} }, 2, 'one bind value travels with it';

is $schema->storage->_dbh, undef,
  'building that query opened no connection';

# Without that declaration there is no DuckDB rendering to ask for: a schema
# that names no driver is refused at connect (core ADR 0067).
SKIP: {
  skip 'core predates ADR 0067 (no refusal of a schema without a driver)', 1
    unless DBIO->can('driver_for');

  my $err = do {
    local $@;
    eval { DBIO::Test::Schema->clone->connect('dbi:DuckDB:dbname=:memory:'); 1 } ? '' : "$@";
  };
  like $err, qr/declares no driver.*ADR 0067/s,
    'the shared test schema without a declared driver is refused at connect';
}

done_testing;
