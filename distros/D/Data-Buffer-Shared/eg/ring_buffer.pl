#!/usr/bin/env perl
# Lock-free SPSC ring buffer (single producer, single consumer)
#
# Head/tail indices in I64 (atomic), payload in F32.
# Producer: write at tail, atomic incr tail.
# Consumer: read from head up to tail, atomic store head.
# No locks, no syscalls on the fast path.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time);

use Data::Buffer::Shared::F32;
use Data::Buffer::Shared::I64;

my $ring_size = 4096;  # must be power of 2
my $mask = $ring_size - 1;
my $total_items = 100_000;

my $ring = Data::Buffer::Shared::F32->new_anon($ring_size);
my $ctl = Data::Buffer::Shared::I64->new_anon(2);
# ctl[0] = head (consumer reads here)
# ctl[1] = tail (producer writes here)

my $pid = fork();
if ($pid == 0) {
    # === PRODUCER ===
    for my $i (1..$total_items) {
        # spin until there's space (tail - head < ring_size)
        while ($ctl->get(1) - $ctl->get(0) >= $ring_size) {}

        my $pos = $ctl->get(1) & $mask;
        $ring->set($pos, $i * 0.001);
        $ctl->incr(1);  # atomic publish
    }
    _exit(0);
}

# === CONSUMER ===
my $consumed = 0;
my $sum = 0.0;
my $t0 = time();

while ($consumed < $total_items) {
    my $head = $ctl->get(0);
    my $tail = $ctl->get(1);
    next if $head >= $tail;  # nothing to read

    # batch consume all available
    while ($head < $tail) {
        my $pos = $head & $mask;
        $sum += $ring->get($pos);
        $head++;
        $consumed++;
    }
    $ctl->set(0, $head);  # atomic advance head
}
waitpid($pid, 0);
my $elapsed = time() - $t0;

printf "SPSC ring buffer: %d slots, %d items\n", $ring_size, $total_items;
printf "throughput: %.0f items/sec (%.3fs)\n", $total_items / $elapsed, $elapsed;
printf "sum: %.2f (expected %.2f)\n", $sum,
    0.001 * $total_items * ($total_items + 1) / 2;
