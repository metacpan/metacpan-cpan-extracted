use strict;
use warnings;
use Algorithm::TravelingSalesman::BitonicTour;
use Data::Dumper;
use Test::More 'no_plan';
use Test::Exception;

use_ok('Algorithm::TravelingSalesman::BitonicTour');

# make sure a problem with exactly two points "works"
for my $i (1 .. 10) {

    my @points = map {
        my $x = $_ * (5 + rand(10));
        my $y = $_ * (5 + rand(10));
        [ $x, $y ];
    } (-1, 1);

    my $b = Algorithm::TravelingSalesman::BitonicTour->new;

    $b->add_point(@$_) for @points;

    my $delta = delta(@points);

    my @solution;
    lives_ok { @solution = $b->solve };
    is(round($solution[0]), round(2 * $delta));
}

sub delta {
    my ($p1, $p2) = @_;
    my ($x1, $y1) = @$p1;
    my ($x2, $y2) = @$p2;
    return sqrt((($x1-$x2)*($x1-$x2))+(($y1-$y2)*($y1-$y2)));
}

sub round {
    my $float = shift;
    return sprintf '%.6f', $float;
}

