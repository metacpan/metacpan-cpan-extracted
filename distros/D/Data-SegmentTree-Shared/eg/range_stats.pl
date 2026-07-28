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
use Data::SegmentTree::Shared;

# A booking calendar: 365 days, each cell is the number of reservations that day.
# range_add books a contiguous stay in O(log n); range min/max/sum answer
# "how busy is this week?" without scanning the days.

my $st = Data::SegmentTree::Shared->new(undef, 365);

# a few overlapping bookings, each covering a date range (0-based day of year)
my @bookings = ([10, 20], [15, 18], [17, 30], [100, 140], [120, 125], [359, 364]);
$st->range_add($_->[0], $_->[1], 1) for @bookings;

printf "%d bookings applied over a 365-day calendar\n\n", scalar @bookings;

# busiest single day overall, and total reserved-days
printf "peak occupancy any day : %d\n", $st->max(0, 364);
printf "total reserved day-slots: %d\n\n", $st->sum(0, 364);

# week-by-week view of one busy month
printf "days 10-30:\n";
for (my $d = 10; $d <= 30; $d += 7) {
    my $end = $d + 6; $end = 30 if $end > 30;
    my $q = $st->query($d, $end);
    printf "  days %3d-%-3d: min=%d max=%d busy-day-slots=%d\n",
        $d, $end, $q->{min}, $q->{max}, $q->{sum};
}

# is a proposed stay (days 16-19) free of triple-booking?
my $busiest = $st->max(16, 19);
printf "\nproposed stay days 16-19: peak existing occupancy %d -> %s\n",
    $busiest, $busiest >= 3 ? "crowded" : "ok";
