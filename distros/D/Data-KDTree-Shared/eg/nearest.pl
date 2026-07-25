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
use Data::KDTree::Shared;

# A 2-D spatial index of "stations": nearest, k-nearest, bounding-box, and
# radius queries over a random point cloud, each in O(log n) rather than a
# full O(n) scan.

my $N = 50_000;
my $kd = Data::KDTree::Shared->new(undef, 2, $N);

my $seed = 20260710;
sub rnd { $seed = ($seed * 1103515245 + 12345) & 0x7fffffff; $seed / 0x7fffffff }

# scatter stations across a 1000 x 1000 area, id == station number
$kd->add([rnd() * 1000, rnd() * 1000], $_) for 0 .. $N - 1;
printf "indexed %d stations in a 1000x1000 area\n\n", $kd->count;

my @q = (500, 500);

# single nearest
my $near = $kd->nearest(\@q);
printf "nearest station to (%.0f, %.0f): #%d at distance %.2f\n\n", @q, $near->{id}, $near->{dist};

# 5 nearest
printf "5 nearest to (%.0f, %.0f):\n", @q;
printf "  #%-6d  dist %.2f\n", $_->{id}, $_->{dist} for $kd->knn(\@q, 5);

# how many stations in a central 100x100 box?
my @box = $kd->range([450, 450], [550, 550]);
printf "\nstations inside the central 100x100 box: %d\n", scalar @box;

# how many within radius 25 of the query point?
my @ball = $kd->radius(\@q, 25);
printf "stations within distance 25 of (%.0f, %.0f): %d\n", @q, scalar @ball;
printf "  closest three: %s\n", join(", ", map { sprintf('#%d(%.1f)', $_->{id}, $_->{dist}) } @ball[0 .. 2]);
