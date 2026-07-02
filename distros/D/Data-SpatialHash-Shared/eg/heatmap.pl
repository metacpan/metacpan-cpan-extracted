#!/usr/bin/env perl
use strict; use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;

# Density heatmap: bin points into cells and render per-cell occupancy with
# query_cell -- a quick way to visualise spatial distribution.

my ($CS, $W) = (10, 100);
my $s = Data::SpatialHash::Shared->new(undef, 5000, 0, $CS);
for (1 .. 2000) {                                  # two gaussian-ish clusters
    my @c = rand() < 0.5 ? (30, 30) : (70, 60);
    $s->insert($c[0] + (rand()-0.5)*40, $c[1] + (rand()-0.5)*40, $_);
}

my @sym = (' ', '.', ':', 'o', 'O', '#');
for (my $gy = $W - $CS; $gy >= 0; $gy -= $CS) {
    for (my $gx = 0; $gx < $W; $gx += $CS) {
        my @in  = $s->query_cell($gx + 0.5, $gy + 0.5);
        my $n   = scalar @in;
        my $lvl = $n == 0 ? 0
                : $n < 5   ? 1
                : $n < 15  ? 2
                : $n < 30  ? 3
                : $n < 60  ? 4 : 5;
        print $sym[$lvl];
    }
    print "\n";
}
printf "%d points across the grid\n", $s->count;
