use strict;
use warnings;

use Test::More tests => 1;

use Chart::OFC;
use Chart::OFC::Grid;


my @datasets =
    Chart::OFC::Dataset::OutlinedBar->new( values        => [ 1 .. 5 ],
                                         opacity       => 50,
                                         outline_color => 'blue',
                                         fill_color    => 'green',
                                         label         => 'small',
                                         text_size     => 9,
                                       );

push @datasets,
    Chart::OFC::Dataset::LineWithDots->new( values    => [ 10, 20, 30, 40, 50, 60, 70 ],
                                            width     => 4,
                                            dot_size  => 7,
                                            label     => 'large',
                                            text_size => 9,
                                          );

push @datasets,
    Chart::OFC::Dataset::GlassBar->new( values        => [ 25..35 ],
                                        outline_color => 'red',
                                        fill_color    => 'yellow',
                                      );

my $x_axis = Chart::OFC::XAxis->new( labels      => [ 'a'..'e' ],
                                     axis_label  => 'X Axis',
                                     orientation => 'diagonal',
                                   );

my $y_axis = Chart::OFC::YAxis->new( axis_label  => 'Y Axis',
                                     min         => 20,
                                     max         => 100,
                                     label_steps => 20,
                                   );

my $chart = Chart::OFC::Grid->new( title       => 'Complex Grid Test',
                                   title_style => 'font-size: 25px',
                                   bg_color    => 'black',
                                   datasets    => \@datasets,
                                   x_axis      => $x_axis,
                                   y_axis      => $y_axis,
                                 );

my @data = ( '&title=Complex Grid Test,{ font-size: 25px }&',
             '&bg_colour=#000000&',
             $x_axis->_ofc_data_lines(),
             $y_axis->_ofc_data_lines(),
             $datasets[0]->_ofc_data_lines(1),
             $datasets[1]->_ofc_data_lines(2),
             $datasets[2]->_ofc_data_lines(3),
           );

my $data = join '', map { $_ . "\r\n" } @data;
is( $chart->as_ofc_data(), $data,
    'check as_ofc_data output' );
