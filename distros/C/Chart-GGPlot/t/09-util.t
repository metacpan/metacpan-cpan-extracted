#!perl

use Chart::GGPlot::Setup qw(:base :pdl);

use Data::Frame;
use Data::Frame::Examples qw(airquality);
use PDL::Core qw(long);
use Chart::GGPlot::Util qw(:all !match);

use Test2::V0 '!number';
use Test2::Tools::DataFrame;
use Test2::Tools::PDL;

subtest expand_range4 => sub {
    pdl_is(
        expand_range4( pdl( [ 0, 1 ] ), pdl( [ 0, 0, 0, 0 ] ) ),
        pdl([ 0, 1 ]),
        'expand_range4() with empty expand params'
    );
    pdl_is(
        expand_range4( pdl( [ 0, 1 ] ), pdl( [ 1, 2 ] ) ),
        pdl([ 0 - 3, 1 + 3 ]),
        'expand_range4() with 2 expand params'
    );
    pdl_is(
        expand_range4( pdl( [ 0, 1 ] ), pdl( [ 1, 2, 3, 4 ] ) ),
        pdl([ 0 - 3, 1 + 7 ]),
        'expand_range4() with 4 expand params'
    );
    ok( expand_range4( null, pdl( [ 0, 0, 0, 0 ] ) )->isempty,
        'expand_range4() with empty limits' );
};

my $df =
  Chart::GGPlot::Util::find_line_formula( [ 4, 7, 9 ], [ 1, 5, 3 ] );

#diag($df->stringify);

{
    my $spiral_arc_length = Chart::GGPlot::Util::spiral_arc_length(
        [ 0.2,      0.5 ],
        [ 0.5 * PI, PI ],
        [ PI,       1.25 * PI ]
    );
    pdl_is( $spiral_arc_length,
        pdl([ -0.806146217, -1.442604138 ]),
        'spiral_arc_length()'
    );

    my $lf = find_line_formula( pdl( [ 4, 7, 9 ] ), pdl( [ 1, 5, 3 ] ) );
    dataframe_is(
        $lf,
        Data::Frame->new(
            columns => [
                x1         => pdl( 4,              7 ),
                y1         => pdl( 1,              5 ),
                x2         => pdl( 7,              9 ),
                y2         => pdl( 5,              3 ),
                slope      => pdl( 1 + 1 / 3,      -1.000000 ),
                yintercept => pdl( -( 4 + 1 / 3 ), 12.000000 ),
                xintercept => pdl( 3.25,           12.00 )
            ]
        ),
        'find_line_formula()'
    );
}

subtest resolution => sub {
    is( resolution( pdl( [ 1 .. 10 ] ) ),       1 );
    is( resolution( pdl( [ 1 .. 10 ] ) - 0.5 ), 0.5 );
    is( resolution( pdl( [ 1 .. 10 ] ) - 0.5, false ), 1, '$zero=false' );

    # Note the difference between float and integer piddles.
    is( resolution( pdl( [ 2, 10, 20, 50 ] ) ), 2 );
    is( resolution( long( [ 2, 10, 20, 50 ] ) ),
        1, 'result 1 for integer type piddles' );
};

subtest remove_missing => sub {
    my $airquality = airquality();
    is(remove_missing($airquality)->nrow, 111);
};

done_testing();
