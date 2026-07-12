use strict;
use warnings;
use Test::More;

# LIVE test for the karr #19 WP3 / karr #18 / core #68 pool-connect replay:
# on_connect_do AND on_connect_call must run on EVERY freshly-spawned EV pool
# connection, so a pooled async connection has the same session setup as the sync
# path. Before karr #18 the ev MySQL pool wired no {storage} back-ref, so the
# replay silently never fired.
#
# WHY live: the replay drives real SET statements to completion on real
# EV::MariaDB connections at spawn time
# (DBIO::MySQL::EV::Storage::_run_pool_connect_statement, a blocking loop-run
# over EV). Each pooled connection is a separate MySQL session, so proving a
# session user-variable is visible on EACH of N distinct connections proves the
# replay fired per spawn. A mock cannot exercise the blocking-at-spawn path.
#
# Dogfoods DBIO::MySQL::EV::TestHarness (the reusable, INSTALLABLE harness a
# downstream extension reuses for the identical on_connect_call replay assertion).

use DBIO::MySQL::EV::TestHarness;

BEGIN { DBIO::MySQL::EV::TestHarness->skip_all_unless_live }

my $N = 3;

my $h = DBIO::MySQL::EV::TestHarness->new(
  connect_attrs => {
    # on_connect_do: a plain SET of a session user-variable, replayed verbatim.
    on_connect_do   => [ q{SET @dbio_replay_do = 'do-ran'} ],
    # on_connect_call: exercises connect_call_* resolution on the OWNING sync
    # storage (connect_call_do_sql is core's) -- the same dispatch a real
    # extension's connect_call_* rides.
    on_connect_call => [ [ do_sql => q{SET @dbio_replay_call = 'call-ran'} ] ],
    pool_size       => $N,
  },
);

isa_ok $h->async, 'DBIO::MySQL::EV::Storage',
  'harness async backend is the EV transport';
isa_ok $h->sync_storage, 'DBIO::MySQL::Storage',
  'owning sync storage is the MySQL driver storage';
ok( (grep { $_ eq 'on_connect_replay' } $h->async->transport_capabilities),
  'transport advertises the on_connect_replay capability' );

# Force $N distinct pool connections to spawn (each replays the connect actions
# at spawn) and read both session user-variables back on each one.
my @per_conn = $h->run_on_each_pooled_connection($N, sub {
  my ($conn, $harness) = @_;
  return $harness->query_on($conn,
    q{SELECT @dbio_replay_do AS replay_do, @dbio_replay_call AS replay_call});
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
