#!/usr/bin/perl
# Regression: the lock-free Int publish must not let a publisher that was
# preempted for a full lap -- between claiming its write_pos and committing its
# slot -- revert a slot a later lap already filled. Such a revert leaves the
# slot's sequence stuck below a subscriber's cursor, so the subscriber stalls
# forever (drain case) or, were only the sequence repaired, reads a stale value.
#
# The fix commits (value, sequence) atomically and DROPS a store whose lap is
# already superseded. This recreates the exact interleaving deterministically
# with the test-only _publish_at(pos, value) hook -- publish at an explicit ring
# position WITHOUT advancing write_pos, i.e. a stale late writer. The hook is
# compiled only under -DPUBSUB_TEST_HOOKS (PUBSUB_TEST_HOOKS=1 at build time);
# the test skips when it is absent.
#
# This test is config-agnostic and should also be run against the mutex
# fallbacks to cover them:
#   PUBSUB_TEST_HOOKS=1 PUBSUB_INT_FORCE_MUTEX=1  perl Makefile.PL && make  # 16-byte Int
#   PUBSUB_TEST_HOOKS=1 PUBSUB_INT8_FORCE_MUTEX=1 perl Makefile.PL && make  # 8-byte Int32/Int16
#
# Without the fix the assertions fail on the SPECIFIC symptom: the fresh
# last-lap value never arrives (permastall) and/or the stale value surfaces.
use strict;
use warnings;
use Test::More;
use Data::PubSub::Shared;

my @variants = (
    ['Int',   'Data::PubSub::Shared::Int'],
    ['Int32', 'Data::PubSub::Shared::Int32'],
    ['Int16', 'Data::PubSub::Shared::Int16'],
);

plan skip_all => 'built without -DPUBSUB_TEST_HOOKS (set PUBSUB_TEST_HOOKS=1 at build)'
    unless $variants[0][1]->can('_publish_at');

my $CAP   = 8;        # power of 2 -> cap_mask 7
my $STALE = 30000;    # fits int16; must never surface
my $FRESH = 100 + $CAP;   # value published at pos == CAP (108)

for my $v (@variants) {
    my ($name, $class) = @$v;
    my $c   = $class->new(undef, $CAP);
    my $sub = $c->subscribe;                   # cursor = write_pos = 0

    # Fill: publish pos 0..CAP (CAP+1 messages). pos 0 and pos CAP both map to
    # slot 0; slot 0 ends holding pos CAP's value (108) with sequence CAP+1.
    $c->publish(100 + $_) for 0 .. $CAP;       # values 100..108, write_pos = CAP+1

    # Stale late writer: a publisher that claimed pos 0 a full lap ago and only
    # now commits. pos 0 maps to slot 0 -- the slot pos CAP just wrote fresh.
    $c->_publish_at(0, $STALE);

    # Drain. The subscriber (cursor 0, CAP+1 behind) overflows to the oldest
    # kept position and must still reach pos CAP's fresh value. With the bug,
    # slot 0 was reverted to sequence 1 and the subscriber stalls there.
    my @got;
    for (1 .. 4 * $CAP) {                      # bounded; poll is non-blocking
        my $x = $sub->poll;
        last unless defined $x;
        push @got, $x;
    }

    ok(  (grep { $_ == $FRESH } @got),  "$name: fresh last-lap value delivered, no stall")
        or diag "drained: @got";
    ok( !(grep { $_ == $STALE } @got),  "$name: stale reverted value never surfaces");
}

# --- the 2^32 sequence-truncation boundary (Int32/Int16 only) ---
# At pos == 2^32-1 the stored sequence is (uint32)(pos+1) == 0, indistinguishable
# from "never written". A stale writer one lap behind (same slot) must still be
# dropped, not allowed to revert the boundary occupant to a stale-low sequence.
# A naive `sequence != 0` bypass re-opens the lap-ABA revert here. Int's boundary
# is 2^64 and unreachable, so it is exempt.
{
    my $BND  = 4294967295;     # 2^32 - 1
    my $CAP2 = 8;
    for my $v (['Int32', 'Data::PubSub::Shared::Int32'],
               ['Int16', 'Data::PubSub::Shared::Int16']) {
        my ($name, $class) = @$v;
        my $c = $class->new(undef, $CAP2);
        $c->_publish_at($BND, 4242);              # boundary occupant: slot sequence -> 0
        is($c->_slot_seq($BND), 0,
           "$name: boundary occupant has truncated sequence 0");
        $c->_publish_at($BND - $CAP2, 9999);      # stale writer one lap behind, same slot
        is($c->_slot_seq($BND), 0,
           "$name: stale lap-behind writer dropped, boundary slot not reverted");
    }
}

done_testing;
