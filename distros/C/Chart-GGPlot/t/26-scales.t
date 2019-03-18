#!perl 

use Chart::GGPlot::Setup qw(:base :pdl);

use Data::Frame::Examples qw(mtcars);

use Test2::V0;
use Test2::Tools::PDL;

use Chart::GGPlot::Aes::Functions qw(aes);
use Chart::GGPlot::Scale::Functions qw(:all);
use Chart::GGPlot::ScalesList;

my $mtcars = mtcars();

{
    my $scales = Chart::GGPlot::ScalesList->new();
    ok( $scales, 'Chart::GGPlot::ScalesList->new' );

    $scales->add( scale_color_continuous() );
    $scales->add( scale_x_continuous() );

    is( $scales->length, 2, '$scales->add' );

    ok( $scales->has_scale('x'),  '$scales->has_scale' );
    ok( !$scales->has_scale('y'), '$scales->has_scale' );

    is(
        [ sort @{ $scales->input } ],
        [
            sort
              qw(color x xmin xmax xend xintercept xmin_final xmax_final xlower xmiddle xupper)
        ],
        '$scales->sort'
    );

    pdl_is( $scales->find('xmin'), pdl([ 0, 1 ]), '$scales->find' );
    pdl_is( $scales->find( [qw(xmin xmax)] ), pdl([ 0, 1 ]), '$scales->find' );
    pdl_is(
        $scales->find( [qw(xmin xmax color)] ),
        pdl([ 1, 1 ]),
        '$scales->find'
    );

    {

        my $non_position_scales = $scales->non_position_scales;
        isa_ok(
            $non_position_scales,
            ['Chart::GGPlot::ScalesList'],
            '$scales->non_position_scales'
        );
        is( $non_position_scales->length, 1 );

    }

    {
        my $got_scales = $scales->get_scales('x');
        ok( $got_scales->$_does('Chart::GGPlot::Scale'),
            '$scales->get_scales' );

        my $got_scales2 = $scales->get_scales( [qw(color x)] );
        ok( $got_scales2->$_does('Chart::GGPlot::Scale'),
            '$scales->get_scales' );
    }
}

{
    my $scales = Chart::GGPlot::ScalesList->new();
    $scales->add_missing( [qw(x y)] );

    ok( ($scales->has_scale('x') and $scales->has_scale('y')),
        '$scales->add_missing()' );
}

{
    my $scales = Chart::GGPlot::ScalesList->new();
    $scales->add_defaults( $mtcars, aes(x => 'mpg', y => 'wt') );

    ok( ($scales->has_scale('x') and $scales->has_scale('y')),
        '$scales->add_defaults()' );
}

done_testing();
