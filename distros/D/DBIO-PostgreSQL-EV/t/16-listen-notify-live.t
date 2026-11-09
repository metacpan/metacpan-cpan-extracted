use strict;
use warnings;
use Test::More;
use Test::Exception;

# LIVE coverage for $storage->listen / $storage->notify / $storage->unlisten
# (Storage.pm:602-701).
#
# WHY this is a live test and not just offline: t/listen-notify.t mocks
# EV::Pg's on_notify, so it only proves that the handler dispatch table is
# populated and that a notify() Future resolves through the pool. It cannot
# prove that a real NOTIFY from one PG session is actually delivered to a
# LISTEN on another PG session. That round-trip goes through libpq's async
# protocol on a dedicated, non-pooled socket — only a real PostgreSQL +
# real sockets + a real second connection emitting pg_notify can exercise
# the wire path. We assert that:
#
#   1. Storage A's listen() callback fires with (channel, payload, sender_pid)
#      when Storage B notifies 'hello-async';
#   2. sender_pid is a positive integer (real backend PID, not 0 / undef);
#   3. multiple sequential notifies on the SAME channel arrive IN ORDER;
#   4. a notify on an UNLISTENED channel does NOT crash either side (the
#      listener simply ignores it);
#   5. $storage->unlisten('test_ch') removes the handler, after which a
#      notify on the same channel does NOT push onto @received.
#
# Design note (one channel per test run): Storage's listen() builds one
# dedicated EV::Pg handle on the first call and reuses it for subsequent
# listen() calls. In testing, issuing a second listen() against an
# already-connected dedicated LISTEN socket has been observed to leave the
# listener silently ignoring notifications on the new channel — the LISTEN
# command appears to be in flight but its callback never fires the on_notify
# dispatcher. We avoid the race by reusing a single channel for the
# ordering section, and rely on the "notify on never-listened channel" path
# (section 4) to prove that notifications on unlistened channels are
# silently ignored — the production PG behaviour we care about, regardless
# of which channel is used.
#
# The "wait until LISTEN is in effect" step awaits the Future listen()
# returns (core ADR 0056, karr k43). Before k43 this file polled the internal
# flag $storage->{_listen_connected}, because there was no public hook; the
# listen Future is that hook now, and it resolves only once the server has
# answered the LISTEN -- not merely once the socket is up -- so the first
# NOTIFY below can no longer race the LISTEN.

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

# Drive a Future to completion on the EV loop under a wall-clock guard, so a
# regression that reintroduces a listen/notify hang fails this test loud.
sub await_guarded {
  my ($f, $what) = @_;
  return GuardedWait->until_ready($f, 15, "TIMEOUT awaiting $what\n");
}

# --- bring up two Storage instances bound to the same DB -------------------

my $listener = DBIO::PostgreSQL::EV::Storage->new(undef);
$listener->connect_info([ \%ci, {} ]);

my $sender = DBIO::PostgreSQL::EV::Storage->new(undef);
$sender->connect_info([ \%ci, {} ]);

# --- 1. one-shot notify round-trip ----------------------------------------

my @received;
my $lf = $listener->listen('test_ch' => sub {
  my ($ch, $payload, $pid) = @_;
  push @received, [ $ch, $payload, $pid ];
});

await_guarded($lf, 'listen test_ch');
ok $lf->is_done, 'listen Future resolved: LISTEN is in effect';

# Send a notify from the other storage. notify() is a normal pooled call.
my $nf = await_guarded($sender->notify('test_ch', 'hello-async'), 'notify #1');
ok $nf->is_done, 'notify Future resolved';

# Allow the dedicated LISTEN socket to deliver the message.
EV::run(EV::RUN_ONCE) until @received;

is scalar(@received), 1, 'listener received exactly one notification';
is_deeply $received[0],
  [ 'test_ch', 'hello-async', $received[0][2] ],
  'received tuple = (channel, payload, sender_pid)';
ok $received[0][2] =~ /^\d+$/ && $received[0][2] > 0,
  'sender_pid is a positive integer (real backend PID)';

my $first_pid = $received[0][2];

# --- 2. multiple sequential notifies arrive in order ----------------------

my $before_order = scalar @received;
for my $i (1..3) {
  await_guarded($sender->notify('test_ch', "msg-$i"), "notify test_ch #$i");
}

# Allow time for the dedicated LISTEN socket to deliver all three messages.
# 200ms is plenty over loopback but still tight enough to fail loud if
# something is actually broken.
my $drain_order_until = EV::time + 0.5;
EV::run(EV::RUN_ONCE) until scalar(@received) >= $before_order + 3 || EV::time >= $drain_order_until;

is scalar(@received), $before_order + 3,
  'three additional sequential notifies all delivered';

my @order_msgs = map { $_->[1] } @received[$before_order .. $before_order + 2];
is_deeply \@order_msgs, [ 'msg-1', 'msg-2', 'msg-3' ],
  'multiple sequential notifies arrive IN ORDER on test_ch';

# --- 3. notify on an UNLISTENED channel is a no-op for the listener -------

my $before = scalar @received;
my $nf3 = await_guarded(
  $sender->notify('never_listened_ch', 'nobody-cares'),
  'notify unknown',
);
ok $nf3->is_done, 'notify Future on unlistened channel still resolves';
# Drain the loop briefly so any (incorrect) delivery has a chance to fire
# before we assert nothing was pushed. We must use a timer watcher —
# `EV::run(EV::RUN_ONCE)` blocks until the next EV event, so a busy-poll
# against EV::time only progresses while the loop is already active. After
# the previous notify Future has resolved and no I/O is pending, EV::run
# would block indefinitely.
EV::now_update();   # a timer counts from the loop's last "now", maybe long ago
my $drain_w = EV::timer(+0.2, 0, sub { EV::unloop });
$drain_w->start;
EV::loop;
$drain_w = undef;
is scalar(@received), $before,
  'notify on a never-listened channel does not push onto @received';

# --- 4. unlisten removes the handler ---------------------------------------

$listener->unlisten('test_ch');
my $before2 = scalar @received;
await_guarded($sender->notify('test_ch', 'after-unlisten'), 'notify after unlisten');
# Drain briefly so a misbehaving listener has a chance to misbehave, then
# assert silence. Timer-driven (see section 3 for why a busy-poll would
# block once the EV loop is idle).
EV::now_update();
my $drain_w2 = EV::timer(+0.2, 0, sub { EV::unloop });
$drain_w2->start;
EV::loop;
$drain_w2 = undef;
is scalar(@received), $before2,
  'handler gone after unlisten — subsequent notify not delivered';

# --- cleanup ---------------------------------------------------------------

$listener->disconnect;
$sender->disconnect;

done_testing;
