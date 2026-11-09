#!/usr/bin/env perl
# t/53-attribute-prefixes.t — the attribute prefix of DBD::DuckDB (karr k43).
#
# Core asks the storage which lowercase connect keys are attributes of the DBD
# (_dbd_attribute_prefixes, ADR 0057 addendum, core k298/k307). Its default asks
# DBI->driver_prefix, and DBI knows no prefix for DBD::DuckDB (measured: empty),
# although the DBD takes duckdb_* attributes. Without an override such a key is
# refused as "not an attribute". The storage answers 'duckdb_' for DuckDB and
# leaves every other DBD to core.
#
# Offline: no connection, no database.

use strict;
use warnings;
use Test::More;
use DBI;

use DBIO::DuckDB::Test;

my $schema = DBIO::Test::Schema->clone;
$schema->storage_type('+DBIO::DuckDB::Storage');
$schema->connection('dbi:DuckDB:dbname=:memory:');
my $storage = $schema->storage;

isa_ok $storage, 'DBIO::DuckDB::Storage';

is_deeply [ $storage->_dbd_attribute_prefixes('DuckDB') ], ['duckdb_'],
  'DuckDB: the DBD prefix, which DBI does not know';

# a foreign name is core's to answer: the same as the base class gives
for my $other (qw(Pg mysql SQLite NoSuchDBD)) {
  is_deeply
    [ $storage->_dbd_attribute_prefixes($other) ],
    [ DBIO::Storage::DBI::_dbd_attribute_prefixes($storage, $other) ],
    "$other: delegated to core";
}

is_deeply [ $storage->_dbd_attribute_prefixes('Pg') ], [ DBI->driver_prefix('DBD::Pg') ],
  'Pg: DBI registry answer, not duckdb_';

my @none = $storage->_dbd_attribute_prefixes(undef);
is scalar(@none), 0, 'no driver name: nothing';

done_testing;
