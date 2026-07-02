#!/usr/bin/env perl
# Single-process benchmark: insert, query_radius, query_knn, move, bulk, pairs
use strict;
use warnings;
use FindBin;
use lib "$FindBin::Bin/../blib/lib", "$FindBin::Bin/../blib/arch";
use Time::HiRes qw(time);
use Data::SpatialHash::Shared;

my $N = 100_000;
my $s = Data::SpatialHash::Shared->new(undef, $N, 0, 1.0);
my @h;

my $t = time;
push @h, $s->insert(rand() * 1000, rand() * 1000, $_) for 1 .. $N;
printf "insert: %.2fM/s\n", $N / (time - $t) / 1e6;

$t = time;
$s->query_radius(rand() * 1000, rand() * 1000, 10) for 1 .. 10_000;
printf "query_radius: %.0f/s\n", 10_000 / (time - $t);

$t = time;
$s->query_knn(rand() * 1000, rand() * 1000, 10) for 1 .. 10_000;
printf "query_knn(10): %.0f/s\n", 10_000 / (time - $t);

$t = time;
$s->move($h[int rand @h], rand() * 1000, rand() * 1000) for 1 .. $N;
printf "move: %.2fM/s\n", $N / (time - $t) / 1e6;

# bulk move of all N entries in one call (amortizes per-call + lock overhead)
my @rows = map { [ $h[$_], rand() * 1000, rand() * 1000 ] } 0 .. $#h;
$t = time;
$s->move_many(\@rows) for 1 .. 50;
printf "move_many: %.2fM/s\n", $N * 50 / (time - $t) / 1e6;

# collision broad-phase: A actors with interaction radii on a torus, one
# each_colliding_pair call = the whole broad+narrow phase of a tick
my ($W, $A) = (2000, 4000);
my $c = Data::SpatialHash::Shared->new(undef, $A, 0, 16, wrap => [$W, $W]);
for (1 .. $A) { my $hh = $c->insert(rand() * $W, rand() * $W, $_); $c->set_radius($hh, 2 + rand() * 4); }
$t = time;
my $passes = 200;
$c->each_colliding_pair(sub { }) for 1 .. $passes;
printf "each_colliding_pair (N=%d, torus): %.0f/s (%.2f ms each)\n",
    $A, $passes / (time - $t), (time - $t) / $passes * 1000;

# spherical world: geo proximity (planet) + cube-sphere cell ids
my $E   = 6_371_000;
my $geo = Data::SpatialHash::Shared->new(undef, $N, 0, 50000, sphere => $E);
$geo->insert_geo(0.5 + rand() * 0.3, 0.2 + rand() * 0.3, rand() * 5000, $_) for 1 .. $N;
$t = time;
$geo->query_geo_radius(0.5 + rand() * 0.3, 0.2 + rand() * 0.3, 0, 100000) for 1 .. 10_000;
printf "query_geo_radius: %.0f/s\n", 10_000 / (time - $t);

my @dirs = map { [ rand() - 0.5, rand() - 0.5, rand() - 0.5 ] } 1 .. 1000;
my $sink = 0;
$t = time;
for (1 .. 2000) { $sink += $geo->cube_cell(@$_, 14) for @dirs; }
printf "cube_cell (level 14): %.1fM/s\n", 2_000_000 / (time - $t) / 1e6;
