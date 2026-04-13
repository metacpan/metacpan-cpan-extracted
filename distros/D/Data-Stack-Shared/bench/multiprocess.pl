#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use POSIX qw(_exit);
use Data::Stack::Shared;

my $WORKERS = shift || 8;
my $OPS     = shift || 200_000;

printf "Stack multi-process: %d workers x %d push+pop ops\n\n", $WORKERS, $OPS;

my $stk = Data::Stack::Shared::Int->new(undef, 64);

my $t0 = time;
my @pids;
for (1..$WORKERS) {
    my $pid = fork // die;
    if ($pid == 0) {
        for (1..$OPS) {
            $stk->push_wait($$, 1.0);
            $stk->pop_wait(1.0);
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;
my $dt = time - $t0;

my $total = $WORKERS * $OPS;
my $s = $stk->stats;
printf "  %-35s %10.0f/s  (%.3fs)  waits=%d\n",
    "push+pop (cap=64)", $total / $dt, $dt, $s->{waits};
