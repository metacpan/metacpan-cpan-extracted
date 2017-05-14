#!/usr/bin/perl -w

use strict;

use Tk;
use Tk::Canvas;

my $top = MainWindow->new();
my $can = $top->Canvas( -width => 500, -height=> 500 )->pack();
my ($xA, $xB, $xC, $xD);
my ($yA, $yB, $yC, $yD);
my ($xA1,$xB1,$xC1,$xD1);
my ($yA1,$yB1,$yC1,$yD1);
my $q = 0.05; 
my $p = 1.0 - $q;
my $r_max = $can->reqwidth();
my $x_center = $can->reqwidth()/2.0;
my $y_center = $can->reqheight()/2.0;
my $r = 0.95 * $r_max;

$xA = $xD = $x_center - $r;
$xB = $xC = $x_center + $r;
$yA = $yB = $y_center - $r;
$yD = $yC = $y_center + $r;

for( my $i=0; $i<75; $i++ ) {
	$can->create( 'line' , $xA , $yA , $xB , $yB );
	$can->create( 'line' , $xB , $yB , $xC , $yC );
	$can->create( 'line' , $xC , $yC , $xD , $yD );
	$can->create( 'line' , $xD , $yD , $xA , $yA );
	$xA1 = $p*$xA+$q*$xB; $yA1 = $p*$yA+$q*$yB;
	$xB1 = $p*$xB+$q*$xC; $yB1 = $p*$yB+$q*$yC;
	$xC1 = $p*$xC+$q*$xD; $yC1 = $p*$yC+$q*$yD;
	$xD1 = $p*$xD+$q*$xA; $yD1 = $p*$yD+$q*$yA;
	$xA = $xA1; $xB = $xB1; $xC = $xC1; $xD = $xD1;
	$yA = $yA1; $yB = $yB1; $yC = $yC1; $yD = $yD1;
print ("$i $xA , $yA , $xB , $yB\n" );
}

MainLoop;
