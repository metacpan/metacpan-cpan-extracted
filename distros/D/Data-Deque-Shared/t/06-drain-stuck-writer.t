use strict;
use warnings;
use Test::More;
use File::Temp qw(tempfile);
use Time::HiRes qw(time);
use Data::Deque::Shared;

# Regression test for drain() deadlock when a pusher dies between cursor CAS
# and slot publish.
#
# Two stall windows exercised:
#   (A) cursor CAS done, claim_write NOT yet — slot still EMPTY@gen
#   (B) claim_write done, publish NOT yet — slot WRITING@gen
# drain() must bound the wait in both cases and force-skip via gen-bump.

# DeqHeader layout (deque.h):
#   0:   uint32_t magic
#   4:   uint32_t version
#   8:   uint32_t elem_size
#   12:  uint32_t variant_id
#   16:  uint64_t capacity
#   24:  uint64_t total_size
#   32:  uint64_t data_off
#   40:  uint64_t ctl_off
#   48:  uint8_t  _pad0[16]
#   64:  uint64_t cursor       ((head<<32)|tail)
my $CTL_OFF_AT    = 40;
my $CURSOR_OFF_AT = 64;

# Slot ctl word: (generation << 2) | state
# states: EMPTY=0 WRITING=1 FILLED=2 READING=3
my $STATE_EMPTY   = 0;
my $STATE_WRITING = 1;

sub _ctl_off {
    my ($fh) = @_;
    sysseek $fh, $CTL_OFF_AT, 0 or die "seek: $!";
    my $buf;
    sysread $fh, $buf, 8;
    return unpack 'Q<', $buf;
}

sub poke_ctl_state {
    my ($path, $slot_idx, $new_state_bits) = @_;
    open my $fh, '+<:raw', $path or die "open $path: $!";
    my $ctl_off = _ctl_off($fh);
    my $word_off = $ctl_off + $slot_idx * 8;
    sysseek $fh, $word_off, 0 or die "seek slot: $!";
    my $buf;
    sysread $fh, $buf, 8;
    my $cw = unpack 'Q<', $buf;
    my $gen = $cw >> 2;
    my $new_cw = ($gen << 2) | $new_state_bits;
    sysseek $fh, $word_off, 0 or die "seek slot write: $!";
    syswrite $fh, pack('Q<', $new_cw), 8;
    close $fh;
}

sub poke_cursor_tail {
    my ($path, $new_tail) = @_;
    open my $fh, '+<:raw', $path or die "open $path: $!";
    sysseek $fh, $CURSOR_OFF_AT, 0 or die "seek cursor: $!";
    my $buf;
    sysread $fh, $buf, 8;
    my $cursor = unpack 'Q<', $buf;
    my $head = ($cursor >> 32) & 0xFFFFFFFF;
    my $new_cursor = ($head << 32) | ($new_tail & 0xFFFFFFFF);
    sysseek $fh, $CURSOR_OFF_AT, 0 or die "seek cursor write: $!";
    syswrite $fh, pack('Q<', $new_cursor), 8;
    close $fh;
}

# --- Scenario B: stuck WRITING (publish window) ---------------------
{
    my (undef, $path) = tempfile(OPEN => 0, SUFFIX => '.dq');
    my $cap = 8;
    my $dq = Data::Deque::Shared::Int->new($path, $cap);

    # push 4 items, so head=0, tail=4, slots 0..3 are FILLED
    $dq->push_back($_) for 1..4;
    is $dq->size, 4, 'B: four items pushed';

    # Simulate a dead pusher on slot index 2: rewrite ctl FILLED -> WRITING.
    poke_ctl_state($path, 2, $STATE_WRITING);

    my $t0 = time;
    my $count = $dq->drain;
    my $elapsed = time - $t0;

    is $count, 4, 'B: drain returned snapshot count including stuck slot';
    is $dq->size, 0, 'B: cursor reset by drain';
    cmp_ok $elapsed, '<', 5.0, "B: drain completed in ${elapsed}s (must be < 5s)";
    cmp_ok $elapsed, '>=', 1.5, "B: drain waited ~2s before recovering (got ${elapsed}s)";

    my $stats = $dq->stats;
    cmp_ok $stats->{recoveries}, '>=', 1, 'B: stat_recoveries incremented';

    # After recovery the deque must still be usable.
    ok $dq->push_back(100), 'B: push_back after recovery';
    ok $dq->push_back(200), 'B: second push_back after recovery';
    is $dq->pop_front, 100, 'B: pop_front yields recovered-slot push';
    is $dq->pop_front, 200;

    unlink $path;
}

# --- Scenario A: stuck EMPTY (claim_write window) -------------------
# Pusher won cursor CAS but died BEFORE calling claim_write. Cursor advanced
# but slot ctl is still EMPTY@gen from the prior cycle (or zero on a fresh
# deque). Without recovery for this state, drain spins forever.
{
    my (undef, $path) = tempfile(OPEN => 0, SUFFIX => '.dq');
    my $cap = 8;
    my $dq = Data::Deque::Shared::Int->new($path, $cap);

    # Push 3 items normally; slots 0..2 FILLED. Then poke cursor tail=4
    # without ever filling slot 3 — simulating a pusher that won the
    # cursor CAS for tail->4 but died before claim_write.
    $dq->push_back($_) for 1..3;
    poke_cursor_tail($path, 4);
    is $dq->size, 4, 'A: cursor advanced (size reflects fake push)';

    my $t0 = time;
    my $count = $dq->drain;
    my $elapsed = time - $t0;

    is $count, 4, 'A: drain returned full count';
    is $dq->size, 0, 'A: drain reset cursor';
    cmp_ok $elapsed, '<', 5.0, "A: drain completed in ${elapsed}s (must not hang)";
    cmp_ok $elapsed, '>=', 1.5, "A: drain waited ~2s before recovering (got ${elapsed}s)";

    my $stats = $dq->stats;
    cmp_ok $stats->{recoveries}, '>=', 1, 'A: stat_recoveries incremented';

    ok $dq->push_back(300), 'A: push_back after recovery';
    is $dq->pop_front, 300, 'A: pop_front yields fresh value';

    unlink $path;
}

done_testing;
