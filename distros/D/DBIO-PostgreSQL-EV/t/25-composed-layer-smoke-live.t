use strict;
use warnings;
use Test::More;

# LIVE smoke test for the karr #22 payoff: an async storage extension LAYER
# composed onto the EV transport by core #70's storage-layer composition just
# works -- its async method, issuing '?'-dialect SQL through the inherited
# _query_async, runs end to end over EV::Pg. This is the scenario AGE relies on
# (its Age async mirror composed onto EV, cypher_async issuing '?' SQL). Here a
# generic dummy layer stands in so the transport is proven BEFORE AGE arrives.
#
# Dogfoods DBIO::PostgreSQL::EV::TestHarness.

use DBIO::PostgreSQL::EV::TestHarness;

BEGIN { DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live }

# --- A dummy storage extension: a sync layer + its async mirror --------------
# This mirrors how a real extension (AGE, PostGIS) ships: a plain sync storage
# layer plus a sibling async mirror package (NOT a transport). Core composes the
# async mirror ON TOP of the resolved EV transport.
{
  package DBIO::PostgreSQL::EV::TestDummyLayer;
  sub _dummy_layer_marker { 1 }            # sync layer (marker only)

  package DBIO::PostgreSQL::EV::TestDummyLayer::Async;
  # The async mirror method: issues '?'-dialect SQL through the transport's
  # inherited _query_async (which shapes '?' -> '$N' internally) and resolves a
  # scalar. Because it is composed onto the EV transport, $self isa the EV
  # storage and _query_async Just Works.
  sub dummy_async_double {
    my ($self, $n) = @_;
    return $self->_query_async('SELECT (?::int * 2) AS doubled', [ $n ])
      ->then(sub { my @rows = @_; return $rows[0][0] });
  }

  package DBIO::PostgreSQL::EV::TestDummySchema;
  use base 'DBIO::Schema';
  __PACKAGE__->load_components('PostgreSQL');
  __PACKAGE__->register_storage_layer('DBIO::PostgreSQL::EV::TestDummyLayer');
}

my $h = DBIO::PostgreSQL::EV::TestHarness->new(
  schema_class => 'DBIO::PostgreSQL::EV::TestDummySchema',
);

my $async = $h->async;

# The async backend is the EV transport with the dummy async layer composed in.
isa_ok $async, 'DBIO::PostgreSQL::EV::Storage',
  'composed async backend is still the EV transport at its base';
isa_ok $async, 'DBIO::PostgreSQL::EV::TestDummyLayer::Async',
  'the extension async layer was mirrored and composed onto the transport (core #70)';
can_ok $async, 'dummy_async_double';

# The composed layer's async method, issuing '?' SQL, resolves correctly.
my $doubled = $h->await( $async->dummy_async_double(21) );
is $doubled, 42,
  'composed layer async method runs its ? SQL over EV end to end (21 * 2 = 42)';

# And it works through a pinned pool connection too (the exact seam an extension
# uses to assert replay on each pooled connection).
my @per_conn = $h->run_on_each_pooled_connection(2, sub {
  my ($conn, $harness) = @_;
  return $harness->query_on($conn, 'SELECT (?::int + 1) AS incremented', [ 100 ]);
});
is scalar(@per_conn), 2, 'composed transport served 2 distinct pooled connections';
is $per_conn[0][0][0], 101, 'pinned ? query on pooled connection 0 resolved';
is $per_conn[1][0][0], 101, 'pinned ? query on pooled connection 1 resolved';

$h->disconnect;

done_testing;
