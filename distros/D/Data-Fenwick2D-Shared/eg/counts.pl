use strict;
use warnings;
use Data::Fenwick2D::Shared;

# A 2-D Fenwick tree = a grid of running cumulative sums with cheap point updates
# and O(log rows * log cols) rectangle-sum queries.
#
# Example: a 24 x 7 heatmap of events by (hour-of-day, day-of-week).  We tally
# events into cells, then ask for the sum over any rectangle -- e.g. "morning
# events on weekdays" -- without scanning the grid.

my ($hours, $days) = (24, 7);        # rows = hour 1..24, cols = day 1..7 (Mon..Sun)
my $grid = Data::Fenwick2D::Shared->new(undef, $hours, $days);

# tally some events: (hour, day) => count
my @events = (
    [9,  1, 12], [10, 1, 20], [ 9, 2, 15], [14, 3, 8],
    [22, 5, 30], [23, 5, 25], [10, 6, 5],  [11, 7, 40],
);
$grid->update(@$_) for @events;

printf "total events: %d\n", $grid->total;

# rectangle sums via inclusion-exclusion, all O(log h * log d)
printf "morning (hours 8..12) on weekdays (days 1..5): %d\n",
    $grid->rect(8, 1, 12, 5);
printf "late night (hours 22..24), any day:            %d\n",
    $grid->rect(22, 1, 24, 7);
printf "events at exactly (hour 22, day 5):            %d\n",
    $grid->point(22, 5);

# a prefix is the rectangle from the origin
printf "everything up to (hour 12, day 5):             %d\n",
    $grid->prefix(12, 5);

# share the same grid across processes via a backing file or a memfd:
#   my $shared = Data::Fenwick2D::Shared->new("/tmp/heatmap.f2d", 24, 7);
