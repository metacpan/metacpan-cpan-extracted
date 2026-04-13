#!/usr/bin/env perl
# Simulated connection pool: N workers share M connection slots
# Each worker checks out a connection (alloc), does "work", checks it back in (free)

use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::Pool::Shared;
$| = 1;

my $nworkers = shift || 8;
my $nconns   = shift || 3;
my $ops      = shift || 20;

my $pool = Data::Pool::Shared::Str->new(undef, $nconns, 64);
printf "connection pool: %d slots, %d workers, %d ops each\n",
    $nconns, $nworkers, $ops;

my @pids;
for my $w (1..$nworkers) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        for my $i (1..$ops) {
            my $slot = $pool->alloc(5.0);
            unless (defined $slot) {
                warn "worker $w: alloc timeout on op $i\n";
                next;
            }
            $pool->set($slot, sprintf "worker=%d op=%d pid=%d", $w, $i, $$);
            # simulate work
            select(undef, undef, undef, 0.001 + rand(0.005));
            $pool->free($slot);
        }
        _exit(0);
    }
    push @pids, $pid;
}

waitpid($_, 0) for @pids;

my $s = $pool->stats;
printf "done: allocs=%d frees=%d waits=%d timeouts=%d\n",
    $s->{allocs}, $s->{frees}, $s->{waits}, $s->{timeouts};
printf "pool state: used=%d available=%d\n", $pool->used, $pool->available;
