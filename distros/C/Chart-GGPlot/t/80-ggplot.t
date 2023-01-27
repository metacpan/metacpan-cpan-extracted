#!perl

use Chart::GGPlot::Setup qw(:base :pdl);

use Data::Frame;
use Data::Frame::Examples qw(mtcars mpg economics);

use Test2::V0;
use Test2::Tools::DataFrame;
use Test2::Tools::PDL;

use Chart::GGPlot qw(:all);
use Chart::GGPlot::Built;
use Chart::GGPlot::Util qw(NA);

$Data::Frame::TOLERANCE_REL = 1e-3;

subtest geom_point_1 => sub {
    my $mtcars = mtcars();

    my $p = ggplot(
        data    => $mtcars,
        mapping => aes( x => 'wt', y => 'mpg' )
    )->geom_point();

    isa_ok( $p, ['Chart::GGPlot::Plot'], 'ggplot()' );

    my $built = $p->backend->build($p);
    isa_ok( $built, [qw(Chart::GGPlot::Built)], '$plot->build' );

    my $data = $built->data;
    is( $data->length, 1 );
    diag($data->[0]->string);

    my $data_expected = Data::Frame->new(
        columns => [
            x      => $mtcars->at('wt'),
            x_raw  => $mtcars->at('wt'),
            y      => $mtcars->at('mpg'),
            y_raw  => $mtcars->at('mpg'),
            PANEL  => pdl(0),
            group  => pdl(0),
            alpha  => NA(),
            color  => PDL::SV->new( ['black'] ),
            fill   => NA(),
            shape  => pdl(19),
            size   => pdl(1.5),
            stroke => pdl(0.5),
        ]
    );

    dataframe_is( $data->[0], $data_expected, '$built->data' );

    my $layout = $built->layout;
    dataframe_is(
        $layout->layout,
        Data::Frame->new(
            columns => [
                PANEL   => pdl( [0] ),
                ROW     => pdl( [0] ),
                COL     => pdl( [0] ),
                SCALE_X => pdl( [0] ),
                SCALE_Y => pdl( [0] ),
            ]
        ),
        '$built->layout->layout'
    );

    my $coord = $layout->coord;
    isa_ok( $coord, [qw(Chart::GGPlot::Coord::Cartesian)],
        '$built->layout->coord' );

    my $facet = $layout->facet;
    isa_ok( $facet, [qw(Chart::GGPlot::Facet::Null)], '$built->layout->facet' );

    my $scales   = $layout->get_scales(0);
    my $scales_x = $scales->{x};
    my $scales_y = $scales->{y};
    isa_ok( $scales_x, [qw(Chart::GGPlot::Scale::ContinuousPosition)],
        '$scales->{x}' );
    pdl_is(
        $scales_x->range->range,
        pdl( [ 1.513, 5.424 ] ),
        '$scale->{x}->range'
    );
    ok( $scales_x->limits->isempty, '$scale->{x}->limits' );
    isa_ok( $scales_y, [qw(Chart::GGPlot::Scale::ContinuousPosition)],
        '$scales->{y}' );
    pdl_is(
        $scales_y->range->range->pdl,
        pdl( [ 10.4, 33.9 ] ),
        '$scale->{y}->range'
    );
    ok( $scales_y->limits->isempty, '$scale->{y}->limits' );

    diag($p->summary);
};

subtest geom_point_2 => sub {
    my $mtcars = mtcars();

    my $p = ggplot(
        data    => $mtcars,
        mapping => aes( x => 'wt', y => 'mpg' )
    )->geom_point( mapping => aes( color => 'factor($cyl)' ) );

    my $built = $p->backend->build($p);
    my $data  = $built->data;
    diag($data->[0]->string);

    my $data_expected = Data::Frame->new(
        columns => [
            color => PDL::SV->new(
                $mtcars->at('cyl')->unpdl->map(
                    sub {
                        state $mapping =
                          { 6 => '#00ba38', 4 => '#f8766d', 8 => '#619cff' };
                        $mapping->{$_};
                    }
                )
            ),
            color_raw => factor( $mtcars->at('cyl') ),
            x         => $mtcars->at('wt'),
            x_raw     => $mtcars->at('wt'),
            y         => $mtcars->at('mpg'),
            y_raw     => $mtcars->at('mpg'),
            PANEL     => pdl(0),
            group     => pdl(
                $mtcars->at('cyl')->unpdl->map(
                    sub {
                        state $mapping = { 4 => 0, 6 => 1, 8 => 2 };
                        $mapping->{$_};
                    }
                )
            ),
            alpha  => NA(),
            fill   => NA(),
            shape  => pdl(19),
            size   => pdl(1.5),
            stroke => pdl(0.5),
        ]
    );

    dataframe_is( $data->[0], $data_expected, '$built->data' );

    is( $built->plot->labels,
        { x => 'wt', y => 'mpg', color => 'factor($cyl)' },
        '$built->plot->labels' );

};

