#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use PDL::Primitive qw(random which);
use PDL::Ufunc ();
use Data::Frame::Examples qw(mtcars);

srand(0);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $mtcars = mtcars();
my $miss   = factor( ( random( $mtcars->nrow ) * 6 )->floor );
$miss = $miss->setbadif( $miss == 5 );

my $p = ggplot(
    data    => $mtcars,
    mapping => aes(
        x => 'mpg',
        y => 'wt'
    )
)->geom_point( mapping => aes( color => '$miss' ) )
 ->scale_color_hue( na_value => 'black' );

if ( defined $save_as ) {
    $p->save($save_as);
}
else {
    $p->show();
}

