#
#
# Douglas - Peucker algorithm
# Author. John D. Coryat 01/2007 USNaviguide.com
# http://www.usnaviguide.com/douglas-peucker.htm
# Maintainer: Mike Flannigan (temp4@mflan.com)
#
#
# Douglas-Peucker polyline simplification algorithm. First draws single line
# from start to end. Then finds largest deviation from this straight line, and if
# greater than tolerance, includes that point, splitting the original line into
# two new lines. Repeats recursively for each new line created.
#
#
package Data::Douglas_Peucker;
require 5.003;
use strict;

BEGIN {
	use Exporter;
	use vars qw ( $VERSION @ISA @EXPORT);
	$VERSION	= 0.01;
	@ISA		= qw ( Exporter );
	@EXPORT	= qw ( 
		&Douglas_Peucker
		&perp_distance
		&haversine_distance_meters
		&angle3points
	);
}

#
# Call as: @Opoints = &Douglas_Peucker( <reference to input array of points>, <tolerance>);
# Returns: Array of points
# Points Array Format:
# ([lat1,lng1],[lat2,lng2],...[latn,lngn])
#

sub Douglas_Peucker {
	my $href	= shift;
	my $tolerance	= shift;
	my @Ipoints	= @$href;
	my @Opoints	= ( );
	my @stack	= ( );
	my $fIndex	= 0;
	my $fPoint	= '';
	my $aIndex	= 0;
	my $anchor	= '';
	my $max		= 0;
	my $maxIndex	= 0;
	my $point	= '';
	my $dist	= 0;
	my $polygon	= 0; # Line Type
	
	$anchor = $Ipoints[0]; # save first point
	
	push( @Opoints, $anchor );
	
	$aIndex = 0; # Anchor Index
	
# 	Check for a polygon: At least 4 points and the first point == last point...
	
	if ( $#Ipoints >= 4 and $Ipoints[0] == $Ipoints[$#Ipoints] ) {
		$fIndex = $#Ipoints - 1;				# Start from the next to last point
		$polygon = 1; # It's a polygon
	}
	else {
		$fIndex = $#Ipoints; # It's a path (open polygon)
	}
	
	push( @stack, $fIndex );
	
# 	Douglas - Peucker algorithm...
	
	while(@stack) {
		$fIndex = $stack[$#stack];
		$fPoint = $Ipoints[$fIndex];
		$max = $tolerance;		 			# comparison values
		$maxIndex = 0;
	
# 	Process middle points...
	
		for (($aIndex+1) .. ($fIndex-1)) {
			$point = $Ipoints[$_];
			$dist = &perp_distance ($anchor, $fPoint, $point);
	
			if( $dist >= $max ) {
				$max = $dist;
				$maxIndex = $_;
			}
		}
	
		if( $maxIndex > 0 ) {
			push( @stack, $maxIndex );
		}
		else {
			push( @Opoints, $fPoint );
			$anchor = $Ipoints[(pop @stack)];
			$aIndex = $fIndex;
		}
	}
	
	if ( $polygon ) { # Check for Polygon
		push( @Opoints, $Ipoints[$#Ipoints] ); # Add the last point
	
# 		Check for collapsed polygons, use original data in that case...
	
		if( $#Opoints < 4 ) {
			@Opoints = @Ipoints;
		}
	}
	
	return ( @Opoints );
}

# Calculate Perpendicular Distance in meters between a line (two points) and a point...
# my $dist = &perp_distance( <line point 1>, <line point 2>, <point> );

sub perp_distance {	# Perpendicular distance in meters

	my $lp1   = shift;
	my $lp2   = shift;
	my $p     = shift;
	my $dist  = &haversine_distance_meters( $lp1, $p );
	my $angle = &angle3points( $lp1, $lp2, $p ); 

	return ( sprintf("%0.6f", abs($dist * sin($angle)) ) );
}

# Calculate Distance in meters between two points...

sub haversine_distance_meters {
	my $p1	= shift;
	my $p2	= shift;

	my $O = 3.141592654/180;
	my $b = $$p1[0] * $O;
	my $c = $$p2[0] * $O;
	my $d = $b - $c;
	my $e = ($$p1[1] * $O) - ($$p2[1] * $O);
	my $f = 2 * &asin( sqrt( (sin($d/2) ** 2) + cos($b) * cos($c) * (sin($e/2) ** 2)));

	return sprintf("%0.4f",$f * 6378137); # Return meters

	sub asin {
		atan2($_[0], sqrt(1 - $_[0] * $_[0]));
	}
}

# Calculate Angle in Radians between three points...

sub angle3points { # Angle between three points in radians

	my $p1	= shift;
	my $p2	= shift;
	my $p3 = shift;
	my $m1 = &slope( $p2, $p1 );
	my $m2 = &slope( $p3, $p1 );
 
	return ($m2 - $m1);

	sub slope {	# Slope in radians

		my $p1	= shift;
		my $p2	= shift;
		return( sprintf("%0.6f",atan2( (@$p2[1] - @$p1[1]),( @$p2[0] - @$p1[0] ))) );
	}
}

1;

__END__





=head1 NAME

Data::Douglas_Peucker




=head1 DESCRIPTION

Data::Douglas_Peucker processes a list of 2 dimensional 
data and reduces the number of records in the list using 
the Douglas/Peucker algoritm.  So it produces a set of 
2 dimensional data that is reduced in number, but 
approximates the original set.

A typical application is to reduce a set of 2 dimensional
points that fall along a curve to a smaller set of 
2 dimensional points that approximates the same curve.
An example of this is a GPS track (waypoints along a 
GPS track).

Note that the value assigned to $tolerance is roughly the 
number of meters distance that a point can be from the straight
line drawn between two latitude/longitude points, one on each side, 
and the point can be discarded.  So a higher number used for 
$tolerance removes more points from the original set of lat/longs.




=head1 SYNOPSIS

# Test Program: douglasp.pl

# Douglas - Peucker Test Program
# Author. John D. Coryat 01/2007 USNaviguide.com
# Maintainer: Mike Flannigan (temp4@mflan.com)
#
#

use strict;
use Data::Douglas_Peucker;

my $infile	= $ARGV[0];
my $outfile	= $ARGV[1];
my $tolerance	= $ARGV[2];
my @Ipoints	= ( );
my @Opoints	= ( );
my $data	= '';

if(!$infile or !$outfile or !$tolerance) {
 	print "Usage: douglas-peucker.pl <input file name> <output file name> <tolerance in meters>\n";
 	print "Data format: lat,lng\n";
 	exit;
}

if ( $tolerance <= 0 ) {
	print "Tolerance (meters) must be greater than zero.\n";
	exit;
}

if ( !(-s $infile) ) {
	print "Input File ($infile) not found.\n";
	exit;
}

#if (-s $outfile) {
#	print "Output File ($outfile) exists.\n";
#	exit;
#}

open IN, $infile;

while ( $data =  <IN> ) {
	if ( $data	=~ /(-?\d+\.\d*),(-?\d+\.\d*)/ ) {
		push( @Ipoints, [$1,$2] );
	}
}
close IN;

@Opoints = &Douglas_Peucker( \@Ipoints, $tolerance );

open OUT, ">$outfile";

foreach $data (@Opoints) { 
	print OUT "$$data[0],$$data[1]\n";
}

close OUT;

print "\nInput: " . $#Ipoints . " Output: " . $#Opoints . " Tolerance: $tolerance\n\n";

__END__

# Create a $infile, such as 'proc.txt' with this in the file:
-107.49414,46.81526
-107.49559,46.81524
-107.49558,46.81798
-107.49558,46.81886
-107.49415,46.81888
-107.49414,46.81526

# Copy the program above (the text between '=head1 SYNOPSIS' and
# '__END__' and paste it into a file named douglasp.pl.
# Place the file in your Perl script directory and run
# this command in a command-line interpreter, shell, 
# command prompt, terminal, or whatever it is called on
# your system:
# perl douglasp.pl proc.txt procout.txt 1
#
# The expected output is:
 'Input: 5 Output: 4 Tolerance: 1' to the command-line interpreter
# and this output in the 'procout.txt' file:
-107.49414,46.81526
-107.49559,46.81524
-107.49558,46.81886
-107.49415,46.81888
-107.49414,46.81526

# So one of the six records was removed.
#
# Remember that a higher number used for $tolerance removes more
# points from the original set of lat/longs.
#
#


=cut

