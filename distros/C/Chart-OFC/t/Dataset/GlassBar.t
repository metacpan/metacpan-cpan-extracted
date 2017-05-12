use strict;
use warnings;

use Test::More tests => 2;

use Chart::OFC;


{
    my $bar = Chart::OFC::Dataset::GlassBar->new( values    => [ 1, 2 ],
                                                  label     => 'Things',
                                                  text_size => 10,
                                                );

    my @data = ( '&bar_glass=80,#999999,#000000,Things,10&',
                 '&values=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines() ], \@data,
               'check _ofc_data_lines output' );
}

{
    my $bar = Chart::OFC::Dataset::GlassBar->new( values        => [ 1, 2 ],
                                                  label         => 'Things',
                                                  fill_color    => 'blue',
                                                  outline_color => 'red',
                                                  text_size     => 26,
                                                  opacity       => 50,
                                                );

    my @data = ( '&bar_glass_2=50,#0000FF,#FF0000,Things,26&',
                 '&values_2=1,2&',
               );

    is_deeply( [ $bar->_ofc_data_lines(2) ], \@data,
               'check _ofc_data_lines output' );
}
