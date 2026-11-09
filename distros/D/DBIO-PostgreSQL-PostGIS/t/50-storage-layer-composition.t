use strict;
use warnings;
use Test::More;
use mro;

# Storage-layer composition, PostGIS side (core karr k70; PostGIS migration
# ticket k4). A PostGIS extension is a plain storage LAYER, not a storage_type
# subclass: DBIO::PostgreSQL::PostGIS registers it via
# DBIO::Schema::register_storage_layer, and it composes (C3) OVER the driver
# storage. PostGIS is sync-only -- it ships no ::Async sibling.
#
# Pure class/composition/introspection assertions -- no event loop, no real
# database. Live end-to-end proof lives in the DBIO_TEST_PG_* gated suite
# (t/30-spatial-live.t, t/40-deploy-roundtrip.t). Modelled on the reference
# driver's t/38-storage-layer-composition.t (dbio-postgresql).

use DBIO ();

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
can_ok $LAYER, qw( ensure_postgis postgis_version _ensure_postgis_extension );
ok !$LAYER->can('dbio_deploy_class'),
  'the layer defines no dbio_deploy_class: that hook has one owner, the driver '
  . 'storage (ADR 0066 section 4)';

# ===========================================================================
# 1. SYNC composition: the layer composes OVER the real PG driver storage.
#    The composed class isa BOTH and its methods are callable; the driver's
#    dbio_deploy_class is untouched.
# ===========================================================================
{
  my $composed_class = DBIO::Storage::Composed->compose($DRIVER, [$LAYER]);

  ok $composed_class->isa($DRIVER),
    'composed sync class isa the PostgreSQL driver storage (the base)';
  ok $composed_class->isa($LAYER),
    'composed sync class isa the PostGIS storage layer';
  can_ok $composed_class, qw( ensure_postgis postgis_version
    _ensure_postgis_extension );

  # dbio_deploy_class is the driver's: the layer does not override it, so the
  # composed storage keeps the driver's deploy class. The PostGIS model rules
  # reach the deploy through the declared extension list (ADR 0066), not here.
  is $composed_class->dbio_deploy_class, $DRIVER->dbio_deploy_class,
    'the composed class keeps the driver\'s deploy class';

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
#    connect composes it over the declared driver storage. Proves PostGIS.pm's
#    connection() calls register_storage_layer instead of setting storage_type:
#    the driver comes from the PostgreSQL component beside it, as every schema
#    declares its driver (core ADR 0067).
# ===========================================================================
{
  package T::GisSchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL', 'PostgreSQL::PostGIS');
}
{
  # connect() clones + runs connection(); storage construction is lazy, so no
  # database is contacted. The base is the declared driver storage from the
  # start: the PostgreSQL component pins storage_type, and the first dbh
  # access may only adapt it to an access path within that driver (core
  # ADR 0059). What we assert offline: the layer was registered and composed
  # over the driver the schema declared.
  my $schema = T::GisSchema->connect('dbi:Pg:dbname=dbio_offline_compose', '', '');

  is_deeply [ @{ $schema->storage_layers } ], [ $LAYER ],
    'the component connection() registered exactly the PostGIS storage layer';

  my $storage = $schema->storage;
  isa_ok $storage, $LAYER,
    'the connected (unconnected) storage carries the composed PostGIS layer';
  isa_ok $storage, $DRIVER,
    'composed over the declared PostgreSQL driver storage';
  can_ok $storage, 'ensure_postgis';
  ok !$storage->connected,
    'no database was opened for this offline composition assertion';
}

# ===========================================================================
# 2b. THE EXTENSION IS NO DRIVER (core ADR 0067): a schema that loads only the
#     PostGIS component declares no driver -- the component registers a storage
#     layer and leaves storage_type alone -- so connect refuses it before any
#     storage is built. Were the extension to pin the PostgreSQL storage, this
#     schema would connect; that is the composition seam the house rules keep
#     closed. An older core has no refusal and composes the layer over the
#     generic DBIO::Storage::DBI; the rule is not there to hold.
# ===========================================================================
{
  package T::GisOnlySchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL::PostGIS');
}
SKIP: {
  skip 'core without ADR 0067 (no DBIO->driver_for): a schema without a '
     . 'driver is not refused there', 4
    unless DBIO->can('driver_for');

  my $ok  = eval {
    T::GisOnlySchema->connect('dbi:Pg:dbname=dbio_offline_compose', '', '');
    1;
  };
  my $err = $@;
  ok !$ok, 'a schema with the PostGIS component and no driver is refused at connect';
  like "$err", qr/Schema class T::GisOnlySchema declares no driver/,
    'the refusal names the schema class and that it declares no driver';
  like "$err", qr/generic DBIO::Storage::DBI/,
    'the PostGIS component left the storage class generic: it declared nothing';
  like "$err", qr/load_components\('PostgreSQL'\)/,
    'the refusal names the driver component as the way out';
}

# ===========================================================================
# 3. NO ASYNC LAYER (WP3): PostGIS ships no ::Async sibling. Core composition
#    refuses a layer without an ::Async mirror unless it opts out explicitly;
#    PostGIS does so via async_layer_class (undef for every mode, see
#    t/55-async-sync-only.t), so async modes carry no PostGIS async layer --
#    CRUD on geometry columns flows through the transport unchanged. Assert the
#    sibling genuinely does not exist.
# ===========================================================================
{
  my $async_sibling = $LAYER . '::Async';
  my $loaded = eval "require $async_sibling; 1";
  ok !$loaded,
    "PostGIS ships no async sibling ($async_sibling) -- sync-only layer";
}

done_testing;
