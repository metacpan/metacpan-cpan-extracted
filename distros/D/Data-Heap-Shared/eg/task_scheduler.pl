#!/usr/bin/env perl
# Task scheduler: workers pop highest-priority tasks (lowest number = highest priority)
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time);
use Data::Heap::Shared;
$| = 1;

my $nworkers = shift || 3;
my $ntasks   = shift || 30;

my $h = Data::Heap::Shared->new(undef, $ntasks + $nworkers);

# push tasks with random priorities
srand(42);
for my $i (1..$ntasks) {
    my $pri = int(rand(100));
    $h->push($pri, $i);
}
# sentinel tasks (highest priority number = lowest urgency)
$h->push(999, -1) for 1..$nworkers;

printf "scheduler: %d tasks, %d workers\n", $ntasks, $nworkers;

my $t0 = time;
my @pids;
for my $w (1..$nworkers) {
    my $pid = fork // die;
    if ($pid == 0) {
        my $done = 0;
        while (1) {
            my ($pri, $task) = $h->pop_wait(2.0);
            last unless defined $pri;
            last if $task == -1;
            $done++;
        }
        printf "  worker %d processed %d tasks\n", $w, $done;
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($_, 0) for @pids;
printf "done in %.3fs, heap size=%d\n", time - $t0, $h->size;
