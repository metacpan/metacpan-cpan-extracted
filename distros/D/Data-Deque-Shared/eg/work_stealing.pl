#!/usr/bin/env perl
# Work-stealing: owner push_back/pop_back (LIFO, cache-hot),
# thieves pop_front (steal from the other end)
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Time::HiRes qw(time sleep);
use Data::Deque::Shared;
$| = 1;

my $nthieves = shift || 3;
my $dq = Data::Deque::Shared::Int->new(undef, 256);

# owner: produces work, processes own work (LIFO), lets thieves steal
my $owner_pid = fork // die;
if ($owner_pid == 0) {
    for my $batch (1..10) {
        # produce a batch of work items
        for my $i (1..20) {
            $dq->push_back($batch * 100 + $i);
        }
        # process own work (LIFO — most recent = cache hot)
        my $own = 0;
        while (defined(my $v = $dq->pop_back)) {
            $own++;
            last if $dq->size < 5;  # leave some for thieves
        }
    }
    sleep 0.2;  # let thieves drain
    _exit(0);
}

# thieves: steal from front (oldest items)
my @pids;
for my $t (1..$nthieves) {
    my $pid = fork // die;
    if ($pid == 0) {
        my $stolen = 0;
        while (1) {
            my $v = $dq->pop_front_wait(0.3);
            last unless defined $v;
            $stolen++;
        }
        printf "thief %d stole %d items\n", $t, $stolen;
        _exit(0);
    }
    push @pids, $pid;
}
waitpid($owner_pid, 0);
waitpid($_, 0) for @pids;
printf "deque final size: %d\n", $dq->size;
