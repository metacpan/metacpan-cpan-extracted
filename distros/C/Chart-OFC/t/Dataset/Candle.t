use strict;
use warnings;

use Test::More tests => 4;

use Chart::OFC;

{
    my $candle =
        Chart::OFC::Dataset::Candle->new
            ( values => [ [ 5, 4, 3, 2 ], [ 9, 8, 6, 5 ] ],
            );

    my @data = ( '&candle=80,2,#000000&', '&values=[5,4,3,2],[9,8,6,5]&', );

    is_deeply( [ $candle->_ofc_data_lines() ],
               \@data,
               'check _ofc_data_lines output - no label' );
}

{
    my $candle =
        Chart::OFC::Dataset::Candle->new
            ( values => [ [ 6, 5, 4, 3 ], [ 7, 3, 2, 1 ] ],
              label => 'Intensity',
              text_size => 5,
              opacity   => 70,
            );

    my @data = ( '&candle=70,2,#000000,Intensity,5&', '&values=[6,5,4,3],[7,3,2,1]&', );

    is_deeply( [ $candle->_ofc_data_lines() ],
               \@data,
               'check _ofc_data_lines output - labeled' );
}

{
    my $candle =
        Chart::OFC::Dataset::Candle->new
            ( values => [ [ 41, 32, 23, 11 ] ],
              label => 'Intensity',
              text_size => 5,
              color     => 'red',
              opacity   => 80,
            );

    my @data = ( '&candle=80,2,#FF0000,Intensity,5&', '&values=[41,32,23,11]&', );

    is_deeply( [ $candle->_ofc_data_lines() ],
               \@data,
               'check _ofc_data_lines output - all candle parameters' );
}

{
    my $candle =
        Chart::OFC::Dataset::Candle->new
            ( values => [ [ 11, 10, 9, 1 ], [ 14, 12, 9, 3 ] ],
              width  => 1,
              label  => 'Intensity',
              text_size => 5,
              color     => 'red',
              opacity   => 80,
            );

    my @data = ( '&candle=80,1,#FF0000,Intensity,5&', '&values=[11,10,9,1],[14,12,9,3]&', );

    is_deeply( [ $candle->_ofc_data_lines() ],
               \@data,
               'check _ofc_data_lines output - all parameters again' );
}

