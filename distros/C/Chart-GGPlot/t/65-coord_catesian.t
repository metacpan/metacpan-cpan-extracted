#!perl

use Chart::GGPlot::Setup;

use Data::Frame;
use Data::Frame::Examples qw(mtcars);

use Test2::V0;

use Chart::GGPlot::Coord::Cartesian;

my @cases_construction = (
    {
        params => {},
    },
    {
        params => { xlim => [ 0, 1 ], ylim => [ 0, 1 ] },
    },
);

for my $case (@cases_construction) {
    my $coord = Chart::GGPlot::Coord::Cartesian->new( %{ $case->{params} } );
    isa_ok( $coord, ['Chart::GGPlot::Coord::Cartesian'], 'construction' );
}

done_testing();
