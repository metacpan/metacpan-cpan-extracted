use strict;
use warnings;

use Test::More tests => 5;

use Chart::OFC;


eval { Chart::OFC::Dataset::Bar->new( values => [ 1, 2 ], labels => [ 'a', 'b' ], text_size => 0 ) };
like( $@, qr/\Q(text_size) does not pass the type constraint/,
      'text_size cannot be 0' );

eval { Chart::OFC::Dataset::Bar->new( values => [ 1, 2 ], labels => [ 'a', 'b' ], text_size => -2 ) };
like( $@, qr/\Q(text_size) does not pass the type constraint/,
      'text_size cannot be -2' );

{
    my $bar = Chart::OFC::Dataset::Bar->new( values => [ 1, 2 ],
                                           );
    my @data = ( '&bar=80,#999999&',
                 '&values=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines() ], \@data,
               'check _ofc_data_lines output - no label' );
}

{
    my $bar = Chart::OFC::Dataset::Bar->new( values => [ 1, 2 ],
                                             label  => 'Things',
                                           );

    my @data = ( '&bar=80,#999999,Things,10&',
                 '&values=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines() ], \@data,
               'check _ofc_data_lines output - labeled' );
}

{
    my $bar = Chart::OFC::Dataset::Bar->new( values     => [ 1, 2 ],
                                             label      => 'Things',
                                             fill_color => 'red',
                                             text_size  => 26,
                                             opacity    => 50,
                                           );

    my @data = ( '&bar_2=50,#FF0000,Things,26&',
                 '&values_2=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines(2) ], \@data,
               'check _ofc_data_lines output - all parameters' );
}
