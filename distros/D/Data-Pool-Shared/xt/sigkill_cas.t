use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time usleep);
use POSIX qw(_exit);

# SIGKILL a worker in the middle of its CAS loop. PID-based stale slot
# recovery must reclaim its slot on the next recover_stale scan.

use Data::Pool::Shared;

my $p = Data::Pool::Shared::I64->new_memfd("sigkill", 32);

# Worker that loops allocating+holding slots for variable durations
my $pid = fork // die;
if (!$pid) {
    my $p2 = Data::Pool::Shared::I64->new_from_fd($p->memfd);
    while (1) {
        my $s = $p2->alloc;
        $p2->set($s, $$);
        usleep 1000;  # 1ms
        $p2->free($s);
    }
    _exit(99);
}

# Let the worker churn a moment, then SIGKILL while it's mid-op
usleep 50_000;
kill 'KILL', $pid;
waitpid $pid, 0;
my $sig = $? & 0x7f;
is $sig, 9, "worker received SIGKILL (signal=$sig)";

# At this point the worker may have held a slot; scan for stale
usleep 100_000;
my $used_before = $p->used;
my $recovered = $p->recover_stale;
my $used_after = $p->used;

diag "used_before=$used_before recovered=$recovered used_after=$used_after";

cmp_ok $used_after, '<=', $used_before,
    "recover_stale did not increase used count";

# If the worker was holding a slot at SIGKILL, recover_stale reclaimed it
if ($used_before > 0) {
    cmp_ok $recovered, '>=', 0, "recover_stale returned non-negative count";
    is $used_after, 0, "all slots recovered";
} else {
    pass "worker happened to be between ops at SIGKILL (no stale slot)";
}

done_testing;
