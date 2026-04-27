use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

use Data::Deque::Shared;

# Parent creates deque, forks N children; each child pushes M items,
# then parent pops all N*M and verifies the sum matches.
# Exercises MPMC with real process-level concurrency.

my $N = 4;
my $M = 1000;

my $d = Data::Deque::Shared::Int->new(undef, 4096);

my @pids;
for my $k (0 .. $N - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for my $i (1 .. $M) {
            $d->push_back($k * $M + $i);
        }
        _exit(0);
    }
    push @pids, $pid;
}

waitpid $_, 0 for @pids;

my $expected_sum = 0;
$expected_sum += $_ for 1 .. $N * $M;

my $got_sum = 0;
my $got_count = 0;
while (defined(my $v = $d->pop_front)) {
    $got_sum += $v;
    $got_count++;
}

is $got_count, $N * $M, "popped all $N * $M items";
is $got_sum, $expected_sum, "sum matches expected (no lost/duplicated)";

done_testing;
