#!/usr/bin/env perl
use strict;
use warnings;
use FindBin;
# Prefer a freshly built blib/ (picks up both lib and the compiled .so),
# fall back to lib/ or the installed module.
BEGIN {
    my $blib = "$FindBin::Bin/../blib";
    if (-d "$blib/arch") { require blib; blib->import($blib) }
    else { unshift @INC, "$FindBin::Bin/../lib" }
}
use Data::TimingWheel::Shared;

# Connection idle-timeouts, the classic timing-wheel use case.  Each connection
# arms a timeout; activity re-arms it (cancel + re-add); the event loop advances
# the wheel one tick per time unit and closes whatever timed out -- all O(1) per
# connection regardless of how many are open.

my $tw = Data::TimingWheel::Shared->new(undef, 256, 100_000);

my %timer_of;    # conn id -> current timer id
my $TIMEOUT = 30;

sub arm {
    my $conn = shift;
    $tw->cancel($timer_of{$conn}) if defined $timer_of{$conn};
    $timer_of{$conn} = $tw->add($TIMEOUT, $conn);
}

# open 1000 connections at tick 0
arm($_) for 1 .. 1000;
printf "armed %d connections with a %d-tick idle timeout\n", $tw->count, $TIMEOUT;

# simulate 60 ticks; some connections stay active (re-arm), most go idle
my $seed = 1;
sub rnd { $seed = ($seed * 1103515245 + 12345) & 0x7fffffff; $seed / 0x7fffffff }

my $closed = 0;
for my $tick (1 .. 60) {
    # ~5% of still-open connections see activity this tick and re-arm
    for my $conn (1 .. 1000) {
        next unless defined $timer_of{$conn};
        arm($conn) if rnd() < 0.05;
    }
    my @timed_out = $tw->advance(1);
    for my $conn (@timed_out) {
        delete $timer_of{$conn};
        $closed++;
    }
    printf "tick %2d: %d timed out (%d still open)\n", $tick, scalar @timed_out, $tw->count
        if @timed_out;
}

printf "\n%d connections closed on idle timeout, %d still open after 60 ticks\n",
    $closed, $tw->count;
