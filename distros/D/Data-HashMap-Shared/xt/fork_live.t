use strict;
use warnings;
use Test::More;
use POSIX qw(_exit);

use Data::HashMap::Shared::II;

# Parent creates file-backed map, forks N children; each child sets
# its own disjoint key range. Parent verifies all keys are present
# with the correct values.

my $N = 4;
my $M = 500;

use File::Temp qw(tmpnam);
my $path = tmpnam() . ".$$";
my $m = Data::HashMap::Shared::II->new($path, $N * $M * 2);

my @pids;
for my $k (0 .. $N - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $child = Data::HashMap::Shared::II->new($path, $N * $M * 2);
        for my $i (0 .. $M - 1) {
            my $key = $k * $M + $i;
            $child->put($key, $key * 7 + 1);
        }
        _exit(0);
    }
    push @pids, $pid;
}

waitpid $_, 0 for @pids;

my $hits = 0;
my $misses = 0;
my $wrong = 0;
for my $k (0 .. $N - 1) {
    for my $i (0 .. $M - 1) {
        my $key = $k * $M + $i;
        my $v = $m->get($key);
        if (!defined $v) { $misses++ }
        elsif ($v != $key * 7 + 1) { $wrong++ }
        else { $hits++ }
    }
}

unlink $path;

is $hits, $N * $M, "all $N * $M keys present with correct values";
is $misses, 0, "no missing keys";
is $wrong, 0, "no wrong values";

done_testing;
