use strict;
use warnings;
use Test::More;
use mro;

# WP4b (karr #6) -- the family's canonical MULTI-EXTENSION regression (core #69
# facet 2). Two storage-layer extensions on ONE schema: AGE (graph) and PostGIS
# (spatial). Both are plain layers; core composes them (C3) over the resolved
# driver storage into a single class that isa AND can BOTH.
#
# This file is the runtime half. The model half -- that the two extensions
# commute in deploy, in either order -- used to be asserted here through a
# chained dbio_deploy_class (karr k12); with ADR 0066 (karr k20) there is no
# deploy chain, and it is t/50-extension-set.t (DBIO::Test::ExtensionSet).
#
# Pure class/composition assertions -- no event loop, no real database. PostGIS is
# a develop/recommends dependency (never a hard require); skip cleanly when absent.

BEGIN {
  eval { require DBIO::PostgreSQL::PostGIS; require DBIO::PostgreSQL::PostGIS::Storage; 1 }
    or plan skip_all =>
      'DBIO::PostgreSQL::PostGIS not installed (develop/recommends only) -- stacking test needs it';
}

use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Age::Storage;

my $AGE_LAYER = 'DBIO::PostgreSQL::Age::Storage';
my $GIS_LAYER = 'DBIO::PostgreSQL::PostGIS::Storage';

# ===========================================================================
# 0. Precondition: the AGE layer does not take the deploy class. It is the
#    driver's (ADR 0066 section 4); the model rules are the extension class's.
# ===========================================================================
ok !$AGE_LAYER->can('dbio_deploy_class'),
  'the AGE layer defines no dbio_deploy_class';

# ===========================================================================
# 1. Direct compose of both layers over the PG driver: it does NOT croak, and the
#    composed class isa BOTH and can BOTH surfaces.
# ===========================================================================
{
  my $composed_class = eval {
    DBIO::Storage::Composed->compose('DBIO::PostgreSQL::Storage', [ $AGE_LAYER, $GIS_LAYER ]);
  };
  my $err = $@;
  ok !$err, 'composing the AGE and PostGIS layers together does NOT croak'
    or diag "died with: $err";

  ok $composed_class->isa($AGE_LAYER), 'composed class isa the AGE layer';
  ok $composed_class->isa($GIS_LAYER), 'composed class isa the PostGIS layer';
  ok $composed_class->isa('DBIO::PostgreSQL::Storage'), 'composed class isa the PG driver base';

  can_ok $composed_class, qw( cypher create_graph drop_graph cypher_async );  # AGE
  can_ok $composed_class, qw( ensure_postgis postgis_version );                # PostGIS

  is_deeply [ DBIO::Storage::Composed->layers_of($composed_class) ],
    [ $AGE_LAYER, $GIS_LAYER ],
    'layers_of records both layers in registration order';
}

# Reverse registration order reverses the layer order, nothing else.
{
  my $rev = DBIO::Storage::Composed
    ->compose('DBIO::PostgreSQL::Storage', [ $GIS_LAYER, $AGE_LAYER ]);
  is_deeply [ DBIO::Storage::Composed->layers_of($rev) ], [ $GIS_LAYER, $AGE_LAYER ],
    'PostGIS + AGE: reverse registration, reverse layer order';
  can_ok $rev, qw( cypher create_graph ensure_postgis );
}

# ===========================================================================
# 2. REGISTRATION WIRING: a schema that load_components both extensions registers
#    BOTH layers via their connection() hooks, and an (offline, lazy) connect
#    composes them over the driver storage the schema declares (-pg; the
#    extensions declare no driver, core ADR 0067). No database is opened.
# ===========================================================================
{
  package T::AgeGisSchema;
  use DBIO 'Schema', -pg;   # the schema declares its driver (core ADR 0067)
  __PACKAGE__->load_components('PostgreSQL::Age', 'PostgreSQL::PostGIS');
}
{
  my $schema = T::AgeGisSchema->connect('dbi:Pg:dbname=dbio_offline_stack', '', '');

  is_deeply [ @{ $schema->storage_layers } ], [ $AGE_LAYER, $GIS_LAYER ],
    'both connection() hooks registered exactly the AGE and PostGIS storage layers';

  my $storage = $schema->storage;
  isa_ok $storage, $AGE_LAYER, 'the connected (unconnected) storage carries the AGE layer';
  isa_ok $storage, $GIS_LAYER, 'the connected (unconnected) storage carries the PostGIS layer';
  isa_ok $storage, 'DBIO::PostgreSQL::Storage',
    'composed over the declared PostgreSQL driver storage';

  # The whole point: cypher (AGE) AND ensure_postgis (PostGIS) on ONE storage.
  can_ok $storage, 'cypher';
  can_ok $storage, 'ensure_postgis';

  ok !$storage->connected,
    'no database was opened for this offline stacking assertion';
}

done_testing;
