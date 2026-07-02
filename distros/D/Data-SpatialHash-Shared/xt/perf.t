use strict; use warnings; use Test::More;
use Time::HiRes qw(time);
plan skip_all => 'author test' unless $ENV{AUTHOR_TESTING};

use Data::SpatialHash::Shared;

# Throughput regression guard. Floors are ~10x below measured numbers so they
# catch a gross regression, not normal machine variance.

my $N = 100_000;
my $s = Data::SpatialHash::Shared->new(undef, $N, 0, 1.0);
my @h;

my $t = time; push @h, $s->insert(rand()*1000, rand()*1000, $_) for 1 .. $N;
my $ins = $N / (time - $t);
$t = time; $s->query_radius(rand()*1000, rand()*1000, 10) for 1 .. 10_000;
my $rad = 10_000 / (time - $t);
$t = time; $s->query_knn(rand()*1000, rand()*1000, 10) for 1 .. 10_000;
my $knn = 10_000 / (time - $t);
$t = time; $s->move($h[int rand @h], rand()*1000, rand()*1000) for 1 .. $N;
my $mov = $N / (time - $t);

diag sprintf 'insert %.2fM/s  radius %.0f/s  knn %.0f/s  move %.2fM/s',
    $ins/1e6, $rad, $knn, $mov/1e6;

cmp_ok $ins, '>', 300_000, 'insert throughput floor';
cmp_ok $rad, '>', 3_000,   'radius throughput floor';
cmp_ok $knn, '>', 3_000,   'knn throughput floor';
cmp_ok $mov, '>', 300_000, 'move throughput floor';

done_testing;
