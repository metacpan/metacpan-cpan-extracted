use strict;
use warnings;
use Test::More;

use_ok 'DBIO::PostgreSQL::PostGIS';
use_ok 'DBIO::PostgreSQL::PostGIS::Storage';
use_ok 'DBIO::PostgreSQL::PostGIS::Geometry';
use_ok 'DBIO::PostgreSQL::PostGIS::ResultSet';
use_ok 'DBIO::PostgreSQL::PostGIS::Extension';
use_ok 'DBIO::PostgreSQL::PostGIS::Topology::Extension';
use_ok 'DBIO::PostgreSQL::PostGIS::Introspect';
use_ok 'DBIO::PostgreSQL::PostGIS::Deploy';

# ADR 0032 section 7: this extension must never decide the driver. It registers
# a storage layer and leaves the storage class to the DSN -- so it must not pin
# storage_type and must not inherit a driver component. The family broke that
# twice (karr k8 in dbio-postgresql-age via inheritance, karr k14 in
# dbio-mysql-ev via storage_type), both times caught only by review.
# Guarded because the helper is new in DBIO 0.900004.
SKIP: {
  eval { require DBIO::Test::StorageLayer; 1 }
    or skip 'DBIO::Test::StorageLayer (DBIO 0.900004+) not available', 1;
  DBIO::Test::StorageLayer::storage_layer_contract_ok(
    'DBIO::PostgreSQL::PostGIS' => 'DBIO::PostgreSQL::PostGIS::Storage',
  );
}

done_testing;
