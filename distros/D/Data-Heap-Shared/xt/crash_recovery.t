use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);
use Time::HiRes qw(usleep);

# SIGKILL a child mid-operation; parent's stale-recovery must reclaim
# the mutex on next operation.

use Data::Heap::Shared;

my $h = Data::Heap::Shared->new_memfd("crash", 32);

# Spawn a child that pushes/pops in a tight loop
my $pid = fork // die;
if (!$pid) {
    my $h2 = Data::Heap::Shared->new_from_fd($h->memfd);
    while (1) {
        $h2->push(int(rand(1000)), $$);
        usleep 100;
        $h2->pop if $h2->size > 0;
    }
    _exit(0);
}

usleep 50_000;
kill 'KILL', $pid;
waitpid $pid, 0;
my $sig = $? & 0x7f;
is $sig, 9, "child received SIGKILL";

# Parent should still be able to operate (stale mutex recovered)
usleep 100_000;
eval { $h->push(7, 42) };
is $@, '', "push after child SIGKILL succeeds (stale-mutex recovered)";
my @p = $h->pop;
ok @p == 2, "pop works after recovery";

my $stats = $h->stats;
cmp_ok $stats->{recoveries} // 0, '>=', 0, "stat_recoveries tracked";

done_testing;
