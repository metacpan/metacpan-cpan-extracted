use strict;
use warnings;

use Test::More tests => 6;

use Chart::OFC::Dataset;
use Chart::OFC::Pie;

{
    my $set = Chart::OFC::Dataset->new( values => [ 1..10 ] );

    eval { Chart::OFC::Pie->new( dataset => $set ) };
    like( $@, qr/\Q(labels) is required/, 'labels is required for constructor' );

    eval { Chart::OFC::Pie->new( dataset => $set, labels => [ 'a'..'j' ], slice_colors => [] ) };
    like( $@, qr/\Qpass the type constraint/,
          'cannot pass an empty array ref for slice_colors' );

    eval { Chart::OFC::Pie->new( dataset => $set, labels => [ 'a'..'j' ], slice_colors => [ 'not a color' ] ) };
    like( $@, qr/\Qpass the type constraint/,
          'cannot pass a bad color in slice_colors' );
}

{
    my $set = Chart::OFC::Dataset->new( values => [ 1..10 ] );

    my $pie = Chart::OFC::Pie->new( title => 'Pie Test', dataset => $set, labels => [ 'a'..'j' ] );
    is_deeply( $pie->slice_colors(),
               [ '#FF0000', '#0000FF', '#00FF00', '#FFFF00', '#FFA500', '#A020F0', '#000000' ],
               'check default slice colors',
             );

    my @data = ( '&title=Pie Test,{ font-size: 25px }&',
                 '&pie=80,#000000,{ color: #000000 }&',
                 '&pie_labels=a,b,c,d,e,f,g,h,i,j&',
                 '&colours=#FF0000,#0000FF,#00FF00,#FFFF00,#FFA500,#A020F0,#000000&',
                 '&values=1,2,3,4,5,6,7,8,9,10&',
               );

    my $data = join '', map { $_ . "\r\n" } @data;
    is( $pie->as_ofc_data(), $data,
        'check as_ofc_data output' );
}

{
    my @links = map { "http://example.com/$_" } 1..10;
    my $set = Chart::OFC::Dataset->new( values => [ 1..10 ],
                                        links  => \@links,
                                      );

    my $pie = Chart::OFC::Pie->new( title       => 'Pie Test',
                                    dataset     => $set,
                                    labels      => [ 'a'..'j' ],
                                    label_style => 'font-size: 12pt',
                                  );

    my $links = join ',', @links;
    my @data = ( '&title=Pie Test,{ font-size: 25px }&',
                 '&pie=80,#000000,{ font-size: 12pt }&',
                 '&pie_labels=a,b,c,d,e,f,g,h,i,j&',
                 '&colours=#FF0000,#0000FF,#00FF00,#FFFF00,#FFA500,#A020F0,#000000&',
                 '&values=1,2,3,4,5,6,7,8,9,10&',
                 '&links=' . $links . '&',
               );

    my $data = join '', map { $_ . "\r\n" } @data;
    is( $pie->as_ofc_data(), $data,
        'check as_ofc_data output' );
}
