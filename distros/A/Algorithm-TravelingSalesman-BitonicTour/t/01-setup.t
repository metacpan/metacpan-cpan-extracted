use strict;
use warnings;

use Test::More 'no_plan';
use Test::Exception;
use Algorithm::TravelingSalesman::BitonicTour;

my $b = Algorithm::TravelingSalesman::BitonicTour->new;

ok($b);
is($b->N, 0);
throws_ok { $b->R } qr/Problem has no rightmost point/, '... with a nice error message';

# add a few points, making sure they're stored and sorted correctly

$b->add_point(0,0);
is($b->N, 1);
is($b->R, 0);
is_deeply( [$b->sorted_points], [[0,0]] );

$b->add_point(3,0);
is($b->N, 2);
is($b->R, 1);
is_deeply( [$b->sorted_points], [[0,0], [3,0]] );

$b->add_point(2,1);
is($b->N, 3);
is($b->R, 2);
is_deeply( [$b->sorted_points], [[0,0], [2,1], [3,0]] );

$b->add_point(1,1);
is($b->N, 4);
is($b->R, 3);
is_deeply( [$b->sorted_points], [[0,0], [1,1], [2,1], [3,0]] );

# make sure that attempts to add points with duplicate X-coordinates croak()
{
    dies_ok { $b->add_point(2,1) } 'repeated X-coordinate should die';
    dies_ok { $b->add_point(2,2) } 'repeated X-coordinate should die';
    dies_ok { $b->add_point(2,3) } 'repeated X-coordinate should die';
    throws_ok { $b->add_point(2,1) } qr/duplicates previous point/,
        'with a nice error message';
}

# make sure we can retrieve coordinates correctly
is_deeply([ $b->coord( 0) ], [ 0, 0 ]);
is_deeply([ $b->coord( 1) ], [ 1, 1 ]);
is_deeply([ $b->coord( 2) ], [ 2, 1 ]);
is_deeply([ $b->coord( 3) ], [ 3, 0 ]);
is_deeply([ $b->coord(-1) ], [ 3, 0 ]);     # sweet

# verify that delta() returns the correct distances between points
{
    my $d = sub { return 0 + sprintf('%.3f', $b->delta(@_)) };
    is( $d->(0,0), 0.0);
    is( $d->(1,1), 0.0);
    is( $d->(0,1), 1.414);
    is( $d->(0,2), 2.236);
    is( $d->(0,3), 3.0);
    is( $d->(1,2), 1.0);
    is( $d->(1,3), 2.236);
    is( $d->(2,3), 1.414);
}

