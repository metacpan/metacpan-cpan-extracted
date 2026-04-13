#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use POSIX qw(_exit);
use Data::Heap::Shared;

my $WORKERS = shift || 4;
my $OPS     = shift || 100_000;

printf "Heap multi-process: %d workers x %d push+pop\n\n", $WORKERS, $OPS;

my $h = Data::Heap::Shared->new(undef, 64);

my $t0 = time;
my @pids;
for (1..$WORKERS) {
    my $pid = fork // die;
    if ($pid == 0) {
        for (1..$OPS) {
            $h->push($_, $$);
            $h->pop;
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;
my $dt = time - $t0;
printf "  %-35s %10.0f/s  (%.3fs)\n", "push+pop (cap=64)", $WORKERS * $OPS / $dt, $dt;
