use strict;
use warnings;
use Test::More;
use mro;

# WP4b (karr #6) -- the family's canonical MULTI-EXTENSION regression (core #69
# facet 2). Two storage-layer extensions on ONE schema: AGE (graph) and PostGIS
# (spatial). Both are plain layers; core composes them (C3) over the resolved
# driver storage into a single class that isa AND can BOTH. Their method sets are
# DISJOINT (AGE deliberately does NOT hook dbio_deploy_class, which PostGIS owns),
# so composition does not trip the layer-collision check.
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
# 0. Precondition: AGE and PostGIS own DISJOINT method sets. AGE must NOT define
#    its own dbio_deploy_class (PostGIS's single-owner base override) -- that is
#    exactly what lets the two compose without a collision croak.
# ===========================================================================
ok !$AGE_LAYER->can('dbio_deploy_class'),
  'the AGE layer does NOT define dbio_deploy_class (so it never collides with PostGIS)';
ok $GIS_LAYER->can('dbio_deploy_class'),
  'the PostGIS layer DOES own dbio_deploy_class (single-owner base override)';

# ===========================================================================
# 1. Direct compose of both layers over the PG driver: it does NOT croak, and the
#    composed class isa BOTH and can BOTH surfaces.
# ===========================================================================
{
  my $composed_class = eval {
    DBIO::Storage::Composed->compose('DBIO::PostgreSQL::Storage', [ $AGE_LAYER, $GIS_LAYER ]);
  };
  my $err = $@;
  ok !$err, 'composing the AGE and PostGIS layers together does NOT croak (disjoint methods)'
    or diag "died with: $err";

  ok $composed_class->isa($AGE_LAYER), 'composed class isa the AGE layer';
  ok $composed_class->isa($GIS_LAYER), 'composed class isa the PostGIS layer';
  ok $composed_class->isa('DBIO::PostgreSQL::Storage'), 'composed class isa the PG driver base';

  can_ok $composed_class, qw( cypher create_graph drop_graph cypher_async );  # AGE
  can_ok $composed_class, qw( ensure_postgis postgis_version );                # PostGIS

  is_deeply [ DBIO::Storage::Composed->layers_of($composed_class) ],
    [ $AGE_LAYER, $GIS_LAYER ],
    'layers_of records both layers in registration order';

  # Single-owner deploy hook: PostGIS owns it, AGE does not touch it, so the
  # composed class routes deploy through PostGIS's deploy class.
  is $composed_class->dbio_deploy_class, 'DBIO::PostgreSQL::PostGIS::Deploy',
    'the composed storage selects the PostGIS deploy class (AGE adds no rival)';
}

# ===========================================================================
# 2. REGISTRATION WIRING: a schema that load_components both extensions registers
#    BOTH layers via their connection() hooks, and an (offline, lazy) connect
#    composes them over the resolved base storage. No database is opened.
# ===========================================================================
{
  package T::AgeGisSchema;
  use base qw( DBIO::PostgreSQL::Age DBIO::PostgreSQL::PostGIS DBIO::Schema );
  use mro 'c3';
}
{
  my $schema = T::AgeGisSchema->connect('dbi:Pg:dbname=dbio_offline_stack', '', '');

  is_deeply [ @{ $schema->storage_layers } ], [ $AGE_LAYER, $GIS_LAYER ],
    'both connection() hooks registered exactly the AGE and PostGIS storage layers';

  my $storage = $schema->storage;
  isa_ok $storage, $AGE_LAYER, 'the connected (unconnected) storage carries the AGE layer';
  isa_ok $storage, $GIS_LAYER, 'the connected (unconnected) storage carries the PostGIS layer';
  ok $storage->isa('DBIO::Storage::DBI'), 'composed over the resolved base storage';

  # The whole point: cypher (AGE) AND ensure_postgis (PostGIS) on ONE storage.
  can_ok $storage, 'cypher';
  can_ok $storage, 'ensure_postgis';

  ok !$storage->connected,
    'no database was opened for this offline stacking assertion';
}

done_testing;