subtest geom_bar_1 => sub {
    my $mpg = mpg();

    my $p = ggplot(
        data    => $mpg,
        mapping => aes( x => 'class' )
    )->geom_bar();

    my $built = $p->backend->build($p);
    my $data  = $built->data;
    diag($data->[0]->string);

    my $count = pdl(5, 47, 41, 11, 33, 35, 62);
    my $class_sorted = PDL::SV->new( [ sort $mpg->at('class')->uniq->list ] );
    my $data_expected = Data::Frame->new(
        columns => [
            count    => $count,
            prop     => pdl(1),
            x        => pdl( 0 .. 6 ),
            x_raw    => $class_sorted,
            PANEL    => pdl(0),
            group    => pdl( 0 .. 6 ),
            y        => $count,
            xmax     => pdl( 0.45, 1.45, 2.45, 3.45, 4.45, 5.45, 6.45 ),
            xmin     => pdl( -0.45, 0.55, 1.55, 2.55, 3.55, 4.55, 5.55 ),
            ymax     => $count,
            ymin     => pdl(0),
            alpha    => NA(),
            color    => NA(),
            fill     => PDL::SV->new( ['grey35'] ),
            linetype => PDL::SV->new( ['solid'] ),
            size     => pdl(0.5),
        ]
    );

    #diag($data_expected->string);

    dataframe_is( $data->[0], $data_expected, '$built->data' );

    is( $built->plot->labels,
        { x => 'class', y => '$count', weight => 'weight' },
        '$built->plot->labels' );

    my $layout = $built->layout;
    my $panel_params = $layout->panel_params->at(0);

    pdl_is(
        $panel_params->{'x.labels'},
        PDL::SV->new(
            [qw(2seater compact midsize minivan pickup subcompact suv)]
        ),
        'x.labels',
    );
    pdl_is( $panel_params->{'x.major_source'}, pdl(0 .. 6), 'x.major_source');
    pdl_is( $panel_params->{'x.range'}, pdl( [ -0.6, 6.6 ] ), 'x.range' );
    pdl_is( $panel_params->{'y.range'}, pdl( [ -3.1, 65.1 ] ), 'y.range' );
};

subtest geom_line_1 => sub {
    my $economics = economics();

    my $p = ggplot(
        data    => $economics,
        mapping => aes( x => 'date', y => 'unemploy' )
    )->geom_line();

    my $built = $p->backend->build($p);
    my $data  = $built->data;
    diag($data->[0]->string);

    my $x_raw = PDL::DateTime->new_sequence('1967-07-01', 10, 'month');
    my $x = pdl($x_raw->unpdl);
    my $y = $economics->at('unemploy')->slice(pdl(0 .. 9));

    my $data_expected = Data::Frame->new(
        columns => [
            x        => $x,
            x_raw    => $x_raw,
            y        => $y,
            y_raw    => $y,
            PANEL    => pdl(0),
            group    => pdl(0),
            alpha    => NA(),
            color    => PDL::SV->new( ['black'] ),
            linetype => PDL::SV->new( ['solid'] ),
            size     => pdl(0.5),
        ]
    );

    my $data0 = $data->[0]->head(10);
    dataframe_is( $data0->head(10), $data_expected, '$built->data' );

    my $layout = $built->layout;

    my $scales = $layout->get_scales(0);
    my $scale_x = $scales->at('x');
    isa_ok( $scale_x, [qw(Chart::GGPlot::Scale::ContinuousDateTime)],
        '$scale_x is Chart::GGPlot::Scale::ContinuousDateTime object' );

    my $scale_x_breaks = $scale_x->get_breaks();
    DOES_ok($scale_x_breaks, [qw(PDL PDL::Role::HasNames)]);
    pdl_is(
        pdl(
            $scale_x_breaks->unpdl->map(
                sub {
                    $_ eq 'BAD' ? 'nan' : $_;
                }
            )
        )->setnantobad,
        pdl(qw(nan 0 3.155328e+14 6.31152e+14 9.466848e+14 1.262304e+15 nan))
          ->setnantobad,
        '$scale_x->get_breaks()'
    );
    pdl_is( $scale_x->get_labels(),
        PDL::SV->new( [qw(1960 1970 1980 1990 2000 2010 2020)] ), 
        '$scale_x->get_labels()' );

    my $panel_params = $layout->panel_params->at(0);
    pdl_is(
        $panel_params->{'x.labels'},
        PDL::SV->new(
            [qw(1970 1980 1990 2000 2010)]
        ),
        'x.labels',
    );
};

