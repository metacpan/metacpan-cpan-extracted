use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::PostgreSQL::EV
  DBIO::PostgreSQL::EV::ConnectInfo
  DBIO::PostgreSQL::EV::Future
  DBIO::PostgreSQL::EV::Pool
  DBIO::PostgreSQL::EV::Storage
  DBIO::PostgreSQL::EV::TransactionContext
  DBIO::PostgreSQL::EV::TestHarness
);

plan tests => scalar(@modules) + 1;   # + the storage-layer contract below

for my $mod (@modules) {
  use_ok($mod);
}

# ADR 0032 section 7: this module must never decide the driver. It is the
# distribution's overview -- POD, no methods, no connection() hook -- and,
# loaded as a component, it takes no part in resolution: the DSN resolves the
# storage and { async => 'ev' } opts into EV::Storage, which the storage-keyed
# mode registry resolves over the STORAGE MRO whether or not this component was
# loaded -- so it must pin no storage_type and inherit no driver component. No
# layer class is passed: this component registers none. The family broke that rule twice (karr k14 in dbio-mysql-ev
# via storage_type, karr k8 in dbio-postgresql-age via inheritance), both times
# caught only by review. Guarded because the helper is new in DBIO 0.900004.
SKIP: {
  eval { require DBIO::Test::StorageLayer; 1 }
    or skip 'DBIO::Test::StorageLayer (DBIO 0.900004+) not available', 1;
  DBIO::Test::StorageLayer::storage_layer_contract_ok('DBIO::PostgreSQL::EV');
}
