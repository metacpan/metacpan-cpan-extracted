use strict;
use warnings;

use Test::More tests => 4;

use Chart::OFC;

{
    my $bar = Chart::OFC::Dataset::LineWithDots->new( values => [ 1, 2 ],
                                                    );
    my @data = ( '&line_dot=2,#000000&',
                 '&values=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines() ], \@data,
               'check _ofc_data_lines output - no label' );
}

{
    my $bar = Chart::OFC::Dataset::LineWithDots->new( values    => [ 1, 2 ],
                                                      label     => 'Intensity',
                                                      text_size => 5,
                                                      dot_size  => 7,
                                                    );
    my @data = ( '&line_dot=2,#000000,Intensity,5,7&',
                 '&values=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines() ], \@data,
               'check _ofc_data_lines output - labeled' );
}

{
    my $bar = Chart::OFC::Dataset::LineWithDots->new( values    => [ 1, 2 ],
                                                      label     => 'Intensity',
                                                      text_size => 5,
                                                      color     => 'red',
                                                      dot_size  => 8,
                                                    );
    my @data = ( '&line_dot=2,#FF0000,Intensity,5,8&',
                 '&values=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines() ], \@data,
               'check _ofc_data_lines output - all parameters' );
}

{
    my $bar = Chart::OFC::Dataset::LineWithDots->new( values     => [ 1, 2 ],
                                                      label      => 'Intensity',
                                                      text_size  => 5,
                                                      color      => 'red',
                                                      dot_size   => 8,
                                                      solid_dots => 0,
                                                    );
    my @data = ( '&line_hollow=2,#FF0000,Intensity,5,8&',
                 '&values=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines() ], \@data,
               'check _ofc_data_lines output - all parameters & hollow dots' );
}
