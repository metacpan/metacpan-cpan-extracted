#!/usr/bin/env perl
# Broad-phase collision detection: for each entity, find neighbour candidates
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;

my $N      = 200;
my $radius = 2.0;
my $world  = 100.0;

my $s = Data::SpatialHash::Shared->new(undef, $N, 0, $radius);

# Insert N random entities; store positions for later
my (@px, @py);
for my $i (0 .. $N - 1) {
    $px[$i] = rand() * $world;
    $py[$i] = rand() * $world;
    $s->insert($px[$i], $py[$i], $i);
}
printf "inserted %d entities (radius=%.1f)\n", $s->count, $radius;

# Broad-phase: query 2*radius box per entity
my $total_pairs = 0;
for my $i (0 .. $N - 1) {
    my @candidates = $s->query_radius($px[$i], $py[$i], $radius * 2);
    # Exclude self
    my @others = grep { $_ != $i } @candidates;
    $total_pairs += @others;
}
printf "total broad-phase candidate pairs: %d\n", $total_pairs;
printf "average candidates per entity: %.1f\n", $total_pairs / $N;
