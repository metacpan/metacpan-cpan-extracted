use strict;
use warnings;

use Data::Dumper;
use Test::More 'no_plan';
use Test::Exception;
local $Data::Dumper::Sortkeys = 1;

use Algorithm::TravelingSalesman::BitonicTour;

# set up a problem and do some basic sanity checking
my $b = Algorithm::TravelingSalesman::BitonicTour->new;
$b->add_point(0,0);
$b->add_point(1,1);
$b->add_point(2,1);
$b->add_point(3,0);
is($b->N, 4);
is_deeply( [$b->sorted_points], [[0,0], [1,1], [2,1], [3,0]] );

# optimal open tours aren't populated yet...
throws_ok { $b->tour_length(1,2) } qr/Don't know the length/, 'die on unpopulated tour length';
throws_ok { $b->tour_points(1,2) } qr/Don't know the points/, 'die on unpopulated tour points';

# make sure population with bad endpoints is caught...
throws_ok { $b->tour_points(1,2,0,1,2) } qr/ERROR/, 'die on bad endpoints';
throws_ok { $b->tour_points(1,2,1,2,3) } qr/ERROR/, 'die on bad endpoints';
throws_ok { $b->tour_points(1,2,1,2)   } qr/ERROR/, 'die on wrong number of points';

# populate the optimal open tours
$b->populate_open_tours;
#diag(Dumper($b));

# make sure invalid tour queries throw an exception
throws_ok { $b->tour(1,0) } qr/ERROR/, 'die on invalid tour limits';
throws_ok { $b->tour_length(42,142) } qr/ERROR/, 'die on invalid length limits';
throws_ok { $b->tour_length(0,1,-1) } qr/ERROR/, 'die on invalid length';
throws_ok { $b->optimal_open_tour(1,0) } qr/ERROR/, 'die on invalid tour limits';
throws_ok { $b->optimal_open_tour(1.5,2) } qr/ERROR/, 'die on invalid tour limits';

{
    my @tour = $b->optimal_open_tour(1,2);
    is (sprintf('%.2f',$tour[0]), 3.65);
}
{
    my @tour = $b->optimal_open_tour(0,2);
    is (sprintf('%.3f',$tour[0]), 2.414);
}

# verify calculated tours
{
    my @tests = (
        [ 0,1 => 1.41 => 0, 1 ],
        [ 0,2 => 2.41 => 0, 1, 2 ],
        [ 0,3 => 3.83 => 0, 1, 2, 3 ],
        [ 1,2 => 3.65 => 1, 0, 2 ],
        [ 1,3 => 5.06 => 1, 0, 2, 3 ],
        [ 2,3 => 5.41 => 2, 1, 0, 3 ],
    );

    my $c = sub { 0 + sprintf('%.2f', $b->tour_length(@_)) };
    my $p = sub { [ $b->tour_points(@_) ] };

    foreach my $t (@tests) {
        my ($i, $j, $length, @points) = @$t;
        is( $c->($i,$j), $length);
        is_deeply( $p->($i, $j), \@points);
    }
}

