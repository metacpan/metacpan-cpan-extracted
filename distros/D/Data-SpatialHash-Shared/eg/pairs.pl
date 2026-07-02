#!/usr/bin/env perl
# Proximity pairs: each_pair_within finds every pair of points closer than a
# threshold in one grid walk -- a spatial self-join (near-duplicate detection,
# clustering, contact finding) without a per-point query + dedup.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;

my $N         = 2000;
my $threshold = 3;
my $s = Data::SpatialHash::Shared->new(undef, $N, 0, $threshold);   # cell ~ threshold
my %pos;
for my $id (1 .. $N) {
    my @p = (rand() * 100, rand() * 100);
    $s->insert(@p, $id);
    $pos{$id} = \@p;
}

# every unordered pair within $threshold, emitted exactly once
my ($pairs, $closest, $cd) = (0, '-', 1e9);
$s->each_pair_within($threshold, sub {
    my ($a, $b) = @_;
    $pairs++;
    my ($pa, $pb) = ($pos{$a}, $pos{$b});
    my $d = sqrt(($pa->[0] - $pb->[0])**2 + ($pa->[1] - $pb->[1])**2);
    ($cd, $closest) = ($d, "$a-$b") if $d < $cd;
});
printf "%d points; %d pairs within %g; closest = %s at %.3f\n",
    $N, $pairs, $threshold, $closest, $cd;
