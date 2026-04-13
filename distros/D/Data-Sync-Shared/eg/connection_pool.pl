#!/usr/bin/env perl
# Connection pool limiter with semaphore
#
# Simulates a pool of N database connections shared across workers.
# The semaphore ensures no more than N concurrent "connections".
use strict;
use warnings;
use POSIX qw(_exit);
use Time::HiRes qw(time usleep gettimeofday tv_interval);
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::Sync::Shared;

my $pool_size = 3;
my $nworkers  = 10;
my $queries   = 5;

my $sem = Data::Sync::Shared::Semaphore->new(undef, $pool_size);

my @pids;
my $t0 = time;

for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for my $q (1..$queries) {
            my $wait_start = [gettimeofday];
            $sem->acquire;  # get a connection slot
            my $waited = tv_interval($wait_start);
            printf "  worker %2d query %d: acquired (waited %.1fms, pool=%d/%d)\n",
                $w, $q, $waited * 1000, $pool_size - $sem->value, $pool_size;
            usleep(1000 + int(rand(2000)));  # simulate query
            $sem->release;  # return connection to pool
        }
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;

printf "\n%d workers x %d queries through %d-slot pool in %.3fs\n",
    $nworkers, $queries, $pool_size, time - $t0;
my $s = $sem->stats;
printf "total acquires: %d, waits: %d, final pool: %d/%d\n",
    $s->{acquires}, $s->{waits}, $sem->value, $pool_size;
