use strict;
use warnings;

use Test::More tests => 4;

use Chart::OFC;

{
    my $hlc =
        Chart::OFC::Dataset::HighLowClose->new
            ( values => [ [ 1, 2, 3 ], [ 4, 5, 6 ] ],
            );

    my @data = ( '&hlc=80,2,#000000&', '&values=[1,2,3],[4,5,6]&', );

    is_deeply( [ $hlc->_ofc_data_lines() ],
               \@data,
               'check _ofc_data_lines output - no label' );
}

{
    my $hlc =
        Chart::OFC::Dataset::HighLowClose->new
            ( values => [ [ 6, 5, 4 ], [ 3, 2, 1 ] ],
              label => 'Intensity',
              text_size => 5,
              opacity   => 70,
            );

    my @data = ( '&hlc=70,2,#000000,Intensity,5&', '&values=[6,5,4],[3,2,1]&', );

    is_deeply( [ $hlc->_ofc_data_lines() ],
               \@data,
               'check _ofc_data_lines output - labeled' );
}

{
    my $hlc =
        Chart::OFC::Dataset::HighLowClose->new
            ( values => [ [ 1, 2, 3 ] ],
              label => 'Intensity',
              text_size => 5,
              color     => 'red',
              opacity   => 80,
            );

    my @data = ( '&hlc=80,2,#FF0000,Intensity,5&', '&values=[1,2,3]&', );

    is_deeply( [ $hlc->_ofc_data_lines() ],
               \@data,
               'check _ofc_data_lines output - all hlc parameters' );
}

{
    my $hlc =
        Chart::OFC::Dataset::HighLowClose->new
            ( values => [ [ 1, 2, 3 ], [ 3, 2, 1 ] ],
              width  => 1,
              label  => 'Intensity',
              text_size => 5,
              color     => 'red',
              opacity   => 80,
            );

    my @data = ( '&hlc=80,1,#FF0000,Intensity,5&', '&values=[1,2,3],[3,2,1]&', );

    is_deeply( [ $hlc->_ofc_data_lines() ],
               \@data,
               'check _ofc_data_lines output - all parameters again' );
}

