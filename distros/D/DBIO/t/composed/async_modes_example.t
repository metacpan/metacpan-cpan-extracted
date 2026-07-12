# ABSTRACT: karr #71 -- the DBIO::Storage::Async "layered schema across async
# transports" example, proven with SYNTHETIC stand-ins (mock-only, no real DB,
# no downstream deps). This is the suite backing for the worked narrative in the
# DBIO::Storage::Async POD (karr #72 convention: every synopsis has a test).
#
# The POD example names AGE / PostGIS / EV -- downstream dists core cannot depend
# on -- so here we reproduce only the MECHANISM the example relies on:
#
#   POD example                          this test
#   -----------                          ---------
#   DBIO::PostgreSQL::Age    (graph)  -> T::AME::GraphLayer  (+ ::Async mirror)
#   DBIO::PostgreSQL::PostGIS (spat)  -> T::AME::SpatialLayer (sync-only, NO ::Async)
#   future_io transport (convention)  -> T::AME::Storage::Async
#   ev transport (registry)           -> T::AME::EV::Storage
#   AGE's on_connect_replay need      -> capability 'on_connect_replay'
#
# ONE schema class carries both layers; the async execution model is chosen PER
# CONNECTION (ADR 0030), so the same class resolves a DISTINCT composed backend
# for each mode -- and two of them can be held at once. The real AGE+PostGIS+EV
# realization is exercised by the DBIO-PostgreSQL-Age suite (t/40-stacking.t,
# t/41-dual-mode-coexistence.t, t/42-immediate-smoke.t, t/43-ev-integration-live.t).
use strict;
use warnings;

use Test::More;

use DBIO::Schema;
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::Storage::Composed;
use DBIO::Future::Immediate;
use DBIO::Test::Storage;

# ---------------------------------------------------------------------------
# A recording transport base: a concrete DBIO::Storage::Async whose query seam
# records the SQL it is handed and resolves an immediate Future, so the test
# needs neither an event loop nor a CPAN Future.
# ---------------------------------------------------------------------------
{
  package T::AME::RecordingTransport;
  use base 'DBIO::Storage::Async';
  use mro 'c3';

  sub future_class { 'DBIO::Future::Immediate' }

  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{recorded} ||= [] }, $sql;
    return DBIO::Future::Immediate->done([ recorded => $sql ]);
  }
  sub recorded { @{ $_[0]->{recorded} || [] } }
}

# --- the two SYNC storage layers registered on the schema ------------------
# graph-ish: a sync method + an ::Async mirror that declares a required
# transport capability and carries the async-only method.
{ package T::AME::GraphLayer;        sub cypher { 'sync-cypher' } }
{
  package T::AME::GraphLayer::Async;
  sub required_transport_capabilities { ('on_connect_replay') }
  sub cypher_async {
    my ($self, $query) = @_;
    return $self->_query_async("CYPHER $query", []);
  }
}
# spatial-ish: sync-only -- NO ::Async sibling, so it never composes onto an
# async backend (geometry CRUD flows through the transport unchanged).
{ package T::AME::SpatialLayer;      sub ensure_spatial { 'ensured' } }

# --- the driver stand-in + its transports ----------------------------------
# T::AME::Storage stands in for a concrete PostgreSQL storage. It is a
# DBIO::Test::Storage subclass so connect() never opens a real connection
# (_determine_driver is a no-op) -- mock-only, per core testing rules.
{ package T::AME::Storage;         use base 'DBIO::Test::Storage';       use mro 'c3'; }

# future_io transport, resolved BY CONVENTION as <base>::Async.
{ package T::AME::Storage::Async;  use base 'T::AME::RecordingTransport'; use mro 'c3';
  sub transport_capabilities { ('on_connect_replay') } }

# ev transport, resolved from the registry (register_async_mode below).
{ package T::AME::EV::Storage;     use base 'T::AME::RecordingTransport'; use mro 'c3';
  sub transport_capabilities { ('on_connect_replay') } }

# a transport that provides NO capabilities -- the gate must refuse the graph
# async layer over it.
{ package T::AME::Gapless::Storage; use base 'T::AME::RecordingTransport'; use mro 'c3'; }

T::AME::Storage->register_async_mode( ev      => 'T::AME::EV::Storage' );
T::AME::Storage->register_async_mode( gapless => 'T::AME::Gapless::Storage' );

# --- the ONE schema class, defined once with BOTH layers -------------------
{
  package T::AME::Schema;
  use base 'DBIO::Schema';
  __PACKAGE__->storage_type('T::AME::Storage');
  __PACKAGE__->register_storage_layer('T::AME::GraphLayer');
  __PACKAGE__->register_storage_layer('T::AME::SpatialLayer');
}

# connect(sub {}) is the standard lazy/offline pattern: it builds and stores the
# composed storage but never connects. $mode (or undef) drives { async => ... }.
sub connect_mode {
  my ($mode) = @_;
  my @attrs = defined $mode ? ({ async => $mode }) : ();
  return T::AME::Schema->connect(sub {}, @attrs);
}

# ===========================================================================
# 1. The schema, defined once, composes BOTH layers onto one sync object.
# ===========================================================================
my $s_fio    = connect_mode('future_io');
my $sync_fio = $s_fio->storage;

