#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use PDL::Core qw(pdl);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $datapoly = Data::Frame->new(
    columns => [
        id => factor( [ map { ($_) x 4 } qw(1.1 2.1 1.2 2.2 1.3 2.3) ] ),
        value => pdl( [ map { ($_) x 4 } qw(3 3.1 3.1 3.2 3.15 3.5) ] ),
        x     => pdl(
            2,   1,   1.1, 2.2, 1,   0,   0.3, 1.1, 2.2, 1.1, 1.2, 2.5,
            1.1, 0.3, 0.5, 1.2, 2.5, 1.2, 1.3, 2.7, 1.2, 0.5, 0.6, 1.3
        ),
        y => pdl(
            -0.5, 0,   1,   0.5, 0,   0.5, 1.5, 1,   0.5, 1,   2.1, 1.7,
            1,    1.5, 2.2, 2.1, 1.7, 2.1, 3.2, 2.8, 2.1, 2.2, 3.3, 3.2
        ),
    ]
);

my $p = ggplot(
    data    => $datapoly,
    mapping => aes( x => 'x', y => 'y' )
)->geom_polygon( mapping => aes( fill => 'value', group => 'id' ) );

if ( defined $save_as ) {
    $p->save($save_as);
}
else {
    $p->show();
}

