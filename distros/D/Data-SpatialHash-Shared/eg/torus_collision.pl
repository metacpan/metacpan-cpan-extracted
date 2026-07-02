#!/usr/bin/env perl
# Toroidal collision broad-phase: actors with per-entry radii on a SEAMLESS
# torus. Each tick: bulk-reposition everyone (wrapping), then each_colliding_pair
# emits every overlapping pair (seam-aware, heterogeneous radii) in one C call --
# the broad + narrow phase a game tick needs, with a small cell that stays
# correct even for the few large actors.
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;

my $W = 200;                          # 200x200 seamless torus
my $N = 400;
my $s = Data::SpatialHash::Shared->new(undef, $N, 0, 20, wrap => [$W, $W]);  # cell divides the world

my (%hnd, %pos, %vel);
for my $id (1 .. $N) {                # mostly small actors, a few big ones
    my $r = rand() < 0.7 ? 2 : rand() < 0.8 ? 3 : 15;
    my @p = (rand()*$W, rand()*$W);
    $hnd{$id} = $s->insert(@p, $id);
    $s->set_radius($hnd{$id}, $r);
    $pos{$id} = [@p];
    $vel{$id} = [ (rand()*2-1)*3, (rand()*2-1)*3 ];
}

sub wrap { my $v = shift; $v -= $W while $v >= $W; $v += $W while $v < 0; $v }

for my $tick (1 .. 5) {
    my @rows;
    for my $id (1 .. $N) {            # advance + wrap, then bulk-move in one call
        my $p = $pos{$id};
        $p->[0] = wrap($p->[0] + $vel{$id}[0]);
        $p->[1] = wrap($p->[1] + $vel{$id}[1]);
        push @rows, [ $hnd{$id}, @$p ];
    }
    $s->move_many(\@rows);

    my $pairs = 0;
    $s->each_colliding_pair(sub { $pairs++ });
    printf "tick %d: %d actors, %d colliding pairs (seam-aware)\n", $tick, $s->count, $pairs;
}