isa_ok $sync_fio, 'T::AME::GraphLayer',   'sync storage isa the graph layer';
isa_ok $sync_fio, 'T::AME::SpatialLayer', 'sync storage isa the spatial layer';
isa_ok $sync_fio, 'T::AME::Storage',      'sync storage isa the driver stand-in';
can_ok $sync_fio, 'cypher';           # graph sync method (example: cypher())
can_ok $sync_fio, 'ensure_spatial';   # spatial sync method (example: ensure_postgis())

# ===========================================================================
# 2. future_io: the graph async layer composes over the convention transport;
#    the sync-only spatial layer does not; the async method rides the transport.
# ===========================================================================
my $async_fio = $s_fio->storage->async;
ok $async_fio, 'future_io resolved an async backend';
isa_ok $async_fio, 'T::AME::Storage::Async',    'future_io transport resolved by convention';
isa_ok $async_fio, 'DBIO::Storage::Async',      '... is a real DBIO::Storage::Async transport';
isa_ok $async_fio, 'T::AME::GraphLayer::Async', 'the graph async mirror composed over the transport';
can_ok $async_fio, 'cypher_async';

ok !$async_fio->isa('T::AME::SpatialLayer'),
  'the sync-only spatial layer is absent from the async backend';
ok !$async_fio->can('ensure_spatial'),
  'spatial sync methods are absent from the async backend';
ok !$async_fio->isa('T::AME::GraphLayer'),
  'the SYNC graph layer is not composed -- only its ::Async mirror is';

is_deeply [ DBIO::Storage::Composed->layers_of(ref $async_fio) ],
  [ 'T::AME::GraphLayer::Async' ],
  'exactly the one async mirror layer over the future_io transport';

my $f = $async_fio->cypher_async('MATCH (n) RETURN n');
isa_ok $f, 'DBIO::Future::Immediate', 'cypher_async returns a Future';
ok $f->is_ready, '... already resolved (recording transport, no loop)';
is_deeply [ $async_fio->recorded ], [ 'CYPHER MATCH (n) RETURN n' ],
  'cypher_async routed its query through the future_io transport seam';

# ===========================================================================
# 3. ev: the SAME schema class, a different mode -> a DISTINCT composed backend
#    over a DIFFERENT transport, held at the same time as the future_io one.
# ===========================================================================
my $s_ev    = connect_mode('ev');
my $async_ev = $s_ev->storage->async;

isa_ok $async_ev, 'T::AME::EV::Storage',       'ev transport resolved from the registry';
isa_ok $async_ev, 'T::AME::GraphLayer::Async', 'the same graph async layer, over the ev transport';
is_deeply [ DBIO::Storage::Composed->layers_of(ref $async_ev) ],
  [ 'T::AME::GraphLayer::Async' ],
  'exactly the one async mirror layer over the ev transport';
ok !$async_ev->isa('T::AME::SpatialLayer'),
  'the sync-only spatial layer is absent from the ev backend too';

isnt ref($async_fio), ref($async_ev),
  'the same schema class resolved TWO DISTINCT composed backends (mode is per-connection)';
ok !$async_ev->isa('T::AME::Storage::Async'),
  'the ev backend is NOT the future_io transport';
ok !$async_fio->isa('T::AME::EV::Storage'),
  'the future_io backend is NOT the ev transport';

# both backends are live and independent at once
$async_ev->cypher_async('MATCH (m) RETURN m');
is_deeply [ $async_ev->recorded ], [ 'CYPHER MATCH (m) RETURN m' ],
  'the ev backend records on its OWN transport';
is_deeply [ $async_fio->recorded ], [ 'CYPHER MATCH (n) RETURN n' ],
  'the future_io backend still holds only its own recording (backends are independent)';

# ===========================================================================
# 4. immediate: no event loop, no embedded backend -- *_async runs in-process
#    and returns an already-resolved Future.
# ===========================================================================
my $s_imm = connect_mode('immediate');
ok !defined $s_imm->storage->async,
  'immediate builds NO embedded backend (Future::Immediate is not a transport)';

my $fi = $s_imm->storage->txn_do_async(sub { return 'done-immediate' });
isa_ok $fi, 'DBIO::Future::Immediate', 'immediate *_async returns an immediate Future';
ok $fi->is_ready, '... already resolved, with no event loop';
is scalar $fi->get, 'done-immediate', '... carrying the in-process result';

# ===========================================================================
# 5. No async mode (plain sync connect): the *_async methods croak -- async is
#    opt-in per connection.
# ===========================================================================
my $s_sync = connect_mode(undef);
ok !defined $s_sync->storage->_async_mode,
  'a plain sync connect chose no async mode';

eval { $s_sync->storage->txn_do_async(sub {}) };
like $@, qr/not an async connection/,
  'txn_do_async on a no-mode connection croaks';
eval { $s_sync->storage->select_async('artist', ['*'], {}) };
like $@, qr/not an async connection/,
  'select_async on a no-mode connection croaks too -- async is opt-in';

# ===========================================================================
# 6. Capability gate: a transport that does not declare a required capability is
#    refused, naming the layer, the capability and the transport.
# ===========================================================================
my $s_gap = connect_mode('gapless');
eval { $s_gap->storage->async };
my $err = $@;
ok $err, 'a transport lacking a required capability croaks';
like $err, qr/T::AME::GraphLayer::Async/, '... naming the async layer';
like $err, qr/on_connect_replay/,          '... naming the missing capability';
like $err, qr/T::AME::Gapless::Storage/,    '... naming the transport';
like $err, qr/choose another async mode/,   '... with the upgrade/choose hint';

done_testing;
