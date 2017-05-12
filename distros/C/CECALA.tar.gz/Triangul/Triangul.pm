package Triangul;

use strict;
use Exporter;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK %EXPORT_TAGS);

$VERSION     = 1.00;
@ISA         = qw(Exporter);
@EXPORT      = ();
@EXPORT_OK   = qw(&new &triangul);
%EXPORT_TAGS = ( DEFAULT => [qw(&new &triangul)],
                   Both    => [qw(&new &triangul)]);


sub triangul {
	my $pol = shift; # ref to array
	my $n	= shift; # scalar
	my $nrs = shift; # ref to Array of Hashs struct trianrs { int A, B, C }
	my $orienta = shift; # ref to sub
	my $PP	= shift; #ref to array of Vector2D to be passed or orienta

	my $j = 0;

	my @ptr = ();
	my ( $q, $qA, $qB, $qC);
	my $r = -1;
	my $collinear;
	my $polconvex = 1;


	if ( $n < 3 ) { return -1; }
	if ( $n == 3 ) {
		my $rec = {};
		$rec->{A} = $pol->[0]; $rec->{B} = $pol->[1]; $rec->{C} = $pol->[2];
		push( @$nrs, $rec );
		return 1;
	}

	my @ort = (0..($n-1));
	for ( my $ortI=0; $ortI<$n-1; $ortI++ ) { $ort[$ortI] = 0;}

	do {
		$collinear = 0;
		for( my $i=0; $i<$n; $i++ ) {
			my $i1 = ($i <($n-1) ? $i  + 1 : 0 );
			my $i2 = ($i1<($n-1) ? $i1 + 1 : 0 );
			$ort[$i1] = &$orienta( $pol->[$i], $pol->[$i1], $pol->[$i2], $PP );
			if ( $ort[$i1] == 0 ) {
				$collinear = 1;
				for ( $j=$i1; $j<$n-1; $j++ ) { $pol->[$j] = $pol->[$j+1]; }
				$n--;
				last;
			}
			if ( $ort[$i1] < 1 ) { $polconvex = 0; } 
		}

	} while ( $collinear != 0 );
	if ( $n < 3 ) { return -1; }
	if ( $polconvex != 0 ) {
		for ( $j=0; $j<$n-2; $j++ ) {
			my $rec = {};
			# I don't know if 0 here is a typo
			# or actually correct
			#$rec->{A} = $pol->[0];	
			$rec->{A} = $pol->[$j];	
			$rec->{B} = $pol->[$j+1];	
			$rec->{C} = $pol->[$j+2];	
			$nrs->[$j]= $rec;
			#push( @$nrs, $rec );
		}
		return $n-2;
	}
 
	for( my $i=1; $i<$n; $i++ ) { $ptr[$i-1]=$i; }
	$ptr[$n-1] = 0;

	$q = 0;
	$qA = $ptr[$q];
	$qB = $ptr[$qA];
	$qC = $ptr[$qB];
	$j=0;
	for( my $m=$n; $m>2; $m-- ) {
		for( my $k=0; $k<$m; $k++ ) {
			# try triangle ABC
			my $ortB = $ort[$qB];
			my $ok = 0;
			# B is canidate for convex
			if ( $ortB > 0 ) {
				my $A = $pol->[$qA];
				my $B = $pol->[$qB];
				my $C = $pol->[$qC];
				$ok = 1;
				$r = $ptr[$qC];
				while( $r != $qA && $ok != 0 ) {
					my $P = $pol->[$r]; # ABC counter clockwise
					$ok = 	$P == $A || 
						$P == $B || 
						$P == $C ||
						&$orienta( $A, $B, $P, $PP ) < 0 ||
						&$orienta( $B, $C, $P, $PP ) < 0 ||
						&$orienta( $C, $A, $P, $PP ) < 0;
					if( length($ok) == 0 ) { $ok = 0;}
					$r = $ptr[$r];
				} #end while 
				# ok means: P coinciding with A, B , or C
				# or outside ABC
				if( $ok != 0 ) {
					my $rec = {};
					$rec->{A} = $pol->[$qA];
					$rec->{B} = $pol->[$qB];
					$rec->{C} = $pol->[$qC];
					# push might be better
					#push( @$nrs, $rec );
					$nrs->[$j] = $rec;
					$j++;
				} 
			} # end if ortB
			if ( ($ok != 0 ) || ($ortB == 0) ) {
				$ptr[$qA] = $qC;
				$qB = $qC;
				$qC = $ptr[$qC];
				if( $ort[$qA] < 1 ) {
					$ort[$qA] = &$orienta( $pol->[$q], $pol->[$qA], $pol->[$qB], $PP);
				}
				if( $ort[$qB] < 1 ) {
					$ort[$qB] = &$orienta( $pol->[$qA], $pol->[$qB], $pol->[$qC], $PP);
				}
				while( ($ort[$qA] == 0) && ($m > 2) ) {
					$ptr[$q] = $qB;
					$qA = $qB;
					$qB = $qC;
					$qC = $ptr[$qC];
					$m--;
				}
				while( ($ort[$qB]) == 0 && ($m > 2) ) {
					$ptr[$qA] = $qC;
					$qB = $qC;
					$qC = $ptr[$qC];
					$m--;
				}
				last;
			} #end if ok or ortB
			$q = $qA;
			$qA = $qB;
			$qB = $qC;
			$qC = $ptr[$qC];
		} # end for k
	} # end for m
	return $j;
} #end sub triangul

1;
