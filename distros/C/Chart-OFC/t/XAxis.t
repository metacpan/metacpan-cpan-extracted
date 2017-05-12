use strict;
use warnings;

use Test::More tests => 6;

use Chart::OFC::XAxis;
use Chart::OFC::AxisLabel;


eval { Chart::OFC::XAxis->new() };
like( $@, qr/\Q(axis_label) is required/, 'axis_label is required for constructor' );

{
    my $axis_label = Chart::OFC::AxisLabel->new( label => 'Months' );

    my $axis = Chart::OFC::XAxis->new( axis_label => $axis_label );

    my @lines = ( '&x_legend=Months,20,#000000&',
                  '&x_label_style=10,#784016,0,1&',
                );
    is_deeply( [ $axis->_ofc_data_lines() ], \@lines,
               'data lines with defaults and label' );
}

{
    my $axis_label = Chart::OFC::AxisLabel->new( label      => 'Months',
                                                 text_color => 'red',
                                                 text_size  => 10,
                                               );

    my $axis = Chart::OFC::XAxis->new( axis_label => $axis_label );

    my @lines = ( '&x_legend=Months,10,#FF0000&',
                  '&x_label_style=10,#784016,0,1&',
                );
    is_deeply( [ $axis->_ofc_data_lines() ], \@lines,
               'data lines with all-params axis_label' );
}

{
    my $axis = Chart::OFC::XAxis->new( axis_label => 'Months' );

    my @lines = ( '&x_legend=Months,20,#000000&',
                  '&x_label_style=10,#784016,0,1&',
                );
    is_deeply( [ $axis->_ofc_data_lines() ], \@lines,
               'string -> axis_label coercion' );
}

{
    my $axis = Chart::OFC::XAxis->new( axis_label => { label => 'Months', text_size => 15 } );

    my @lines = ( '&x_legend=Months,15,#000000&',
                  '&x_label_style=10,#784016,0,1&',
                );
    is_deeply( [ $axis->_ofc_data_lines() ], \@lines,
               'hashref -> axis_label coercion' );
}

{
    my $axis =
        Chart::OFC::XAxis->new( axis_label     => 'Months',
                                axis_color     => 'blue',
                                label_steps    => 4,
                                tick_steps     => 2,
                                text_size      => 7,
                                text_color     => 'blue',
                                grid_color     => 'orange',
                                labels         => [ qw( jan feb mar apr may jun jul aug sep oct nov dec ) ],
                                three_d_height => 5,
                                orientation    => 'diagonal',
                              );

    my @lines = ( '&x_legend=Months,20,#000000&',
                  '&x_labels=jan,feb,mar,apr,may,jun,jul,aug,sep,oct,nov,dec&',
                  '&x_label_style=7,#0000FF,2,4,#FFA500&',
                  '&x_ticks=2&',
                  '&x_axis_3d=5&',
                  '&x_axis_colour=#0000FF&',
                  '&x_axis_steps=2&',
                );
    is_deeply( [ $axis->_ofc_data_lines() ], \@lines,
               'x axis with all attributes set' );
}
