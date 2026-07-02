#!/usr/bin/env perl
# Spherical world (planet): place surface + air entities by lat/lon/alt, run
# proximity queries in real 3D, and bucket entities into cube-sphere chunks for
# level-of-detail streaming.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;

my $R    = 6_371_000;   # body radius (m), Earth-ish
my $cell = 50_000;      # 50 km Cartesian cell ~ query scale
my $s = Data::SpatialHash::Shared->new(undef, 100_000, 0, $cell, sphere => $R);

# scatter entities over a region: most on the surface, ~10% airborne
srand(42);
my %chunk;              # cube-sphere chunk id (level 6) -> entity count
for my $id (1 .. 20_000) {
    my $lat = 0.5 + rand() * 0.3;                       # mid latitudes (radians)
    my $lon = 0.2 + rand() * 0.3;
    my $alt = (rand() < 0.1) ? rand() * 10_000 : 0;     # 10% in the air
    $s->insert_geo($lat, $lon, $alt, $id);
    $chunk{ $s->cube_cell_geo($lat, $lon, 6) }++;
}
printf "placed %d entities across %d level-6 chunks\n", $s->count, scalar keys %chunk;

# proximity: everything within 30 km of a point of interest (true 3D distance)
my ($qlat, $qlon, $qalt) = (0.65, 0.35, 0);
my @near = $s->query_geo_radius($qlat, $qlon, $qalt, 30_000);
printf "within 30 km of (%.2f, %.2f rad): %d entities\n", $qlat, $qlon, scalar @near;

# LOD streaming: load the chunk under the camera plus its ring of neighbors
my $here   = $s->cube_cell_geo($qlat, $qlon, 6);
my @ring   = $s->cube_neighbors($here);
my $loaded = $chunk{$here} || 0;
$loaded += ($chunk{$_} || 0) for @ring;
printf "camera chunk + %d neighbors hold %d entities to stream\n", scalar(@ring), $loaded;

# zoom out one level of detail: the parent chunk
printf "parent (level 5) chunk of the camera cell: %d\n", $s->cube_parent($here);
