use strict;
use warnings;
use Algorithm::TravelingSalesman::BitonicTour;
use Data::Dumper;
use Test::More 'no_plan';
use Test::Exception;
use Readonly;

Readonly::Scalar my $pi => 3.14159;     # duh
Readonly::Scalar my $N  => 201;         # number of points

use_ok('Algorithm::TravelingSalesman::BitonicTour');

# Solve a problem consisting of some large number of points evenly spaced along
# the circumference of the unit circle.  The distance should be roughly 2 * pi.

{
    my $b = Algorithm::TravelingSalesman::BitonicTour->new;
    $b->add_point(@$_) for points();
    my ($length, @points) = $b->solve;
    is(
        sprintf('%.3f', $length),
        sprintf('%.3f', 2 * $pi),
        'circumference of the unit circle equals 2 * pi'
    );

    my $points = do {
        my @p = map "[@$_[0],@$_[1]]", @points[ 0 .. $#points - 1 ];
        join q( ), @p, @p;
    };

    my $correct_re = do {
        my @correct = map quotemeta, map { "[@$_[0],@$_[1]]" } points();
        my $pat = "@correct|@{[ reverse @correct ]}";
        qr/$pat/;
    };
    like($points, $correct_re);
}

sub points {
    return
        map { [ cos($_), sin($_) ] }
        map { $_ + $pi / 2 }
        map { $pi * 2 * $_ / $N }
            0 .. $N - 1;
}

