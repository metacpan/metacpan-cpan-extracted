use strict;
use warnings;
use Test::More;
use Test::Exception;

# Regression test for karr k15:
#   "second listen() on same Storage silently breaks notifications"
#
# Storage.pm:listen used to register only the first channel correctly.
# Subsequent calls to listen() on the same Storage (with the dedicated
# LISTEN connection already up) DID queue the LISTEN SQL on EV::Pg but
# the resulting notifications on the new channel were never delivered
# to the registered callback. The first channel kept working fine.
#
# This test would fail loudly against the original implementation:
#   - @received_b stays empty while @received_a gets 'one'.
# After the fix both arrays contain their respective payloads.
#
# Three test sections cover the bug surface:
#   1. 2 channels, second registered AFTER first is connected (the
#      original repro: listen a, connect, listen b, notify each).
#   2. 3 channels all registered AFTER the dedicated conn is up
#      (stress the "already connected" branch harder).
#   3. unlisten a, then listen c on the now-disconnected-from-a
#      connection — proves the bookkeeping tracks which channels
#      the dedicated conn has subscribed to and unlistens actually
#      stop delivery.

BEGIN {
  plan skip_all => 'Set DBIO_TEST_PG_DSN to run integration tests'
    unless $ENV{DBIO_TEST_PG_DSN};
}

use EV;
use EV::Pg;
use DBIO::PostgreSQL::EV::Storage;

# The test login as the libpq parameters the transport reads it as; a server
# that is not there fails the file, with a plan (karr k77).
use FindBin;
use lib "$FindBin::Bin/lib";
use LiveServer;
use GuardedWait;
LiveServer->require_server;
my %ci = LiveServer->conninfo;

# The file's backstop: a hang anywhere in it ends the process. A guarded wait
# has a timeout of its own and leaves this alarm running (karr k88).
alarm 120;

# Drive a Future to completion on the EV loop under a wall-clock guard.
sub await_guarded {
  my ($f, $what) = @_;
  return GuardedWait->until_ready($f, 15, "TIMEOUT awaiting $what\n");
}

# Wait until the dedicated LISTEN connection is open -- and so its first
# LISTEN has just been sent and is still in flight, the moment the k15 race
# needs. karr k43: core owns the connection now (ADR 0056), and it is in core's
# listen state from the connect on; before k43 this polled this transport's
# own flag $storage->{_listen_connected}. Reading core's state is a test's
# privilege: awaiting the listen Future instead would wait for the LISTEN to
# be answered and so step around the race this file exists for.
sub listen_connected {
  my ($storage) = @_;
  return $storage->{_listen} && $storage->{_listen}{conn} ? 1 : 0;
}

sub await_listen_connected {
  my ($storage, $what) = @_;
  my $deadline = EV::time + 2;
  my $count    = 0;
  while (!listen_connected($storage)) {
    return 0 if EV::time >= $deadline || ++$count > 1000;
    EV::run(EV::RUN_ONCE);
  }
  die "TIMEOUT waiting for the listen connection ($what)\n"
    unless listen_connected($storage);
  return 1;
}

# Drain the EV loop briefly so a late-arriving notification has a chance
# to fire before we assert. Timer-driven (not busy-poll) because once
# nothing is pending, EV::run blocks indefinitely.
sub drain_briefly {
  my ($seconds) = @_;
  $seconds //= 0.5;
  EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
  my $w = EV::timer($seconds, 0, sub { EV::unloop });
  $w->start;
  EV::loop;
  $w = undef;
}

my $listener = DBIO::PostgreSQL::EV::Storage->new(undef);
$listener->connect_info([ \%ci, {} ]);

my $sender = DBIO::PostgreSQL::EV::Storage->new(undef);
$sender->connect_info([ \%ci, {} ]);

# --- 1. two channels; second registered AFTER first is connected -------
# This is the original repro: register ch_a, wait for connect, register
# ch_b on the already-connected listener, notify each, expect BOTH
# callbacks to fire.

