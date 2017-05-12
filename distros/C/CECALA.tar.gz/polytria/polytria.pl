#!/usr/bin/perl -w

use strict;
use Tk;
use Tk::Canvas;
use Getopt::Std;
use Math::Trig;
use lib ('../Vector2D');
use lib ('../Triangul');
use lib ('../Viewport');
use Vector2D;
use Triangul;
use Viewport;
use constant EPS => 1e-6;

my $width = 500;
my $height = 500;
my $background = 'blue';
my $fill = 'yellow';
my %opts = ();
getopts( 'w:h:b:f:', \%opts );
if( $opts{w} ) { $width = $opts{w} ; }
if( $opts{h} ) { $height = $opts{h} ; }
if( $opts{b} ) { $background = $opts{b} ; }
if( $opts{f} ) { $fill = $opts{f} ; }

my $vp = new Viewport();
my $pidiv180 = atan(1)/45;
my $top 	= MainWindow->new();
my $frame 	= $top->Frame();
my $can = $top->Canvas( -width => $width, -height=> $height, -background=>$background );
my $x_max 	= $width;
my $y_max 	= $height;
my $x_min 	= 5;
my $y_min 	= 5;
my $x_center 	= $can->reqwidth()/2.0;
my $y_center 	= $can->reqheight()/2.0;
my $r_max 	= $can->reqwidth()/2;

$can->packAdjust( -side => 'left', -fill => 'both', -delay => 1 );
$frame->pack( -side 	=> 'left', -fill 	=> 'y', -expand => 'y', -anchor => 'w' );

my $doButton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "Draw", 
	-command	=> \&doit  )->pack(  anchor => 'w' );

my $clearButton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "Clear", 
	-command	=> \&clear  )->form( 
	-left => [$doButton,0] );

my @p = (); # array of Vector2Ds
my $i = 0;
my $n = <>;
my @nrspol = ( 0..$n-1 );
my @nrs = ();
while(<>) {
	chomp;
	my ( $x, $y ) = split /,/;
	push ( @p, new Vector2D( $x, $y ) );
	$vp->updatewindowboundaries( $x, $y );
}
$vp->viewportboundaries ( $x_min, $x_max, $y_min, $y_max, 0.9 );
$can->create ( 'line', $x_min, $y_min, $x_min, $y_max );
$can->create ( 'line', $x_min, $y_max, $x_max, $y_max );
$can->create ( 'line', $x_max, $y_max, $x_max, $y_min );
$can->create ( 'line', $x_max, $y_min, $x_min, $y_min );
my $rc = &Triangul::triangul ( \@nrspol, $n, \@nrs, \&orienta, \@p );

if( $rc == -1 ) { die "Bad poly\n"; }
if( $rc == -2 ) { die "out of mem\n"; }
&drawPoly ( @p );

&drawTriangles( \@p, \@nrs, $rc );


MainLoop;

sub drawPoly {
	my @p = @_; #Array of  Vector2Ds

	my $start_point = pop( @p );
	my $first_point = $start_point;
	while( my $end_point = pop( @p ) ) {
		$can->create( 'line', 
			$vp->x_viewport($start_point->getx()),
			$vp->y_viewport($start_point->gety()),
			$vp->x_viewport($end_point->getx()),
			$vp->y_viewport($end_point->gety()),
			-fill => $fill);
		$start_point = $end_point;
	}
#	$can->create( 'line', 
#		$vp->x_viewport($first_point->getx()),
#		$vp->y_viewport($first_point->gety()),
#		$vp->x_viewport($start_point->getx()),
#		$vp->y_viewport($start_point->gety()),
#		-fill => $fill);
#	
} #end drawPoly


sub drawTriangles {
	my $refp    	= shift; #ref to an array
	my $refnrs  	= shift; #ref to an array
	my $m   	= shift; #scalar

	my @p 	= @$refp;
	my @nrs = @$refnrs;

	my $Centroid = new Vector2D( 0, 0 );
	# my $A  = new Vector2D( 0, 0 );
	# my $B  = new Vector2D( 0, 0 );
	# my $C  = new Vector2D( 0, 0 );
	my $A1 = new Vector2D( 0, 0 );
	my $B1 = new Vector2D( 0, 0 );
	my $C1 = new Vector2D( 0, 0 );
	for( my $j=0; $j<$m; $j++ ) {
		my $A = $p[$nrs[$j]->{A}];
		my $B = $p[$nrs[$j]->{B}];
		my $C = $p[$nrs[$j]->{C}];
		$Centroid = 0.3333333 * ( $A + $B + $C );
		$A1 = $Centroid + 0.9 * ( $A - $Centroid );
		$B1 = $Centroid + 0.9 * ( $B - $Centroid );
		$C1 = $Centroid + 0.9 * ( $C - $Centroid );
		$can->create( 'line' ,
			$vp->x_viewport($A1->getx()), $vp->y_viewport($A1->gety()),
			$vp->x_viewport($B1->getx()), $vp->y_viewport($B1->gety()),
			-fill => 'red');
			#-fill => $fill);
		$can->create( 'line' ,
			$vp->x_viewport($B1->getx()), $vp->y_viewport($B1->gety()),
			$vp->x_viewport($C1->getx()), $vp->y_viewport($C1->gety()),
			-fill => 'red');
			#-fill => $fill);
		$can->create( 'line' ,
			$vp->x_viewport($C1->getx()), $vp->y_viewport($C1->gety()),
			$vp->x_viewport($A1->getx()), $vp->y_viewport($A1->gety()),
			-fill => 'red');
			#-fill => $fill);
	}
} #end drawTriangles

sub orienta {
	my ( $Pnr, $Qnr, $Rnr, $PP ) = @_;
	my $A = new Vector2D( 0, 0 );
	my $B = new Vector2D( 0, 0 );
	$A = $PP->[$Qnr]->minus( $PP->[$Pnr] );
	$B = $PP->[$Rnr] - $PP->[$Pnr];
	my $determinant = $A->getx() * $B->gety() - $A->gety() * $B->getx();
	if ($determinant < (-1 * EPS) ) { return -1; }
	if ($determinant > EPS ) { return 1; }
	if ($determinant < EPS ) { return 0; }
	return 0;
}
