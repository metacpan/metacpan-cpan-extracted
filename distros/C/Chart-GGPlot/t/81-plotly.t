#!perl

use Chart::GGPlot::Setup qw(:base :pdl);

use Data::Frame;
use Module::Load;

use Test2::V0;
use Test2::Tools::DataFrame;
use Test2::Tools::PDL;

use Chart::GGPlot::Backend::Plotly::Util qw(:all);
use Chart::GGPlot qw(:all);

# use all backend geom implementations for syntax test
subtest syntax_check => sub {
    my @geoms = qw(Bar Boxplot Path Point Line);
    for (@geoms) {
        my $package = "Chart::GGPlot::Backend::Plotly::Geom::$_"; 
        eval { load $package };
        unless (ok(!$@, "syntax check: $package")) {
            diag $@;
        }
    }
};

subtest group_to_NA => sub {
    my $df1 = Data::Frame->new(
        columns => [
            group => pdl( [ (0) x 10 ] ),
            x     => pdl( [ (1) x 10 ] )
        ]
    );
    dataframe_is( group_to_NA($df1), $df1, 'same group' );

    my $df1_retraced = Data::Frame->new(
        columns => [
            group => pdl( [ (0) x 10, 0 ] ),
            x     => pdl( [ (1) x 10, 1 ] )
        ]
    );
    dataframe_is( group_to_NA( $df1, retrace_first => true ),
        $df1_retraced, 'same group, retrace' );

    my $df2 = Data::Frame->new( columns => [ group => pdl( [0] ) ] );
    my $df2_retraced =
      Data::Frame->new( columns => [ group => pdl( [ 0, 0 ] ) ] );
    dataframe_is( group_to_NA($df2), $df2, 'single row' );
    dataframe_is( group_to_NA( $df2, retrace_first => true ),
        $df2_retraced, 'single row, retrace' );

    my $df3 = Data::Frame->new(
        columns => [
            group => pdl( [ (0) x 5, (1) x 5 ] ),
            x     => pdl( [ (1) x 10 ] )
        ]
    );
    dataframe_is(
        group_to_NA($df3),
        Data::Frame->new(
            columns => [
                group => pdl( [ (0) x 6, (1) x 5 ] ),
                x     => pdl( [ (1) x 11 ] )->setbadat(5),
            ]
        ),
        'multiple groups'
    );

    my $df4 = Data::Frame->new(
        columns => [
            group => pdl( [ (0) x 5, (1) x 5 ] ),
            x     => pdl( [ 0, 0, 0, 1, 2, 0, 0, 0, 1, 2 ] ),
            y     => pdl( [ ( 0, 1 ) x 5 ] )
        ]
    );
    my $df4_expected = Data::Frame->new(
        columns => [
            group => pdl( [ (0) x 4, (1) x 3, (0) x 2, 1, (0) x 2, 1 ] ),
            x     => pdl( [ (0) x 7, (1) x 3, (2) x 3 ] ),
            y => pdl( [ 0, 0, 1, "nan", 0, 1, 1, 1, "nan", 0, 0, "nan", 1 ] )
              ->setnantobad,
        ]
    );
    diag( $df4->string );
    diag( $df4_expected->string(-1) );
    dataframe_is( group_to_NA( $df4, nested => ['x'], ordered => ['y'] ),
        $df4_expected, 'multiple groups' );

    my $df4_retraced = Data::Frame->new(
        columns => [
            group =>
              pdl( [ (0) x 5, (1) x 4, (0) x 3, (1) x 2, (0) x 3, (1) x 2 ] ),
            x => pdl( [ (0) x 9, (1) x 5, (2) x 5 ] ),
            y => pdl(
                [
                    0, 0, 1, 0, "nan", 0, 1, 1, 0, 1, 1, "nan", 0, 0, 0, 0,
                    "nan", 1, 1
                ]
            )->setnantobad,
        ]
    );
    diag( $df4_retraced->string(-1) );
    dataframe_is(
        group_to_NA(
            $df4,
            nested        => ['x'],
            ordered       => ['y'],
            retrace_first => true
        ),
        $df4_retraced,
        'multiple groups, retrace'
    );
};

subtest to_rgb => sub {
    no warnings 'qw';

    pdl_is(
        to_rgb( PDL::SV->new( [qw(black white)] ) ),
        PDL::SV->new( [qw(#000000 #ffffff)] ),
        'to_rgb([qw(black white)])'
    );

    pdl_is(
        to_rgb( PDL::SV->new( [qw(black white)] ), pdl(1) ),
        PDL::SV->new( [qw(#000000 #ffffff)] ),
        'to_rgb([qw(black white)]), pdl(1)'
    );

    pdl_is(
        to_rgb( PDL::SV->new( [qw(black white)] ), pdl( [ 0.2, 0.8001 ] ) ),
        PDL::SV->new( [qw{rgba(0,0,0,0.2) rgba(255,255,255,0.8)}] ),
        'to_rgb([qw(black white)]), pdl([0.2, 0.8])'
    );

    pdl_is(
        to_rgb( PDL::SV->new( [qw(black white)] ), pdl( [ 0.2, 1 ] ) ),
        PDL::SV->new( [qw{rgba(0,0,0,0.2) #ffffff}] ),
        'to_rgb([qw(black white)]), pdl([0.2, 1])'
    );
};

done_testing();
