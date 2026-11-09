use strict;
use warnings;
use Test::More;

my @modules = qw(
  DBIO::MySQL::EV
  DBIO::MySQL::EV::Storage
  DBIO::MySQL::EV::Pool
  DBIO::MySQL::EV::Future
);

plan tests => scalar(@modules) + 1;   # + the storage-layer contract below

for my $mod (@modules) {
  use_ok($mod);
}

# ADR 0032 section 7: this component must never decide the driver. It is an
# inert marker (ADR 0030) -- a no-op, defining no methods and no connection()
# hook: the DSN resolves the storage and { async => 'ev' } opts into
# EV::Storage whether or not it was loaded, because mode resolution walks the
# STORAGE MRO (the 'ev' registration sits on DBIO::MySQL::Storage) and never
# sees a schema component. So it must pin no storage_type
# and inherit no driver component. No layer class is passed: this component
# registers none. karr #14 happened right here: connection() was overridden to
# force storage_type('+DBIO::MySQL::EV::Storage') on every connect (see the
# note at the foot of lib/DBIO/MySQL/EV.pm), and only review caught it -- as
# with karr #8 in dbio-postgresql-age, which reached the same end through
# inheritance. Guarded because the helper is new in DBIO 0.900004.
SKIP: {
  eval { require DBIO::Test::StorageLayer; 1 }
    or skip 'DBIO::Test::StorageLayer (DBIO 0.900004+) not available', 1;
  DBIO::Test::StorageLayer::storage_layer_contract_ok('DBIO::MySQL::EV');
}
