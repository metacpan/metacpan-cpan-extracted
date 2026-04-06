#!/usr/bin/env perl
# Bounded semaphore via CAS for cross-process resource limiting
#
# cmpxchg-based acquire/release: no locks, no syscalls on fast path.
# Use case: connection pool, GPU work queue, fork throttle.
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time sleep usleep);

use Data::Buffer::Shared::I64;

my $max_permits = 3;
my $nworkers = 8;
my $work_per = 20;

my $sem = Data::Buffer::Shared::I64->new_anon(2);
# slot 0: available permits
# slot 1: total acquired count (for verification)
$sem->set(0, $max_permits);

sub acquire {
    my ($sem) = @_;
    while (1) {
        my $cur = $sem->get(0);
        next if $cur <= 0;
        # cmpxchg returns old value; if it matches cur, swap succeeded
        my $old = $sem->cmpxchg(0, $cur, $cur - 1);
        return if $old == $cur;  # success
        # otherwise old != cur, retry with fresh value
    }
}

sub release {
    my ($sem) = @_;
    $sem->incr(0);
}

my @pids;
my $t0 = time();
for my $w (1..$nworkers) {
    my $pid = fork();
    if ($pid == 0) {
        for (1..$work_per) {
            acquire($sem);
            $sem->incr(1);  # track total acquisitions
            # simulate work holding the resource
            usleep(100);    # 0.1ms
            release($sem);
        }
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;
my $elapsed = time() - $t0;

printf "semaphore: %d permits, %d workers, %d ops each\n",
    $max_permits, $nworkers, $work_per;
printf "total acquisitions: %d (expected %d)\n",
    $sem->get(1), $nworkers * $work_per;
printf "final permits: %d (expected %d)\n", $sem->get(0), $max_permits;
printf "elapsed: %.3fs\n", $elapsed;
