use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use POSIX qw(_exit);

# Concurrent stats() reads during heavy alloc/free ops. Must not crash
# and values must be monotonically non-decreasing (stat counters).

use Data::Pool::Shared;

my $p = Data::Pool::Shared::I64->new_memfd("stats", 128);
my $DURATION = 1.0;

my @pids;

# 2 writers
for (1..2) {
    my $pid = fork // die;
    if (!$pid) {
        my $p2 = Data::Pool::Shared::I64->new_from_fd($p->memfd);
        my $end = time + $DURATION;
        while (time < $end) {
            my $s = $p2->alloc;
            $p2->set($s, $$);
            $p2->free($s);
        }
        _exit(0);
    }
    push @pids, $pid;
}

# Parent: hammer stats() and verify monotonicity
my $end = time + $DURATION;
my $prev_stats = { allocs => 0, frees => 0 };
my $reads = 0;
my $regress = 0;
while (time < $end) {
    my $s = $p->stats;
    $reads++;
    for my $k (qw(allocs frees)) {
        my $cur  = $s->{$k} // 0;
        my $prev = $prev_stats->{$k};
        $regress++ if $cur < $prev;
        $prev_stats->{$k} = $cur;
    }
}
diag "stats reads=$reads regressions=$regress final=" . join(',', map "$_=$prev_stats->{$_}", sort keys %$prev_stats);

waitpid $_, 0 for @pids;

cmp_ok $reads, '>', 100, "read stats repeatedly under load (reads=$reads)";
is $regress, 0, "stat counters monotonic non-decreasing under concurrent ops";

done_testing;
