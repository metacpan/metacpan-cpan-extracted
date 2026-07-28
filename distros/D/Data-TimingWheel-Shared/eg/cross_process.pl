#!/usr/bin/env perl
# Cross-process: parent builds a timing wheel via memfd, children each schedule
# their own timers into the one shared wheel, and the parent owns advancing the
# clock and dispatching whatever fires -- the producer/consumer split a shared
# timer service naturally allows.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use POSIX qw(_exit);
use Data::TimingWheel::Shared;
$| = 1;

my $kids = 4;
my $per  = 2000;
my $cap  = $kids * $per + 16;

my $tw = Data::TimingWheel::Shared->new_memfd('timingwheel-demo', 512, $cap);
my $fd = $tw->memfd;
printf "parent: created wheel (512 slots, capacity %d) via memfd fd=%d\n", $tw->capacity, $fd;

my @pids;
for my $c (0 .. $kids - 1) {
    my $pid = fork // die "fork: $!";
    if ($pid == 0) {
        my $child = Data::TimingWheel::Shared->new_from_fd($fd);
        my $seed = 1 + $c;
        for my $i (1 .. $per) {
            $seed = ($seed * 1103515245 + 12345) & 0x7fffffff;
            my $delay = 1 + $seed % 100;                        # 1..100 ticks
            $child->add($delay, $c * $per + $i);                # globally unique payload
        }
        _exit(0);
    }
    push @pids, $pid;
}
waitpid $_, 0 for @pids;

printf "parent: %d timers scheduled by %d children\n\n", $tw->count, $kids;

# advance the clock and count how many fire over 100 ticks
my $total_fired = 0;
for my $tick (1 .. 100) {
    my @fired = $tw->advance(1);
    $total_fired += @fired;
}
printf "after 100 ticks: %d timers fired, %d still pending\n", $total_fired, $tw->count;
printf "(every scheduled timer had a delay in 1..100, so all should have fired)\n";
