use strict;
use warnings;

use Test::More tests => 3;

use Chart::OFC;

{
    my $bar = Chart::OFC::Dataset::Area->new( values => [ 1, 2 ],
                                            );
    my @data = ( '&area_hollow=2,5,80,#000000&',
                 '&values=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines() ], \@data,
               'check _ofc_data_lines output - no label' );
}

{
    my $bar = Chart::OFC::Dataset::Area->new( values    => [ 1, 2 ],
                                              label     => 'Intensity',
                                              text_size => 5,
                                            );
    my @data = ( '&area_hollow=2,5,80,#000000,Intensity,5&',
                 '&values=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines() ], \@data,
               'check _ofc_data_lines output - labeled' );
}

{
    my $bar = Chart::OFC::Dataset::Area->new( values     => [ 1, 2 ],
                                              label      => 'Intensity',
                                              text_size  => 5,
                                              color      => 'red',
                                              dot_size   => 8,
                                              opacity    => 60,
                                              fill_color => 'blue',
                                            );
    my @data = ( '&area_hollow=2,8,60,#FF0000,Intensity,5,#0000FF&',
                 '&values=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines() ], \@data,
               'check _ofc_data_lines output - all parameters' );
}
