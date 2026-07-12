use strict;
use warnings;
use Test::More;
use mro;

# The KEY wiring proof for the composition migration (karr #6, core #70): AGE is
# a storage LAYER now, not a storage_type subclass. Its async sibling
# DBIO::PostgreSQL::Age::Storage::Async is a plain FLOATING layer that core
# composes (C3) OVER whatever transport the chosen async mode resolves. For
# future_io that transport is discovered by convention off the driver
# (DBIO::PostgreSQL::Storage::Async); the Age async layer is mirrored on top.
#
# Pure class/composition assertions: no event loop, no real database. This drives
# the REAL core resolver (DBIO::Storage::DBI::_async_storage) end-to-end on a
# layered, driver-reblessed storage; the dsn is a string parse, nothing connects.
#
# RED/GREEN discriminator: were the Age async layer absent, the future_io walk
# would resolve the plain DBIO::PostgreSQL::Storage::Async transport (CRUD only,
# NO cypher_async). So a composed backend that BOTH isa the transport base AND
# can cypher_async is what proves the floating layer was mirrored and composed.

BEGIN {
  eval { require DBIO::PostgreSQL::Storage::Async; 1 }
    or plan skip_all => 'future_io prerequisites (DBD::Pg/Future/Future::IO) not available';
}

use DBIO::Test;
use DBIO::Storage::DBI;
use DBIO::Storage::Composed;
use DBIO::PostgreSQL::Storage;
use DBIO::PostgreSQL::Age::Storage;
use DBIO::PostgreSQL::Age::Storage::Async;

my $LAYER     = 'DBIO::PostgreSQL::Age::Storage::Async';
my $TRANSPORT = 'DBIO::PostgreSQL::Storage::Async';

# ---------------------------------------------------------------------------
# 0. The async sibling is a plain FLOATING LAYER now -- NOT a transport. This is
#    the migration discriminator: the old class was `use base` the future_io
#    transport; the layer must no longer be one.
# ---------------------------------------------------------------------------
ok !$LAYER->isa('DBIO::Storage::Async'),
  'the Age async sibling is a plain layer, not a DBIO::Storage::Async transport';
ok !$LAYER->isa($TRANSPORT),
  'the Age async sibling no longer subclasses the future_io transport (hard cut)';
can_ok $LAYER, qw( cypher_async create_graph_async drop_graph_async
  required_transport_capabilities );
is_deeply [ $LAYER->required_transport_capabilities ], [ 'on_connect_replay' ],
  'the layer declares on_connect_replay as a required transport capability (LOAD age replay)';

# ---------------------------------------------------------------------------
# 1. future_io is resolved by CONVENTION off the driver -- no explicit
#    per-driver registration. Resolution walks the composition BASE (the driver
#    the Age layer composes over), so we probe there; a plain layer package
#    carries none of the resolver machinery.
# ---------------------------------------------------------------------------
is(
  DBIO::PostgreSQL::Storage->_resolve_async_mode_class(
    'future_io', exclude => 'DBIO::Storage::DBI'),
  undef,
  'no explicit future_io registration on the driver -- the Age transport is resolved by convention',
);

# ---------------------------------------------------------------------------
# 2. Drive the REAL resolver: a layered schema connected { async => 'future_io' }
#    resolves the PG transport off the DRIVER and composes the Age async layer
#    ON TOP. Structural only -- the dsn rebless is a string parse, no DB opened.
# ---------------------------------------------------------------------------
{
  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  $schema->register_storage_layer('DBIO::PostgreSQL::Age::Storage');

  my $composed_class =
    DBIO::Storage::Composed->compose('DBIO::Storage::DBI', ['DBIO::PostgreSQL::Age::Storage']);
  my $storage = $composed_class->new($schema);
  $storage->connect_info(
    [ 'dbi:Pg:dbname=dbio_offline_compose', '', '', { async => 'future_io' } ]
  );

  my $async = eval { $storage->async };
  my $err   = $@;
  ok !$err, 'future_io resolution over a layered Age storage does not croak'
    or diag "died with: $err";

  # Sync storage reblessed onto the PG driver, keeping its Age sync layer.
  isa_ok $storage, 'DBIO::PostgreSQL::Storage',
    'sync storage reblessed onto the PostgreSQL driver';
  isa_ok $storage, 'DBIO::PostgreSQL::Age::Storage',
    'sync storage kept its Age layer through the driver rebless';

  # The composed async backend: transport base + the Age async layer on top.
  ok $async, 'an async backend was resolved';
  isa_ok $async, $TRANSPORT,
    'the composed backend isa the PostgreSQL future_io transport (walk hit the driver)';
  isa_ok $async, 'DBIO::Storage::Async', '... which is a real DBIO::Storage::Async backend';
  isa_ok $async, $LAYER,
    'the floating Age async layer was mirrored and composed ON TOP of the transport';

  # RED/GREEN: cypher_async is the graph-only method the plain transport lacks.
  can_ok $async, qw( cypher_async create_graph_async drop_graph_async );

  is_deeply [ DBIO::Storage::Composed->layers_of(ref $async) ],
    [ $LAYER ],
    'exactly the one Age async layer composed over the PG future_io transport';

  is $storage->async, $async,
    'the resolved backend is cached and feeds the *_async dispatch';
}

done_testing;
