use strict;
use warnings;
use Algorithm::FuzzyCmeans::Distance::Cosine;
use Algorithm::FuzzyCmeans::Distance::Euclid;
use Test::More tests => 2;

my %vec1 = (
    a => 1,
    b => 2,
    c => 3,
    d => 4,
);
my %vec2 = (
    a => 3,
    b => 4,
    c => 5,
    e => 1,
);

my $dist;

my $cos = Algorithm::FuzzyCmeans::Distance::Cosine->distance(
    \%vec1, \%vec2);
$dist = 1 - (1*3 + 2*4 + 3*5)
            / (sqrt(1**2 + 2**2 + 3**2 + 4**2)
               * sqrt(3**2 + 4**2 + 5**2 + 1**2));
is($cos, $dist);

my $ecl = Algorithm::FuzzyCmeans::Distance::Euclid->distance(
    \%vec1, \%vec2);
$dist = (1-3)**2 + (2-4)**2 + (3-5)**2 + (4-0)**2 + (0-1)**2;
is($ecl, $dist);
