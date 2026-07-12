use strict;
use warnings;
use Test::More;
use mro;

# Storage-layer composition, PostGIS side (core karr #70; PostGIS migration
# ticket #4). A PostGIS extension is a plain storage LAYER, not a storage_type
# subclass: DBIO::PostgreSQL::PostGIS registers it via
# DBIO::Schema::register_storage_layer, and it composes (C3) OVER the driver
# storage. PostGIS is sync-only -- it ships no ::Async sibling.
#
# Pure class/composition/introspection assertions -- no event loop, no real
# database. Live end-to-end proof lives in the DBIO_TEST_PG_* gated suite
# (t/30-spatial-live.t, t/40-deploy-roundtrip.t). Modelled on the reference
# driver's t/38-storage-layer-composition.t (dbio-postgresql).

use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::PostGIS::Storage;

my $LAYER  = 'DBIO::PostgreSQL::PostGIS::Storage';
my $DRIVER = 'DBIO::PostgreSQL::Storage';

# ===========================================================================
# 0. SANITY: the storage is a plain LAYER package now -- the `use base
#    'DBIO::PostgreSQL::Storage'` was dropped. It is neither a driver storage
#    nor a DBI storage; it only carries methods that get mixed in above a base.
# ===========================================================================
ok !$LAYER->isa('DBIO::Storage::DBI'),
  'the PostGIS storage is a plain layer, not a DBIO::Storage::DBI subclass';
ok !$LAYER->isa($DRIVER),
  'the PostGIS storage no longer subclasses DBIO::PostgreSQL::Storage';
can_ok $LAYER, qw( ensure_postgis postgis_version _ensure_postgis_extension
  dbio_deploy_class );

# ===========================================================================
# 1. SYNC composition: the layer composes OVER the real PG driver storage.
#    The composed class isa BOTH, its methods are callable, and its
#    dbio_deploy_class override wins over the base driver's deploy class.
# ===========================================================================
{
  my $composed_class = DBIO::Storage::Composed->compose($DRIVER, [$LAYER]);

  ok $composed_class->isa($DRIVER),
    'composed sync class isa the PostgreSQL driver storage (the base)';
  ok $composed_class->isa($LAYER),
    'composed sync class isa the PostGIS storage layer';
  can_ok $composed_class, qw( ensure_postgis postgis_version
    _ensure_postgis_extension );

  # The base driver's dbio_deploy_class returns DBIO::PostgreSQL::Deploy;
  # the layer overrides it (single-owner base override) and wins the MRO.
  is $DRIVER->dbio_deploy_class, 'DBIO::PostgreSQL::Deploy',
    'sanity: bare driver storage selects the plain PostgreSQL deploy class';
  is $composed_class->dbio_deploy_class, 'DBIO::PostgreSQL::PostGIS::Deploy',
    'the layer dbio_deploy_class override wins on the composed class';

  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = $composed_class->new($schema);
  isa_ok $storage, $DRIVER, 'composed instance';
  isa_ok $storage, $LAYER,  'composed instance carries the PostGIS layer';
  can_ok $storage, 'ensure_postgis';

  is_deeply [ DBIO::Storage::Composed->layers_of($composed_class) ],
    [ $LAYER ],
    'layers_of records exactly the one composed PostGIS layer';
}

# ===========================================================================
# 2. REGISTRATION WIRING: loading the DBIO::PostgreSQL::PostGIS component makes
#    connection() register the layer, so an (offline, lazy -- no DB opened)
#    connect composes it over the resolved base storage. Proves PostGIS.pm's
#    connection() calls register_storage_layer instead of setting storage_type.
# ===========================================================================
{
  package T::GisSchema;
  use base qw( DBIO::PostgreSQL::PostGIS DBIO::Schema );
  use mro 'c3';
}
{
  # connect() clones + runs connection(); storage construction is lazy, so no
  # database is contacted. The base here is the generic DBIO::Storage::DBI
  # (driver rebless to the Pg storage only happens on a real connect), which
  # is exactly what we want to assert offline: the layer was registered and
  # composed regardless of transport.
  my $schema = T::GisSchema->connect('dbi:Pg:dbname=dbio_offline_compose', '', '');

  is_deeply [ @{ $schema->storage_layers } ], [ $LAYER ],
    'the component connection() registered exactly the PostGIS storage layer';

  my $storage = $schema->storage;
  isa_ok $storage, $LAYER,
    'the connected (unconnected) storage carries the composed PostGIS layer';
  ok $storage->isa('DBIO::Storage::DBI'),
    'composed over the resolved base storage';
  can_ok $storage, 'ensure_postgis';
  ok !$storage->connected,
    'no database was opened for this offline composition assertion';
}

# ===========================================================================
# 3. FAIL-LOUD: dbio_deploy_class is a single-owner base override. A second
#    deploy-hooking layer that also defines its own dbio_deploy_class makes
#    composition croak at compose time, naming the method and both packages.
#    (This is why two deploy-extending extensions on one schema need a new core
#    deploy-hook-chaining ticket, not a silent workaround here.)
# ===========================================================================
{
  package T::RivalDeployLayer;
  sub dbio_deploy_class { 'T::Rival::Deploy' }
}
{
  my $ok = eval {
    DBIO::Storage::Composed->compose($DRIVER, [$LAYER, 'T::RivalDeployLayer']);
    1;
  };
  my $err = $@;
  ok !$ok, 'composing two deploy-hooking layers croaks (fail-loud by design)';
  like $err, qr/collision/,
    'the croak names it a storage layer method collision';
  like $err, qr/dbio_deploy_class/,
    'the croak names the colliding method dbio_deploy_class';
  like $err, qr/\Q$LAYER\E/,
    'the croak names the PostGIS layer as a definer';
}

# ===========================================================================
# 4. NO ASYNC LAYER (WP3): PostGIS ships no ::Async sibling. Core composition
#    skips a layer without an ::Async mirror silently, so async modes carry no
#    PostGIS async layer -- CRUD on geometry columns flows through the transport
#    unchanged. Assert the sibling genuinely does not exist.
# ===========================================================================
{
  my $async_sibling = $LAYER . '::Async';
  my $loaded = eval "require $async_sibling; 1";
  ok !$loaded,
    "PostGIS ships no async sibling ($async_sibling) -- sync-only layer";
}

done_testing;
