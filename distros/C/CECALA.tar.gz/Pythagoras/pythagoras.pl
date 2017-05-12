#!/usr/bin/perl -w

use strict;

use Tk;
use Tk::Canvas;
use lib( '../Vector2D' );
use lib( '../Viewport' );
use Vector2D;
use Viewport;

my $width = 700;
my $height = 700;

my $top = MainWindow->new();
my $can = $top->Canvas( -width => 500, -height=> 500 )->form();

my $x_max 	= $width;
my $y_max 	= $height;
my $x_min 	= 5;
my $y_min 	= 5;

my $vp = new Viewport();

$vp->updatewindowboundaries( 20, 10 );
$vp->updatewindowboundaries( 0, -5 );
$vp->viewportboundaries ( $x_min, $x_max, $y_min, $y_max, 0.9 );

sub pythagoras {
	my $A = shift; # Vector2D
	my $B = shift; # Vector2D
	my $n = shift; # depth of recursion
#	$vp->updatewindowboundaries( $A->getx(), $A->gety() );
#print "update (" . $A->getx() . ", " . $A->gety() . ")\n";
#	$vp->updatewindowboundaries( $B->getx(), $B->gety() );
#	$vp->viewportboundaries ( $x_min, $x_max, $y_min, $y_max, 0.9 );

	if( $n > 0 ) {
		my $C = $B + new Vector2D( 
				$A->gety() - $B->gety(), 
				$B->getx() - $A->getx()
			);
		my $D = $A + $C - $B;
		my $E = $D + 0.5 * ( $C - $A );
		$can->create( 'line', 
			$vp->x_viewport($A->getx()), 
			$vp->y_viewport($A->gety()),
			$vp->x_viewport($B->getx()), 
			$vp->y_viewport($B->gety()) );
		$can->create( 'line', 
			$vp->x_viewport($B->getx()), 
			$vp->y_viewport($B->gety()),
			$vp->x_viewport($C->getx()), 
			$vp->y_viewport($C->gety()) );
		$can->create( 'line', 
			$vp->x_viewport($C->getx()), 
			$vp->y_viewport($C->gety()),
			$vp->x_viewport($D->getx()), 
			$vp->y_viewport($D->gety()) );
		$can->create( 'line', 
			$vp->x_viewport($D->getx()), 
			$vp->y_viewport($D->gety()),
			$vp->x_viewport($A->getx()), 
			$vp->y_viewport($A->gety()) );
		&pythagoras ( $D, $E, $n-1 );
		&pythagoras ( $E, $C, $n-1 );
	}
}

my $A = new Vector2D( 4.2, 0.3 );
my $B = new Vector2D( 5.8, 0.3 );
#my $n = 8;
my $n = 12;
&pythagoras ( $A, $B, $n );
MainLoop;
