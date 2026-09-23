# ex:ts=8 sw=4:
# $OpenBSD$
#
# Copyright (c) 2026 Dick Olsson <hi@senzilla.io>
#
# Permission to use, copy, modify, and distribute this software for any
# purpose with or without fee is hereby granted, provided that the above
# copyright notice and this permission notice appear in all copies.
#
# THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
# WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
# MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
# ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
# WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
# ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
# OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

package App::FuguSeed::Matrix;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

# App::FuguSeed::Matrix - the 25 x 25 modules of a Standard SeedQR.
#
# The module places the function patterns, the 44 codewords, the mask
# and the format information in the grid of QR-MATRIX. Module (0,0)
# is the top left corner, the first index is the row, and the second
# is the column. A module is 1 when it is dark, and 0 when it is
# light.
#
# Every method is a class method, and every method is pure: it takes
# values and it returns values. The module touches no stream, and it
# loads no module.
#
# The mask is pattern 0, always (D-08), so the module computes no
# penalty score and the format bits are one constant.
#
# Each constant of the QR standard names the clause or the table that
# it comes from (QR-PROGRAM-7). The standard is ISO/IEC 18004.

# SIZE:
#	The module count of one side. Version 2 is 25 x 25 modules
#	(Table 1).
use constant SIZE => 25;

# FINDER:
#	The side of one finder pattern, and the ring of its light
#	modules (6.3.3).
use constant FINDER      => 7;
use constant FINDER_RING => 2;

# TIMING:
#	The row and the column of the two timing patterns (6.3.5).
use constant TIMING => 6;

# ALIGNMENT:
#	The row and the column of the center of the one alignment
#	pattern of version 2 (Table E.1). Its ring of light modules
#	sits one module from the center (6.3.6).
use constant ALIGNMENT      => 18;
use constant ALIGNMENT_RING => 1;

# DARK:
#	The row of the dark module. It sits at (4 * version + 9, 8)
#	(8.9).
use constant DARK => 17;

# FORMAT:
#	The 15 bits of the format information for error correction
#	level L with mask pattern 0 (Table 25), the first bit first.
use constant FORMAT => '111011111000100';

# FORMAT_ONE and FORMAT_TWO:
#	The two positions of each format bit, in bit order
#	(Figure 25). The first copy surrounds the finder pattern of
#	the top left corner, and the second copy sits beside the
#	other two finder patterns.
use constant FORMAT_ONE => [
	[ 8, 0 ], [ 8, 1 ], [ 8, 2 ], [ 8, 3 ], [ 8, 4 ], [ 8, 5 ],
	[ 8, 7 ], [ 8, 8 ], [ 7, 8 ], [ 5, 8 ], [ 4, 8 ], [ 3, 8 ],
	[ 2, 8 ], [ 1, 8 ], [ 0, 8 ],
];
use constant FORMAT_TWO => [
	[ 24, 8 ],  [ 23, 8 ],  [ 22, 8 ],  [ 21, 8 ],  [ 20, 8 ],  [ 19, 8 ],
	[ 18, 8 ],  [ 8,  17 ], [ 8,  18 ], [ 8,  19 ], [ 8,  20 ], [ 8,  21 ],
	[ 8,  22 ], [ 8,  23 ], [ 8,  24 ],
];

# CODEWORD_BITS:
#	The bit width of one codeword (8.4.8).
use constant CODEWORD_BITS => 8;

# $class->build($codewords):
#	The matrix of the codewords of the array reference
#	$codewords, as a reference to 25 rows of 25 modules.
sub build ( $class, $codewords )
{
	my $matrix   = [ map { [ (0) x SIZE ] } 1 .. SIZE ];
	my $reserved = [ map { [ (0) x SIZE ] } 1 .. SIZE ];

	$class->_functions( $matrix, $reserved );
	$class->_place( $matrix, $reserved, $codewords );
	$class->_format($matrix);

	return $matrix;
}