subtest geom_boxplot_1 => sub {
    my $p = ggplot(
        data    => mpg(),
        mapping => aes( x => 'class', y => 'hwy' )
    )->geom_boxplot();

    isa_ok( $p, ['Chart::GGPlot::Plot'], 'ggplot()' );

    my $built = $p->backend->build($p);
    isa_ok( $built, [qw(Chart::GGPlot::Built)], '$plot->build' );

    my $data = $built->data->[0]->select_columns(
        [
            qw(
              ymin lower middle upper ymax notchupper notchlower
              PANEL group ymin_final ymax_final
              size
              )
        ]
    );
    my $data_expected = Data::Frame->new(
        columns => [
            ymin   => pdl( [ 23, 23, 23, 21, 15, 20,   14 ] ),
            lower  => pdl( [ 24, 26, 26, 22, 16, 24.5, 17 ] ),
            middle => pdl( [ 25, 27, 27, 23, 17, 26,   17.5 ] ),
            upper  => pdl( [ 26, 29, 29, 24, 18, 30.5, 19 ] ),
            ymax   => pdl( [ 26, 33, 32, 24, 20, 36,   22 ] ),
            notchupper => pdl(
                [
                    26.41319, 27.69140, 27.74026, 23.95278,
                    17.55009, 27.60241, 17.90132
                ]
            ),
            notchlower => pdl(
                [
                    23.58681, 26.30860, 26.25974, 22.04722,
                    16.44991, 24.39759, 17.09868
                ]
            ),
            PANEL      => pdl(0),
            group      => pdl( [ 0 .. 6 ] ),
            ymin_final => pdl( [ 23, 23, 23, 17, 12, 20, 12 ] ),
            ymax_final => pdl( [ 26, 44, 32, 24, 22, 44, 27 ] ),
            size       => pdl(0.5),
          ]
    );
    dataframe_is( $data, $data_expected, '$built->data' );
};

subtest geom_polygon_1 => sub {
    my $datapoly = Data::Frame->new(
        columns => [
            id    => factor( [ map { ($_) x 4 } qw(1.1 2.1 1.2 2.2 1.3 2.3) ] ),
            value => pdl(    [ map { ($_) x 4 } qw(3 3.1 3.1 3.2 3.15 3.5) ] ),
            x     => pdl(
                2,   1,   1.1, 2.2, 1,   0,   0.3, 1.1, 2.2, 1.1, 1.2, 2.5,
                1.1, 0.3, 0.5, 1.2, 2.5, 1.2, 1.3, 2.7, 1.2, 0.5, 0.6, 1.3
            ),
            y => pdl(
                -0.5, 0,   1,   0.5, 0,   0.5, 1.5, 1,
                0.5,  1,   2.1, 1.7, 1,   1.5, 2.2, 2.1,
                1.7,  2.1, 3.2, 2.8, 2.1, 2.2, 3.3, 3.2
            ),
        ]
    );

    my $p = ggplot(
        data    => $datapoly,
        mapping => aes( x => 'x', y => 'y' )
    )->geom_polygon( mapping => aes( fill => 'value', group => 'id' ) );

    my $built = $p->backend->build($p);

    my $scales = $p->scales;
    is( $scales->length, 3, '$plot->scales->length' );
    my $scale_color = $scales->scales->[0];
    isa_ok( $scale_color, ['Chart::GGPlot::Scale::Continuous'] );
    is( $scale_color->guide, 'colorbar',
        q{geom_polygon's color scale guide is "colorbar"} );
    
    pass();
};

done_testing();
