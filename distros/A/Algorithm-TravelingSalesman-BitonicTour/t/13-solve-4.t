use strict;
use warnings;
use Algorithm::TravelingSalesman::BitonicTour;
use Data::Dumper;
use Test::More 'no_plan';
use Test::Exception;

use_ok('Algorithm::TravelingSalesman::BitonicTour');

# solve a real problem (simple trapezoid)
{
    my $b = Algorithm::TravelingSalesman::BitonicTour->new;
    $b->add_point(0,0);
    $b->add_point(1,1);
    $b->add_point(2,1);
    $b->add_point(3,0);
    my ($length, @points) = $b->solve;
    is(sprintf('%.3f', $length), 6.828, 'known correct length');
    my $points = do {
        my @p = map "[@$_[0],@$_[1]]", @points[ 0 .. $#points - 1 ];
        join q( ), @p, @p;
    };
    my $correct_re = do {
        my @correct = map quotemeta, ('[0,0]','[1,1]','[2,1]','[3,0]');
        my $pat = "@correct|@{[ reverse @correct ]}";
        qr/$pat/;
    };
    like($points, $correct_re);
    #diag "length=$length";
    #diag Dumper(@points);
}

