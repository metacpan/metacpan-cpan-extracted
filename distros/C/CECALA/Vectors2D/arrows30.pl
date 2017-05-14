#!/usr/bin/perl -w

use strict;
use lib ('.');
use Vectors2D;

use Tk;
use Tk::Canvas;
use Math::Trig;

my $top = MainWindow->new();
my $can = $top->Canvas( -width => 500, -height=> 500 )->form();
my $x_center = $can->reqwidth()/2.0;
my $y_center = $can->reqheight()/2.0;

my @P = ( 
	new Vector2D( 0, 7), 
	new Vector2D( 0,-7), 
	new Vector2D(-2, 0), 
	new Vector2D( 2, 0)
);
my $pi	= 4 * atan(1.0);
my $phi = $pi/15.0;

my $cosphi = cos ( $phi );
my $sinphi = sin ( $phi );
my $center = new Vector2D( $x_center, $y_center );
my $r_max = $can->reqwidth()/2;
my $start = $center->plus( new Vector2D( 0.9 * $r_max, 0 ) );

for ( my $j=0; $j<4; $j++ ) {
#	$P[$j]->scale( $r_max );
	$P[$j]->scale( 3 );
	$P[$j]->incr( $start ); 
}

for ( my $i=0; $i<30; $i++ ) {
	for( my $j=0; $j<4; $j++ ) {
		$P[$j] = $P[$j]->rotate( $center, $cosphi, $sinphi );
	}
	$can->create( 'line', 
		$P[0]->getx(), $P[0]->gety(), 
		$P[1]->getx(), $P[1]->gety());
	$can->create( 'line', 
		$P[1]->getx(), $P[1]->gety(), 
		$P[2]->getx(), $P[2]->gety());
	$can->create( 'line', 
		$P[2]->getx(), $P[2]->gety(), 
		$P[3]->getx(), $P[3]->gety());
	$can->create( 'line', 
		$P[3]->getx(), $P[3]->gety(), 
		$P[1]->getx(), $P[1]->gety());
}

MainLoop;
