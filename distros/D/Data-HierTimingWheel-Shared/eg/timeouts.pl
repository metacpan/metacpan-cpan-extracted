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
use Data::HierTimingWheel::Shared;

# Timers spanning a huge range of delays -- from "next tick" to "millions of
# ticks away" -- all scheduled and cancelled in O(1).  Where a single-level wheel
# would revisit a far-future timer once per rotation, the hierarchical wheel
# parks it in a coarse level and only touches it as its time approaches.

# 4 levels of 100 slots -> schedules any delay up to 100**4 - 1 = 99,999,999 ticks
my $tw = Data::HierTimingWheel::Shared->new(undef, 100, 4, 100_000);
printf "wheel: %d slots x %d levels, max delay %d ticks\n\n",
    $tw->num_slots, $tw->num_levels, $tw->max_delay;

# schedule a spread of timeouts at wildly different horizons (payload == delay)
my %label = (
    1         => 'immediate',
    50        => 'half a second (@100Hz)',
    3_000     => '30 seconds',
    180_000   => '30 minutes',
    5_400_000 => '15 hours',
);
$tw->add($_, $_) for keys %label;
my @wanted = sort { $a <=> $b } keys %label;
printf "scheduled %d timers from %d to %d ticks out\n\n", $tw->count, $wanted[0], $wanted[-1];

# advance the clock and report as each fires (jump in chunks to the next expiry)
my $now = 0;
for my $target (@wanted) {
    my @fired = $tw->advance($target - $now);   # advancing millions of ticks is O(ticks + fired)
    $now = $target;
    printf "tick %8d: fired %s\n", $now, join(", ", map { "$label{$_} (delay $_)" } @fired);
}
printf "\nall done; %d timers still pending\n", $tw->count;
