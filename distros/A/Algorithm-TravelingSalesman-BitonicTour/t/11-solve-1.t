use strict;
use warnings;
use Algorithm::TravelingSalesman::BitonicTour;
use Data::Dumper;
use Test::More 'no_plan';
use Test::Exception;

use_ok('Algorithm::TravelingSalesman::BitonicTour');

# make sure a problem with exactly one point "works"
for (1 .. 10) {
    my $b = Algorithm::TravelingSalesman::BitonicTour->new;
    my ($x, $y) = map { 10 - rand(20) } 1, 2;
    $b->add_point($x,$y);
    my @solution;
    lives_ok { @solution = $b->solve };
    is_deeply(\@solution, [0, [$x, $y ]]) or diag(Dumper($b));
}

