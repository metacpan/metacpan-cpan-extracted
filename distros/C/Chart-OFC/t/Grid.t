use strict;
use warnings;

use Test::More tests => 11;

use Chart::OFC::Grid;
use Chart::OFC::Dataset::Bar;
use Chart::OFC::XAxis;
use Chart::OFC::YAxis;


my @datasets = Chart::OFC::Dataset::Bar->new( values => [ 1 .. 5] );
my $x_axis = Chart::OFC::XAxis->new( axis_label => 'X Axis' );
my $y_axis = Chart::OFC::YAxis->new( axis_label => 'Y Axis', max => 100, label_steps => 20 );


eval { Chart::OFC::Grid->new( datasets => \@datasets, x_axis => $x_axis, y_axis => $y_axis,
                              inner_bg_color2 => 'red' ) };
like( $@, qr/\QYou cannot set a second inner background color unless you set a first color and a fade angle/,
      'cannot set inner_bg_color2 without setting inner_bg_color' );

eval { Chart::OFC::Grid->new( datasets => \@datasets, x_axis => $x_axis, y_axis => $y_axis,
                              inner_bg_color => 'blue', inner_bg_color2 => 'red' ) };
like( $@, qr/\QYou cannot set a second inner background color unless you set a first color and a fade angle/,
      'cannot set inner_bg_color2 without setting inner_bg_color' );

eval { Chart::OFC::Grid->new( datasets => \@datasets, x_axis => $x_axis, y_axis => $y_axis,
                              inner_bg_fade_angle => 90 ) };
like( $@, qr/\QYou cannot set an inner background fade angle unless you set two background colors/,
      'cannot set inner_bg_fade_color without setting two bg colors' );

eval { Chart::OFC::Grid->new( datasets => \@datasets, x_axis => $x_axis, y_axis => $y_axis,
                              inner_bg_color2 => 'red', inner_bg_fade_angle => 90 ) };
like( $@, qr/\QYou cannot set an inner background fade angle unless you set two background colors/,
      'cannot set inner_bg_fade_color without setting two bg colors' );

eval { Chart::OFC::Grid->new( datasets => \@datasets, x_axis => $x_axis, y_axis => $y_axis,
                              inner_bg_color => 'red', inner_bg_fade_angle => 90 ) };
like( $@, qr/\QYou cannot set an inner background fade angle unless you set two background colors/,
      'cannot set inner_bg_fade_color without setting two bg colors' );

eval { Chart::OFC::Grid->new( datasets => \@datasets, y_axis => $y_axis ) };
like( $@, qr/\Q(x_axis) is required/, 'x_axis is required for constructor' );

eval { Chart::OFC::Grid->new( datasets => \@datasets, x_axis => $x_axis ) };
like( $@, qr/\Q(y_axis) is required/, 'y_axis is required for constructor' );

eval { Chart::OFC::Grid->new( x_axis => $x_axis, y_axis => $y_axis ) };
like( $@, qr/\Q(datasets) is required/, 'datasets is required for constructor' );

{
    my $chart = Chart::OFC::Grid->new( title    => 'Grid Test',
                                       datasets => \@datasets,
                                       x_axis   => $x_axis,
                                       y_axis   => $y_axis,
                                     );

    my @data = ( '&title=Grid Test,{ font-size: 25px }&',
                 $x_axis->_ofc_data_lines(),
                 $y_axis->_ofc_data_lines(),
                 $datasets[0]->_ofc_data_lines(1),
               );

    my $data = join '', map { $_ . "\r\n" } @data;
    is( $chart->as_ofc_data(), $data,
        'check as_ofc_data output' );
}

{
    my $chart = Chart::OFC::Grid->new( title    => 'Grid Test, Comma in Title',
                                       datasets => \@datasets,
                                       x_axis   => $x_axis,
                                       y_axis   => $y_axis,
                                     );

    my @data = ( '&title=Grid Test#comma# Comma in Title,{ font-size: 25px }&',
                 $x_axis->_ofc_data_lines(),
                 $y_axis->_ofc_data_lines(),
                 $datasets[0]->_ofc_data_lines(1),
               );

    my $data = join '', map { $_ . "\r\n" } @data;
    is( $chart->as_ofc_data(), $data,
        'check as_ofc_data output' );
}

{
    my $chart = Chart::OFC::Grid->new( title               => 'Grid Test',
                                       inner_bg_color      => '#FFFF00',
                                       inner_bg_color2     => '#FFFFFF',
                                       inner_bg_fade_angle => 152,
                                       datasets            => \@datasets,
                                       x_axis              => $x_axis,
                                       y_axis              => $y_axis,
                                     );

    my @data = ( '&title=Grid Test,{ font-size: 25px }&',
                 '&inner_background=#FFFF00,#FFFFFF,152&',
                 $x_axis->_ofc_data_lines(),
                 $y_axis->_ofc_data_lines(),
                 $datasets[0]->_ofc_data_lines(1),
               );

    my $data = join '', map { $_ . "\r\n" } @data;
    is( $chart->as_ofc_data(), $data,
        'check as_ofc_data output' );
}
