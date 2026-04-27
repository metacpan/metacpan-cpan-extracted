use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

use Data::Stack::Shared;

my $N = 4;
my $M = 1000;

my $s = Data::Stack::Shared::Int->new(undef, 4096);

my @pids;
for my $k (0 .. $N - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for my $i (1 .. $M) {
            $s->push($k * $M + $i);
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
while (defined(my $v = $s->pop)) {
    $got_sum += $v;
    $got_count++;
}

is $got_count, $N * $M, "popped all $N * $M items";
is $got_sum, $expected_sum, "sum matches expected (no lost/duplicated)";

done_testing;
