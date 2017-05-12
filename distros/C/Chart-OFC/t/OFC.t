use strict;
use warnings;

use Test::More tests => 2;

use Chart::OFC;


my $chart =
    Chart::OFC->new( title => 'Test Title',
                   );

{
    my @data = ( '&title=Test Title,{ font-size: 25px }&',
               );

    my $data = join '', map { $_ . "\r\n" } @data;
    is( $chart->as_ofc_data(), $data,
        'check as_ofc_data output - minimal parameters' );
}

{
    my $chart =
        Chart::OFC->new( title               => 'Test Title',
                         title_style         => 'font-size: 20px',
                         bg_color            => '#FF0000',
                         tool_tip            => '#key#: #val#',
                       );

    my @data = ( '&title=Test Title,{ font-size: 20px }&',
                 '&tool_tip=#key#: #val#&',
                 '&bg_colour=#FF0000&',
               );

    my $data = join '', map { $_ . "\r\n" } @data;
    is( $chart->as_ofc_data(), $data,
        'check as_ofc_data output - all parameters' );
}