my @received_a;
my @received_b;

$listener->listen('ch_a' => sub {
  my ($ch, $payload, $pid) = @_;
  push @received_a, [ $ch, $payload ];
});

await_listen_connected($listener, 'listen ch_a');

# Second listen(), AFTER the dedicated connection is up — this is the
# branch the original bug breaks.
$listener->listen('ch_b' => sub {
  my ($ch, $payload, $pid) = @_;
  push @received_b, [ $ch, $payload ];
});

# Give EV::Pg a moment to send LISTEN "ch_b" and receive its
# CommandComplete. Otherwise the NOTIFY for ch_b may race the LISTEN
# ack and PostgreSQL drops it. Same drain pattern as elsewhere in
# t/16: timer-driven to avoid blocking on an idle loop.
drain_briefly(0.2);

await_guarded($sender->notify('ch_a', 'one'),   'notify ch_a');
await_guarded($sender->notify('ch_b', 'two'),   'notify ch_b');

drain_briefly(0.5);

is scalar(@received_a), 1, 'ch_a callback fired once';
is $received_a[0][0], 'ch_a', 'ch_a callback received on ch_a';
is $received_a[0][1], 'one',  'ch_a callback got the right payload';

is scalar(@received_b), 1, 'ch_b callback fired once (regression: second listen works)';
is $received_b[0][0], 'ch_b', 'ch_b callback received on ch_b';
is $received_b[0][1], 'two',  'ch_b callback got the right payload';

# --- 2. three channels, all registered AFTER connect ---------------------
# Stress the "already connected, dispatch directly" path with a 3rd
# channel to make sure the bookkeeping scales beyond 2.

my @received_c;

$listener->listen('ch_c' => sub {
  my ($ch, $payload, $pid) = @_;
  push @received_c, [ $ch, $payload ];
});

drain_briefly(0.2);

await_guarded($sender->notify('ch_a', 'again-a'), 'notify ch_a #2');
await_guarded($sender->notify('ch_b', 'again-b'), 'notify ch_b #2');
await_guarded($sender->notify('ch_c', 'three'),   'notify ch_c');

drain_briefly(0.5);

is scalar(@received_a), 2, 'ch_a still receives after ch_b/ch_c added';
is $received_a[1][1], 'again-a', 'ch_a second payload correct';

is scalar(@received_b), 2, 'ch_b still receives after ch_c added';
is $received_b[1][1], 'again-b', 'ch_b second payload correct';

is scalar(@received_c), 1, 'ch_c callback fired (regression: 3rd channel works)';
is $received_c[0][0], 'ch_c', 'ch_c callback received on ch_c';
is $received_c[0][1], 'three', 'ch_c callback got the right payload';

# --- 3. unlisten(ch_a) actually stops delivery, others keep working ------

$listener->unlisten('ch_a');
drain_briefly(0.2);

my $before_a = scalar @received_a;
my $before_b = scalar @received_b;
my $before_c = scalar @received_c;

await_guarded($sender->notify('ch_a', 'should-not-arrive'), 'notify ch_a after unlisten');
await_guarded($sender->notify('ch_b', 'still-here'),       'notify ch_b after unlisten a');
await_guarded($sender->notify('ch_c', 'still-here-c'),     'notify ch_c after unlisten a');

drain_briefly(0.5);

is scalar(@received_a), $before_a,
  'unlisten(ch_a) stopped delivery — no new ch_a notifications';
is scalar(@received_b), $before_b + 1,
  'ch_b still receives after unlisten(ch_a)';
is $received_b[-1][1], 'still-here', 'ch_b got the right post-unlisten payload';
is scalar(@received_c), $before_c + 1,
  'ch_c still receives after unlisten(ch_a)';
is $received_c[-1][1], 'still-here-c', 'ch_c got the right post-unlisten payload';

# --- cleanup -------------------------------------------------------------

$listener->disconnect;
$sender->disconnect;

done_testing;