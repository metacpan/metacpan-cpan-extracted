use strict;
use warnings;
use Test::More;

# LIVE test for the karr #22 WP3 / karr #68 pool-connect replay: on_connect_do
# AND on_connect_call must run on EVERY freshly-spawned EV pool connection, so a
# pooled async connection has the same session setup as the sync path. This is
# facet 1 of core #69 (ev silently dropping the connect-action replay), now
# structurally impossible at the transport.
#
# WHY live: the replay drives real SET statements to completion on real libpq
# connections at spawn time (DBIO::PostgreSQL::EV::Storage::_run_pool_connect_statement,
# a blocking loop-run over EV). Each pooled connection is a separate PG session,
# so proving the setting is visible on EACH of N distinct connections is proving
# the replay fired per spawn. A mock cannot exercise the blocking-at-spawn path.
#
# Dogfoods DBIO::PostgreSQL::EV::TestHarness (the reusable, INSTALLABLE harness
# an extension like AGE reuses for the identical LOAD 'age' replay assertion).

use DBIO::PostgreSQL::EV::TestHarness;

BEGIN { DBIO::PostgreSQL::EV::TestHarness->skip_all_unless_live }

my $N = 3;

my $h = DBIO::PostgreSQL::EV::TestHarness->new(
  connect_attrs => {
    # on_connect_do: a plain SET replayed verbatim.
    on_connect_do   => [ q{SET myapp.replay_do = 'do-ran'} ],
    # on_connect_call: exercises connect_call_* resolution on the OWNING sync
    # storage (connect_call_do_sql is core's) -- the same dispatch AGE's
    # connect_call_load_age rides.
    on_connect_call => [ [ do_sql => q{SET myapp.replay_call = 'call-ran'} ] ],
    pool_size       => $N,
  },
);

isa_ok $h->async, 'DBIO::PostgreSQL::EV::Storage',
  'harness async backend is the EV transport';
isa_ok $h->sync_storage, 'DBIO::PostgreSQL::Storage',
  'owning sync storage is the PostgreSQL driver storage';
ok( (grep { $_ eq 'on_connect_replay' } $h->async->transport_capabilities),
  'transport advertises the on_connect_replay capability' );

# Force $N distinct pool connections to spawn (each replays the connect actions
# at spawn) and read both custom GUCs back on each one.
my @per_conn = $h->run_on_each_pooled_connection($N, sub {
  my ($conn, $harness) = @_;
  return $harness->query_on($conn, q{
    SELECT current_setting('myapp.replay_do',   true) AS replay_do,
           current_setting('myapp.replay_call', true) AS replay_call
  });
});

is scalar(@per_conn), $N, "the assertion op ran on all $N spawned pool connections";

for my $i (0 .. $#per_conn) {
  my $row = $per_conn[$i][0];   # each entry is [ @rows ]; first (only) row
  is $row->[0], 'do-ran',
    "connection $i: on_connect_do replayed on this pooled connection";
  is $row->[1], 'call-ran',
    "connection $i: on_connect_call replayed on this pooled connection";
}

$h->disconnect;

done_testing;
