#!/usr/bin/perl -w

use strict;
use Tk;
use Tk::Canvas;
use Getopt::Std;

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

sub set_of_squares( $$$$$$ ) {
	my( $c, $xA, $yA, $m, $p, $a ) = @_;
	my $xB = $xA + $a;
	my $yB = $yA;
	my $xC = $xB;
	my $yC = $yA + $a;
	my $xD = $xA;
	my $yD = $yC;
	my ($xA1,$xB1,$xC1,$xD1);
	my ($yA1,$yB1,$yC1,$yD1);
	my $q = 1 - $p; 

	for( my $i=0; $i<$m; $i++ ) {
		$c->create( 'line' , $xA , $yA , $xB , $yB, -fill=>$fill );
		$c->create( 'line' , $xB , $yB , $xC , $yC, -fill=>$fill );
		$c->create( 'line' , $xC , $yC , $xD , $yD, -fill=>$fill );
		$c->create( 'line' , $xD , $yD , $xA , $yA, -fill=>$fill );
		$xA1 = $p*$xA+$q*$xB; $yA1 = $p*$yA+$q*$yB;
		$xB1 = $p*$xB+$q*$xC; $yB1 = $p*$yB+$q*$yC;
		$xC1 = $p*$xC+$q*$xD; $yC1 = $p*$yC+$q*$yD;
		$xD1 = $p*$xD+$q*$xA; $yD1 = $p*$yD+$q*$yA;
		$xA = $xA1; $xB = $xB1; $xC = $xC1; $xD = $xD1;
		$yA = $yA1; $yB = $yB1; $yC = $yC1; $yD = $yD1;
	}
}

my $top 	= MainWindow->new();
my $frame 	= $top->Frame();
my $can = $top->Canvas( 
	-width => $width, 
	-height=> $height, 
	-background=>$background );

my $M = 10;  
my $N = 10;  
my $L = 0.0; 
sub incM { $M++; }
sub incN { $N++; }
sub incL { $L+= 0.01; if ($L>1.0) { $L=0;}}
sub clear{ $can->delete( 'all' ); }
sub doit {
	my $r_max = $can->reqwidth();
	my $a = 1.9 * $r_max/$N;
	my $x_center = $can->reqwidth()/2.0;
	my $y_center = $can->reqheight()/2.0;
	my $halfN = $N/2.0;
	for( my $i=0; $i<$N; $i++ ) {
		for( my $j=0; $j<$N; $j++ ) {
			&set_of_squares (
				$can,
				$x_center + ( $i - $halfN ) * $a,
				$y_center + ( $j - $halfN ) * $a,
				$M,
				(($i+$j)%2 ? $L : 1-$L),
				$a
			);
		}
	}
}

$can->packAdjust( -side => 'left', -fill => 'both', -delay => 1 );
$frame->pack( 
	-side 	=> 'left', 
	-fill 	=> 'y', 
	-expand => 'y', 
	-anchor => 'w' );

my $mbutton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "m = ", 
	-command	=> \&incM  )->pack( anchor => 'w' );
my $mentry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$M)->form( 
	-left => [$mbutton,0] );

my $nbutton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "n = ", 
	-command	=> \&incN  )->form( 
	-top => [$mbutton,0] );
my $nentry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$N)->form( 
	-left => [$nbutton,0],
	-top => [$mbutton,0] );

my $Lbutton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "l = ", 
	-command	=> \&incL  )->form( 
	-top => [$nbutton,0] );
my $Lentry = $frame->Entry( 
	-width 	=> 10,
	-textvariable 	=> \$L) ->form( 
	-left => [$Lbutton,0],
	-top => [$nbutton,0] );

my $doButton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "Draw", 
	-command	=> \&doit  )->form( 
	-top => [$Lbutton,0] );

my $clearButton = $frame->Button( 
	-relief 	=> "groove", 
	-text 		=> "Clear", 
	-command	=> \&clear  )->form( 
	-top 		=> [$Lbutton,0],
	-left 		=> [$doButton,0] );
MainLoop;
