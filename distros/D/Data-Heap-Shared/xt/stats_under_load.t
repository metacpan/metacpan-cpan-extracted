use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use POSIX qw(_exit);

use Data::Heap::Shared;

my $h = Data::Heap::Shared->new_memfd("stats", 128);
my $DUR = 1.0;

my @pids;
for (1..2) {
    my $pid = fork // die;
    if (!$pid) {
        my $h2 = Data::Heap::Shared->new_from_fd($h->memfd);
        my $end = time + $DUR;
        while (time < $end) {
            $h2->push(int(rand(1000)), $$);
            $h2->pop if $h2->size > 0;
        }
        _exit(0);
    }
    push @pids, $pid;
}

my $prev = { pushes => 0, pops => 0 };
my $regress = 0;
my $reads = 0;
my $end = time + $DUR;
while (time < $end) {
    my $s = $h->stats;
    $reads++;
    for my $k (qw(pushes pops)) {
        $regress++ if ($s->{$k} // 0) < $prev->{$k};
        $prev->{$k} = $s->{$k} // 0;
    }
}

waitpid $_, 0 for @pids;
diag "reads=$reads regressions=$regress";
cmp_ok $reads, '>', 10, "stats read repeatedly";
is $regress, 0, "stat counters monotonic";

done_testing;
