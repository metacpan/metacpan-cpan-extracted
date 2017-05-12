use strict;
use warnings;
use Algorithm::TravelingSalesman::BitonicTour;
use Data::Dumper;
use Test::More 'no_plan';
use Test::Exception;

use_ok('Algorithm::TravelingSalesman::BitonicTour');

# make sure an attempt to solve a problem with no points dies
{
    my $b = Algorithm::TravelingSalesman::BitonicTour->new;
    throws_ok { $b->solve } qr/need to add some points/,
        'bad problem throws exception';
}

