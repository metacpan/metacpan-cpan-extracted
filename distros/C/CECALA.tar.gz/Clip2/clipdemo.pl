#!/usr/bin/perl -w

#use strict;
use lib ('.');
use Clip;
use Math::Trig;
use Tk;
use Tk::Canvas;
use Getopt::Std;

my $width = 500;
my $height = 500;

getopts( 'w:h:' );
if( $opt_w ) { $width = $opt_w ; }
if( $opt_h ) { $height = $opt_h ; }

my ($r,$pi,$alpha,$phi0,$phi,$x1,$y1,$x2,$y2,$d,$xmin,$xmax,$ymin,$ymax);
my $top 	= MainWindow->new();
print ("w = $width h = $height \n");
my $can = $top->Canvas( -width => $width, -height=> $height )->form();
my $x_center = $can->reqwidth()/2.0;
my $y_center = $can->reqheight()/2.0;
my $r_max = $can->reqwidth()/2;
my $clip = new Clip ( 10, 10, $width, $height, $can, 'tag' );
my $x_max = $clip->getxmax();
my $y_max = $clip->getymax();
my $x_min = $clip->getxmin();
my $y_min = $clip->getymin();

$pi 	= 4.0*atan(1.0);
$alpha 	= 72.0*$pi/180.0;
$phi0	= 0.0;
$d = 0.1 * $r_max;
$xmin = $x_min + $d;
$xmax = $x_max - $d;
$ymin = $y_min + $d;
$ymax = $y_max - $d;

$can->create( 'line', $xmin, $ymin, $xmax, $ymin ); 
$can->create( 'line', $xmax, $ymin, $xmax, $ymax ); 
$can->create( 'line', $xmax, $ymax, $xmin, $ymax ); 
$can->create( 'line', $xmin, $ymax, $xmin, $ymin ); 
$clip->setclipboundaries( $xmin, $ymin, $xmax, $ymax, $can ); 
for( my $j=0; $j<=20; $j++ ) {
	$r = $j * $d;
	$x2 = $x_center + $r * cos($phi0);
	$y2 = $y_center + $r * sin($phi0);
	for( my $i=0; $i<=5; $i++ ) {
		$phi = $phi0 + $i * $alpha;
		$x1 = $x2;
		$y1 = $y2;
		$x2 = $x_center + $r * cos($phi);
		$y2 = $y_center + $r * sin($phi);
		$clip->clipdraw( $x1, $y1, $x2, $y2 );
	} #end for loop
} # end for loop
MainLoop;
