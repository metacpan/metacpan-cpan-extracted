#!/usr/bin/perl -w

use strict;
use Tk;
use Tk::Canvas;
use Getopt::Std;

my $width = 500;
my $height = 500;
my $background = 'blue';
my $fill = 'yellow';
my $k 	= 25;
my %opts = ();
getopts( 'k:w:h:b:f:', \%opts );
if( $opts{w} ) { $width = $opts{w} ; }
if( $opts{h} ) { $height = $opts{h} ; }
if( $opts{b} ) { $background = $opts{b} ; }
if( $opts{f} ) { $fill = $opts{f} ; }
if( $opts{k} ) { $k = $opts{k} ; }

# $canvas->createGrid(x1, y1, x2, y2, ?option, value, option, value, ...?)
my $top = MainWindow->new();
my $can = $top->Canvas( -width => $width, -height=> $height )->pack();

my $Y__max = $height;
my $X__max = $width;
my $n = ($Y__max - 100)/$k;
my $N = $n * $k;
my $xmargin = ( $X__max -$N)/2;
my $ymargin = ( $Y__max -$N)/2;

for( my $x=0; $x<$n-1; $x++ ) {
	my $x1 = $xmargin + $x * $k;
	my $xplus2 = $x + 2;
	for( my $y=0; $y<$n-1; $y++ ) {
		if( &gcd( $xplus2, $y+2 ) == 1 ) {
			my $y1 = $ymargin + $y * $k;
			for( my $i=0; $i<$k; $i++ ) {
				my $X = $x1 + $i;
				for( my $j=0; $j<$k; $j++ ) {
					$can->create ( 'rectangle',
						$X,   $Y__max - ($y1+$j), 
						$X+1, $Y__max - ($y1+$j+1), 
						-fill => 'red',
						-outline => 'red',
					);
				}
			}
		}
	}
}
print "Done!\n";
MainLoop;

sub gcd {
	my ( $a, $b ) = @_; # two integers
	my $r;
	while ($b != 0 ) {
		$r = $a % $b;
		$a = $b;
		$b = $r;
	}
	return $a;
}

sub usage {
print <<USAGE;
-k <Dimension of elementary squares> Default is 25.
USAGE
}
