use strict;
use warnings;

use Test::More tests => 2;

use Chart::OFC;


{
    my $bar = Chart::OFC::Dataset::FadeBar->new( values    => [ 1, 2 ],
                                                 label     => 'Things',
                                               );

    my @data = ( '&bar_fade=80,#999999,Things,10&',
                 '&values=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines() ], \@data,
               'check _ofc_data_lines output' );
}

{
    my $bar = Chart::OFC::Dataset::FadeBar->new( values     => [ 1, 2 ],
                                                 label      => 'Things',
                                                 fill_color => 'red',
                                                 text_size  => 26,
                                                 opacity    => 50,
                                               );

    my @data = ( '&bar_fade_2=50,#FF0000,Things,26&',
                 '&values_2=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines(2) ], \@data,
               'check _ofc_data_lines output' );
}
