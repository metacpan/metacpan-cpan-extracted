#!/usr/bin/env perl
# Work-stealing pattern: producer pushes jobs, workers pop them (LIFO = cache-hot)
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Stack::Shared;
$| = 1;

my $njobs    = shift || 100;
my $nworkers = shift || 4;

my $stk = Data::Stack::Shared::Int->new(undef, $njobs + $nworkers);

# push poison pills first (bottom of stack), then jobs on top
$stk->push(-1) for 1..$nworkers;
$stk->push($_) for 1..$njobs;

printf "producer pushed %d jobs + %d poison pills\n", $njobs, $nworkers;

my $t0 = time;
my @pids;
for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $done = 0;
        while (1) {
            my $job = $stk->pop_wait(2.0);
            last unless defined $job;
            last if $job == -1;
            $done++;
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;
my $dt = time - $t0;

printf "done in %.3fs (%.0f jobs/s), stack size=%d\n", $dt, $njobs / $dt, $stk->size;
