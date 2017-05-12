package Algorithm::MinMax;

use 5.6.1;
use strict;
use warnings;

require Exporter;

our @ISA = qw(Exporter);

# Items to export into callers namespace by default. Note: do not export
# names by default without a very good reason. Use EXPORT_OK instead.
# Do not simply export all your public functions/methods/constants.

# This allows declaration	use Algorithm::MinMax ':all';
# If you do not need this, moving things directly into @EXPORT or @EXPORT_OK
# will save memory.
our %EXPORT_TAGS = ( 'all' => [ qw(
	
) ] );

our @EXPORT_OK = ( @{ $EXPORT_TAGS{'all'} } );

our @EXPORT = qw(
	
);
our $VERSION = '0.01';


# Preloaded methods go here.
sub minmax {
	my @array = @{ $_[ 1 ] };
	my @result;
	if( scalar( @array ) == 0 ) {
		return @result;
	} 
	if( scalar( @array ) == 1 ) {
		$result[ 0 ] = $array[ 0 ];
		$result[ 1 ] = $array[ 0 ];
		return @result;
	}
	my @min_cand;
	my @max_cand;
	my $r = scalar( @array ) - 2;
	my $k = 0;
	for( my $i = 0; $i <= $r ; $i = $i + 2 ) {
		if( $array[ $i ] < $array[ $i + 1 ] ) {
			$min_cand[ $k ] = $array[ $i ];
			$max_cand[ $k ] = $array[ $i + 1 ];
		} else {
			$min_cand[ $k ] = $array[ $i + 1 ];
			$max_cand[ $k ] = $array[ $i ];
		}
		++$k;
	}
	if( scalar( @array ) % 2 != 0 ) {
		if( $min_cand[ 0 ] < $array[ $r + 1 ] ) {
			$max_cand[ $k ] = $array[ $r + 1 ];
		} else {
			$min_cand[ $k ] = $array[ $r + 1 ];
		}
	}
	my $m = $min_cand[ 0 ];
	for( my $i = 1; $i < scalar( @min_cand ); ++$i ) {
		if( $min_cand[ $i ] < $m ) {
			$m = $min_cand[ $i ];
		}
	}
	$result[ 0 ] = $m;
	$m = $max_cand[ 0 ];
	for( my $i = 1; $i < scalar( @max_cand ); ++$i ) {
		if( $max_cand[ $i ] > $m ) {
			$m = $max_cand[ $i ];
		}
	}
	$result[ 1 ] = $m;
	@result;
}

1;
__END__
# Below is stub documentation for your module. You better edit it!

=head1 NAME

Algorithm::MinMax - Finding the minimum and maximum of an array with 
at most 3n/2 - 2 comparisons.

=head1 SYNOPSIS

  use Algorithm::MinMax;
  @a = ( 3, 2, 5, 4, 8, 9 );
  @r = Algorithm::MinMax->minmax( \@a );

  # $r[0] = minimum = 2
  # $r[1] = maximum = 9

=head1 DESCRIPTION

The implementation finds the minimum and maximum of a given array with
at most 3n/2 - 2 comparisons, where n is the number of elements of the
array. 

=head1 RETURN

Returns an array where the first entry is the minimum and the second
entry the maximum of the given array.

If minmax is called with an empty array, minmax will also return an 
empty array.

=head1 AUTHOR

Daniel Etzold, detzold@gmx.de

=cut
