use strict;
use warnings;
use Data::Fenwick::Shared;

# A Fenwick tree = running cumulative sums with cheap point updates.
# Example: per-day event counts over a 30-day window, with prefix/range queries.

my $days = 30;
my $fen  = Data::Fenwick::Shared->new(undef, $days);

# record some events on various days
my %events = (1 => 4, 3 => 2, 7 => 9, 7 => 9, 15 => 5, 22 => 8, 30 => 1);
$fen->update($_, $events{$_}) for keys %events;

printf "events through day %d: %d\n", $_, $fen->prefix($_) for (7, 15, 30);
printf "events in week 1 (days 1..7):  %d\n", $fen->range(1, 7);
printf "events in week 4 (days 22..30): %d\n", $fen->range(22, 30);
printf "total events: %d\n", $fen->total;

# weighted sampling: treat counts as weights, find the day a cumulative rank lands on
my $total = $fen->total;
for my $target (1, int($total/2), $total) {
    printf "cumulative rank %d falls on day %d\n", $target, $fen->find($target);
}
