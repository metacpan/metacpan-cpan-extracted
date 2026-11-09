use strict;
use warnings;
use Test::More;

use_ok 'DBIO::PostgreSQL::Age';
use_ok 'DBIO::PostgreSQL::Age::Storage';

# ADR 0032 section 7: this extension must never decide the driver. It registers
# a storage layer and leaves the storage class to the DSN -- so it must not pin
# storage_type and must not inherit a driver component. karr #8 broke exactly
# that here ('use base DBIO::PostgreSQL'), which review caught, not the suite.
# Guarded because the helper is new in DBIO 0.900004.
SKIP: {
  eval { require DBIO::Test::StorageLayer; 1 }
    or skip 'DBIO::Test::StorageLayer (DBIO 0.900004+) not available', 1;
  DBIO::Test::StorageLayer::storage_layer_contract_ok(
    'DBIO::PostgreSQL::Age' => 'DBIO::PostgreSQL::Age::Storage',
  );
}

# The future_io async adapter needs the PostgreSQL future_io transport (and its
# DBD::Pg/Future/Future::IO chain); load it only when those are available so a
# minimal environment still passes the core load test.
SKIP: {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or skip 'future_io prerequisites (DBD::Pg/Future/Future::IO) not available', 1;
  use_ok 'DBIO::PostgreSQL::Age::Storage::Async';
}

done_testing;
