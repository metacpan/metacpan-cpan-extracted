#!/usr/bin/env perl

use 5.016;
use warnings;

use Getopt::Long;
use Chart::GGPlot qw(:all);
use Data::Frame::Examples qw(mtcars);

my $save_as;
GetOptions( 'o=s' => \$save_as );

my $mtcars2 = mtcars();
$mtcars2->set( 'vs',   factor( $mtcars2->at('vs') ) );
$mtcars2->set( 'am',   factor( $mtcars2->at('am') ) );
$mtcars2->set( 'cyl',  factor( $mtcars2->at('cyl') ) );
$mtcars2->set( 'gear', factor( $mtcars2->at('gear') ) );

my $p = ggplot( data => $mtcars2 )
  ->geom_point( mapping => aes( x => 'wt', y => 'mpg', color => 'gear' ) )
  ->labs(
    title    => 'Fuel economy declines as weight increases',
    subtitle => '(1973-1974)',
    tag      => 'Figure 1',
    x        => 'Weight (1000 lbs)',
    y        => 'Fuel economy (mpg)',
    color    => 'Gears',
  )
  ->theme_linedraw();

if ( defined $save_as ) {
    $p->save($save_as);
}
else {
    $p->show();
}

