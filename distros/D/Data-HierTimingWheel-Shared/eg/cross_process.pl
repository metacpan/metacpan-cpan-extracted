#!/usr/bin/env perl
# Cross-process: parent builds a hierarchical timing wheel via memfd, children
# each schedule their own timers (at widely varying horizons) into the one shared
# wheel, and the parent owns advancing the clock and dispatching whatever fires
# -- the producer/consumer split a shared timer service naturally allows.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::HierTimingWheel::Shared;
$| = 1;

my $kids = 4;
my $per  = 2000;
my $cap  = $kids * $per + 16;

# 256 slots x 4 levels -> delays up to 256**4 - 1 (~4.3 billion ticks)
my $tw = Data::HierTimingWheel::Shared->new_memfd('hiertimingwheel-demo', 256, 4, $cap);
my $fd = $tw->memfd;
printf "parent: created wheel (%d slots x %d levels, capacity %d) via memfd fd=%d\n",
    $tw->num_slots, $tw->num_levels, $tw->capacity, $fd;

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $child = Data::HierTimingWheel::Shared->new_from_fd($fd);
        my $seed = 1 + $c;
        for my $i (1 .. $per) {
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff;
            my $delay = 1 + $seed % 5000;                       # 1..5000 ticks (spans 2 levels)
            $child->add($delay, $c * $per + $i);                # globally unique payload
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

printf "parent: %d timers scheduled by %d children\n\n", $tw->count, $kids;

# advance the clock past every delay and count how many fire
my $total_fired = 0;
$total_fired += scalar $tw->advance(1) for 1 .. 5000;
printf "after 5000 ticks: %d timers fired, %d still pending\n", $total_fired, $tw->count;
printf "(every delay was in 1..5000, so all should have fired -- through 2 levels of cascades)\n";
