#!/usr/bin/env perl
# Bulk insert/move: populate with insert_many, then reposition every entry each
# tick with move_many -- one lock acquisition per batch instead of one per entry.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use Data::SpatialHash::Shared;

my $N = 50_000;
my $s = Data::SpatialHash::Shared->new(undef, $N, 0, 4);

# bulk insert: each row is [x, y, value]
my @rows = map { [ rand() * 1000, rand() * 1000, $_ ] } 1 .. $N;
my @h = $s->insert_many(\@rows);
printf "insert_many: %d handles, count=%d\n", scalar(@h), $s->count;

# bulk-reposition every entry each "tick"
for my $tick (1 .. 5) {
    my @moves = map { [ $h[$_], rand() * 1000, rand() * 1000 ] } 0 .. $#h;
    my $t = time;
    my $moved = $s->move_many(\@moves);
    printf "tick %d: move_many %d entries in %.2f ms\n", $tick, $moved, (time - $t) * 1000;
}
