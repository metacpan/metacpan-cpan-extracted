#!/usr/bin/env perl
use strict; use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Data::SpatialHash::Shared;

# Simulation tick loop: entities with velocities move each tick, and a
# broad-phase pass finds collision-candidate pairs via query_radius. This is
# the spatial hash's core use case -- many moving points, "what is near me".

my $N      = 500;
my $WORLD  = 200;
my $RADIUS = 3;     # collision radius; size cell_size ~ the query radius
my $s = Data::SpatialHash::Shared->new(undef, $N, 0, $RADIUS);

my (%h, %pos, @vel);   # id => handle / [x,y] / [vx,vy]
for my $id (1 .. $N) {
    my @p = (rand()*$WORLD, rand()*$WORLD);
    $h{$id}   = $s->insert(@p, $id);
    $pos{$id} = [@p];
    $vel[$id] = [ (rand()*2-1)*2, (rand()*2-1)*2 ];
}

for my $tick (1 .. 5) {
    for my $id (keys %h) {                       # advance + relocate, bouncing off walls
        my $p = $pos{$id};
        for my $a (0, 1) {
            $p->[$a] += $vel[$id][$a];
            if    ($p->[$a] < 0)      { $p->[$a] = -$p->[$a];            $vel[$id][$a] *= -1 }
            elsif ($p->[$a] > $WORLD) { $p->[$a] = 2*$WORLD - $p->[$a];  $vel[$id][$a] *= -1 }
        }
        $s->move($h{$id}, @$p);
    }
    my (%seen, $pairs);                            # broad-phase collision candidates
    for my $id (keys %h) {
        for my $other ($s->query_radius(@{$pos{$id}}, $RADIUS)) {
            next if $other == $id;
            my $key = $id < $other ? "$id-$other" : "$other-$id";
            $pairs++ unless $seen{$key}++;
        }
    }
    printf "tick %d: %d entities, %d collision-candidate pairs\n", $tick, $s->count, $pairs // 0;
}