# $class->_functions($matrix, $reserved):
#	Draw the function patterns of QR-MATRIX-2, and reserve the
#	modules that hold the format information.
sub _functions ( $, $matrix, $reserved )
{
	# The three finder patterns, each with its separator
	# (6.3.3). The separator is the light frame around the
	# pattern, and it falls outside the matrix on two sides.
	for my $corner ( [ 0, 0 ], [ 0, SIZE - FINDER ], [ SIZE - FINDER, 0 ] )
	{
		my ( $top, $left ) = @{$corner};
		for my $row ( -1 .. FINDER ) {
			for my $column ( -1 .. FINDER ) {
				next if $top + $row < 0 || $top + $row >= SIZE;
				next
				    if $left + $column < 0
				    || $left + $column >= SIZE;
				_set(
					$matrix, $reserved,
					$top + $row,
					$left + $column,
					_finder( $row, $column ) );
			}
		}
	}

	# The two timing patterns (6.3.5). They run between the
	# separators, and they start with a dark module.
	for my $step ( FINDER + 1 .. SIZE - FINDER - 2 ) {
		my $dark = $step % 2 == 0 ? 1 : 0;
		_set( $matrix, $reserved, TIMING, $step,  $dark );
		_set( $matrix, $reserved, $step,  TIMING, $dark );
	}

	# The one alignment pattern of version 2 (6.3.6).
	my $edge = ALIGNMENT_RING + 1;
	for my $row ( -$edge .. $edge ) {
		for my $column ( -$edge .. $edge ) {
			my $ring = _ring( $row, $column );
			_set(
				$matrix, $reserved,
				ALIGNMENT + $row,
				ALIGNMENT + $column,
				$ring == ALIGNMENT_RING ? 0 : 1
			);
		}
	}

	# The dark module (8.9), and the modules of the format
	# information. A format module keeps its value until
	# _format writes it, and no codeword bit reaches it.
	_set( $matrix, $reserved, DARK, 8, 1 );
	for my $position ( @{ +FORMAT_ONE }, @{ +FORMAT_TWO } ) {
		$reserved->[ $position->[0] ][ $position->[1] ] = 1;
	}

	return;
}

# $class->_place($matrix, $reserved, $codewords):
#	Write the 352 codeword bits in the placement order of
#	QR-MATRIX-3, and apply the mask of QR-MATRIX-4. The order
#	starts at the bottom right corner and runs in column pairs,
#	upward and downward in turn, over the timing column. The 7
#	remainder bits after the codewords are 0.
sub _place ( $, $matrix, $reserved, $codewords )
{
	my $bits = join q{},
	    map { sprintf '%0' . CODEWORD_BITS . 'b', $_ } @{$codewords};

	my $next   = 0;
	my $upward = 1;
	my $column = SIZE - 1;

	while ( $column > 0 ) {
		$column-- if $column == TIMING;
		my @rows =
		    $upward ? reverse( 0 .. SIZE - 1 ) : ( 0 .. SIZE - 1 );
		for my $row (@rows) {
			for my $step ( $column, $column - 1 ) {
				next if $reserved->[$row][$step];
				my $bit =
				    $next < length $bits
				    ? substr( $bits, $next, 1 )
				    : 0;
				$next++;
				$bit = 1 - $bit if ( $row + $step ) % 2 == 0;
				$matrix->[$row][$step] = $bit;
			}
		}
		$upward = !$upward;
		$column -= 2;
	}

	return;
}

# $class->_format($matrix):
#	Write the 15 format bits of QR-MATRIX-5 in both positions.
sub _format ( $, $matrix )
{
	my @bits = split //, FORMAT;

	for my $bit ( 0 .. $#bits ) {
		for my $copy ( FORMAT_ONE->[$bit], FORMAT_TWO->[$bit] ) {
			$matrix->[ $copy->[0] ][ $copy->[1] ] = $bits[$bit];
		}
	}

	return;
}

# _finder($row, $column):
#	The module of the finder pattern at ($row, $column), with the
#	top left corner of the pattern at (0,0). A module of the
#	separator is light (6.3.3).
sub _finder ( $row, $column )
{
	return 0 if $row < 0    || $row >= FINDER;
	return 0 if $column < 0 || $column >= FINDER;

	my $middle = ( FINDER - 1 ) / 2;
	my $ring   = _ring( $row - $middle, $column - $middle );

	return $ring == FINDER_RING ? 0 : 1;
}

# _ring($row, $column):
#	The ring of the module at ($row, $column) around the center
#	(0,0) of a square pattern: 0 at the center, and one more for
#	each square around it.
sub _ring ( $row, $column )
{
	my $height = abs $row;
	my $width  = abs $column;

	return $height > $width ? $height : $width;
}

# _set($matrix, $reserved, $row, $column, $dark):
#	Write one function module, and reserve it against the
#	codeword bits.
sub _set ( $matrix, $reserved, $row, $column, $dark )
{
	$matrix->[$row][$column]   = $dark;
	$reserved->[$row][$column] = 1;

	return;
}

1;
