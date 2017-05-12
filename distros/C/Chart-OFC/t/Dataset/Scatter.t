use strict;
use warnings;

use Test::More tests => 6;

use Chart::OFC;

{
    eval { Chart::OFC::Dataset::Scatter->new( values => [ ] ) };
    like( $@, qr/cannot be empty/,
          'Chart::OFC::Dataset::Scatter constructor requires some values' );
}

{
    eval { Chart::OFC::Dataset::Scatter->new( values => [ [], [] ] ) };
    like( $@, qr/cannot be empty/,
          'Chart::OFC::Dataset::Scatter constructor requires some values' );
}

{
    my $scatter =
      Chart::OFC::Dataset::Scatter->new
          ( values => [ [ 1, 2, 3 ], [ 4, 5, 6 ] ],
          );

    my @data = ( '&scatter=2,#000000&', '&values=[1,2,3],[4,5,6]&', );

    is_deeply( [ $scatter->_ofc_data_lines() ],
               \@data,
               'check _ofc_data_lines output - no label' );
}

{
    my $scatter =
        Chart::OFC::Dataset::Scatter->new
            ( values      => [ [ 6, 5, 4 ], [ 3, 2, 1 ] ],
              label       => 'Intensity',
              text_size   => 5,
              circle_size => 7,
            );
    my @data = ( '&scatter=2,#000000,Intensity,5,7&', '&values=[6,5,4],[3,2,1]&', );

    is_deeply( [ $scatter->_ofc_data_lines() ],
               \@data,
               'check _ofc_data_lines output - labeled' );
}

{
    my $scatter =
        Chart::OFC::Dataset::Scatter->new
            ( values      => [ [ 1, 2, 3 ] ],
              label       => 'Intensity',
              text_size   => 5,
              color       => 'red',
              circle_size => 8,
            );
    my @data = ( '&scatter=2,#FF0000,Intensity,5,8&', '&values=[1,2,3]&', );

    is_deeply( [ $scatter->_ofc_data_lines() ],
               \@data,
               'check _ofc_data_lines output - all scatter parameters' );
}

{
    my $scatter =
        Chart::OFC::Dataset::Scatter->new
            ( values      => [ [ 1, 2, 3 ], [ 3, 2, 1 ] ],
              width       => 1,
              label       => 'Intensity',
              text_size   => 5,
              color       => 'red',
              circle_size => 8,
            );

    my @data = ( '&scatter=1,#FF0000,Intensity,5,8&', '&values=[1,2,3],[3,2,1]&', );

    is_deeply( [ $scatter->_ofc_data_lines() ],
               \@data,
               'check _ofc_data_lines output - all parameters again' );
}

