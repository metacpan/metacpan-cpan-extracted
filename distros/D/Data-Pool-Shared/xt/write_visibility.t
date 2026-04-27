use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time usleep);
use POSIX qw(_exit);

# Cross-process mmap write visibility latency. A write in one process
# must become visible to another within microseconds (hardware-dependent
# but always << 100ms). >100ms indicates a memory barrier is missing
# or the atomic-load path is broken.

use Data::Pool::Shared;

my $p = Data::Pool::Shared::I64->new_memfd("vis", 4);
my $s = $p->alloc;
$p->set($s, -1);

my $pid = fork // die;
if (!$pid) {
    my $p2 = Data::Pool::Shared::I64->new_from_fd($p->memfd);
    # Polling loop: wait for parent to write a non-negative value, then
    # write our own marker.
    my $deadline = time + 5;
    while (time < $deadline) {
        my $v = $p2->get($s);
        if (defined $v && $v >= 0) {
            $p2->set($s, $v + 1);
            _exit(0);
        }
        usleep 100;
    }
    _exit(1);
}

# Parent: write timestamp, poll for child's +1
my $t0 = time;
$p->set($s, 12345);

my $latency = -1;
my $deadline = time + 5;
while (time < $deadline) {
    my $v = $p->get($s);
    if ($v == 12346) {
        $latency = time - $t0;
        last;
    }
}

waitpid $pid, 0;

cmp_ok $latency, '>=', 0, "saw child's write-back";
cmp_ok $latency, '<', 0.1, "visible within 100ms (${\sprintf '%.3f', $latency*1000}ms)";
diag sprintf "roundtrip visibility: %.3fms", $latency * 1000;

done_testing;
