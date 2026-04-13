#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use POSIX qw(_exit);
use Data::Deque::Shared;

my $WORKERS = shift || 8;
my $OPS     = shift || 200_000;

printf "Deque multi-process: %d workers x %d ops\n\n", $WORKERS, $OPS;

for my $cap (16, 64, 256) {
    my $dq = Data::Deque::Shared::Int->new(undef, $cap);
    my $t0 = time;
    my @pids;
    for (1..$WORKERS) {
        my $pid = fork // die;
        if ($pid == 0) {
            for (1..$OPS) {
                $dq->push_back_wait($$, 1.0);
                $dq->pop_front_wait(1.0);
            }
            _exit(0);
        }
        push @pids, $pid;
    }
    waitpid($_, 0) for @pids;
    my $dt = time - $t0;
    my $s = $dq->stats;
    printf "  cap=%-6d %10.0f ops/s  (%.3fs)  waits=%d\n",
        $cap, $WORKERS * $OPS / $dt, $dt, $s->{waits};
}
