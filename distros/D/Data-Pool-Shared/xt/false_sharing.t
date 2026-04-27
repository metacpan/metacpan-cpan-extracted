use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use POSIX qw(_exit);

# False-sharing detector: measure producer+consumer throughput with
# heavy concurrent ops. A dramatic drop (<10% expected) suggests two
# hot fields share a cache line. Report, don't assert strictly — pure
# hardware measurement that varies by system.

use Data::Pool::Shared;

my $p = Data::Pool::Shared::I64->new_memfd("fs", 256);
my $DURATION = 1.0;

# Producer + consumer in parallel, both hit hot fields (bitmap, used).
my $producer = fork // die;
if (!$producer) {
    my $p2 = Data::Pool::Shared::I64->new_from_fd($p->memfd);
    my $end = time + $DURATION;
    my $ops = 0;
    while (time < $end) {
        my $s = $p2->alloc;
        $p2->set($s, 1);
        $ops++;
    }
    _exit(0);
}

my $consumer = fork // die;
if (!$consumer) {
    my $p2 = Data::Pool::Shared::I64->new_from_fd($p->memfd);
    my $end = time + $DURATION;
    my $ops = 0;
    while (time < $end) {
        for my $s (0..255) {
            $p2->free($s) if $p2->is_allocated($s);
        }
        $ops++;
    }
    _exit(0);
}

waitpid $producer, 0;
waitpid $consumer, 0;

my $st = $p->stats;
my $allocs = $st->{allocs} // 0;
my $frees  = $st->{frees}  // 0;

diag sprintf "under contention: allocs=%d frees=%d (%.0f ops/s total)",
    $allocs, $frees, ($allocs + $frees) / $DURATION;

cmp_ok $allocs + $frees, '>', 1000,
    "combined throughput under producer/consumer contention > 1k ops/s";

# No strict false-sharing assertion — hardware-dependent. The test
# provides a diagnostic for future tuning if the cache line layout
# is ever restructured.

done_testing;
