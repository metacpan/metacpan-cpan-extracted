use strict;
use warnings;

use Test::More tests => 5;

use Chart::OFC::YAxis;
use Chart::OFC::AxisLabel;


eval { Chart::OFC::YAxis->new( label_steps => 4, max => 20 ) };
like( $@, qr/\Q(axis_label) is required/, 'axis_label is required for constructor' );

eval { Chart::OFC::YAxis->new( axis_label => 'Foo', max => 20 ) };
like( $@, qr/\Q(label_steps) is required/, 'label_steps is required for constructor' );

eval { Chart::OFC::YAxis->new( axis_label => 'Foo', label_steps => 4 ) };
like( $@, qr/\Q(max) is required/, 'max is required for constructor' );

{
    my $axis_label = Chart::OFC::AxisLabel->new( label => 'Size' );

    my $axis = Chart::OFC::YAxis->new( axis_label  => $axis_label,
                                       max         => 20,
                                       label_steps => 5,
                                     );

    my @lines = ( '&y_legend=Size,20,#000000&',
                  '&y_label_style=10,#784016&',
                  '&y_ticks=5,10,4&',
                  '&y_min=0&',
                  '&y_max=20&',
                );
    is_deeply( [ $axis->_ofc_data_lines() ], \@lines,
               'data lines with defaults and label-only axis_label' );
}

{
    my $axis = Chart::OFC::YAxis->new( axis_label      => 'Size',
                                       min             => -9.5,
                                       max             => 20.5,
                                       small_tick_size => 2,
                                       large_tick_size => 20,
                                       label_steps     => 5,
                                       text_color      => 'blue',
                                       axis_color      => 'green',
                                       grid_color      => 'red',
                                     );

    my @lines = ( '&y_legend=Size,20,#000000&',
                  '&y_label_style=10,#0000FF&',
                  '&y_ticks=2,20,6&',
                  '&y_min=-9.5&',
                  '&y_max=20.5&',
                  '&y_axis_colour=#00FF00&',
                  '&y_grid_colour=#FF0000&',
                );
    is_deeply( [ $axis->_ofc_data_lines() ], \@lines,
               'data lines with all parameters' );
}
