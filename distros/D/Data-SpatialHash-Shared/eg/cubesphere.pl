#!/usr/bin/env perl
# Cube-sphere cells: map a lat/lon (or direction) to a hierarchical cell id,
# walk the 4-neighbourhood across face seams, and zoom between levels of detail.
# These methods are stateless geometry -- any handle provides them.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;

my $s = Data::SpatialHash::Shared->new(undef, 1, 0, 1.0);

# a point on the sphere (lat/lon in radians) -> cell id at level 5
my ($lat, $lon) = (0.6, 1.2);
my $cell = $s->cube_cell_geo($lat, $lon, 5);
printf "lat=%.2f lon=%.2f  ->  level-%d cell %d\n", $lat, $lon, $s->cube_level($cell), $cell;

# the cell's centre, back as lat/lon
my ($clat, $clon) = $s->cube_center_geo($cell);
printf "cell centre: lat=%.4f lon=%.4f\n", $clat, $clon;

# 4 edge-adjacent neighbours, correct across cube-face seams
printf "neighbours: %s\n", join(", ", $s->cube_neighbors($cell));

# level of detail: zoom out to the parent, then list the parent's 4 children
my $parent = $s->cube_parent($cell);
my @kids   = $s->cube_children($parent);
printf "parent (level %d) %d -> children %s\n", $s->cube_level($parent), $parent, join(", ", @kids);
printf "...the original cell is among them: %s\n", (grep { $_ == $cell } @kids) ? "yes" : "no";

# how many cells tile the whole sphere at each level
printf "cells per level: %s\n", join("  ", map { "L$_=" . (6 * 4 ** $_) } 0 .. 5);
