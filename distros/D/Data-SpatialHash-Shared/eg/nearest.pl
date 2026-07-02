#!/usr/bin/env perl
# Grid of points, k-nearest queries from several probe locations
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;

my $s = Data::SpatialHash::Shared->new(undef, 10_000, 0, 1.0);

# Build a 100x100 grid with integer ids
my $id = 0;
for my $gx (0 .. 99) {
    for my $gy (0 .. 99) {
        $s->insert($gx, $gy, $id++);
    }
}
printf "inserted %d grid points\n", $s->count;

# Query k nearest from several probe points
my @probes = ([10.3, 10.7], [50.5, 50.5], [99.1, 0.2], [33.0, 66.0]);
my $k = 5;
for my $p (@probes) {
    my ($px, $py) = @$p;
    my @nn = $s->query_knn($px, $py, $k);
    printf "probe (%.1f, %.1f) -> %d nearest: %s\n",
        $px, $py, scalar @nn, join(', ', @nn);
}
