use strict;
use warnings;

use Test::More tests => 4;

use Chart::OFC::AxisLabel;


eval { Chart::OFC::AxisLabel->new() };
like( $@, qr/\Q(label) is required/, 'label is required for constructor' );

{
    my $axis_label = Chart::OFC::AxisLabel->new( label => 'Months' );
    is( $axis_label->_ofc_data_lines('x'), '&x_legend=Months,20,#000000&',
        'data lines with defaults' );
}

{
    my $axis_label = Chart::OFC::AxisLabel->new( label => 'Months, With Year' );
    is( $axis_label->_ofc_data_lines('x'), '&x_legend=Months#comma# With Year,20,#000000&',
        'data lines with comma in label' );
}

{
    my $axis_label = Chart::OFC::AxisLabel->new( label      => 'Months',
                                                 text_color => 'red',
                                                 text_size  => 10,
                                               );
    is( $axis_label->_ofc_data_lines('x'), '&x_legend=Months,10,#FF0000&',
        'data lines with all attributes set' );
}
