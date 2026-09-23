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

package App::FuguSeed::Codewords;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

# App::FuguSeed::Codewords - the 44 codewords of a Standard SeedQR.
#
# The module turns the 48 digits of QR-MNEMONIC-3 into the 34 data
# codewords and the 10 error correction codewords of QR-CODEWORDS.
# The code is QR version 2, error correction level L, numeric mode,
# in one block.
#
# Every method is a class method, and every method is pure: it takes
# values and it returns values. The module touches no stream, and it
# loads no module.
#
# Each constant of the QR standard names the table that it comes from
# (QR-PROGRAM-7). The standard is ISO/IEC 18004.

# MODE:
#	The mode indicator of numeric mode (Table 2).
use constant MODE => '0001';

# COUNT_BITS:
#	The bit width of the character count in numeric mode, for
#	version 1 to version 9 (Table 3).
use constant COUNT_BITS => 10;

# GROUP_DIGITS and GROUP_BITS:
#	Numeric mode takes the digits in groups of 3, and it writes
#	each group as 10 bits (8.4.2).
use constant GROUP_DIGITS => 3;
use constant GROUP_BITS   => 10;

# TERMINATOR:
#	The terminator after the data bits (8.4.8).
use constant TERMINATOR => '0000';

# CODEWORD_BITS:
#	The bit width of one codeword (8.4.8).
use constant CODEWORD_BITS => 8;

# DATA_CODEWORDS and CHECK_CODEWORDS:
#	The codeword counts of version 2 at error correction level L,
#	in one block (Table 9).
use constant DATA_CODEWORDS  => 34;
use constant CHECK_CODEWORDS => 10;

# PAD:
#	The two pad codewords, in turn, after the terminator (8.4.9).
use constant PAD => [ 0xEC, 0x11 ];

# FIELD:
#	The prime modulus of the field GF(256) of the error
#	correction codewords (Annex A).
use constant FIELD => 0x11D;

# The power table and the logarithm table of the field. The table
# entry $EXP[$i] is 2 to the power $i over GF(256), and $LOG is its
# inverse (Annex A).
my ( @EXP, @LOG );
{
	my $value = 1;
	for my $power ( 0 .. 254 ) {
		$EXP[$power] = $value;
		$LOG[$value] = $power;
		$value <<= 1;
		$value ^= FIELD if $value & 0x100;
	}
}

# $class->encode($digits):
#	The 44 codewords of the digit string $digits: the 34 data
#	codewords, then the 10 error correction codewords.
sub encode ( $class, $digits )
{
	my @data = $class->_data($digits);

	return @data, $class->_check(@data);
}

# $class->_data($digits):
#	The 34 data codewords of QR-CODEWORDS-2. The bit stream holds
#	the mode indicator, the character count, the digit groups,
#	the terminator, and the zero bits to a codeword boundary. The
#	two pad codewords fill the rest in turn.
sub _data ( $, $digits )
{
	my $bits = MODE . sprintf( '%0' . COUNT_BITS . 'b', length $digits );
	$bits .= join q{},
	    map { sprintf '%0' . GROUP_BITS . 'b', $_ }
	    unpack( '(A' . GROUP_DIGITS . ')*', $digits );
	$bits .= TERMINATOR;
	$bits .= '0' x ( ( CODEWORD_BITS - length($bits) % CODEWORD_BITS )
		% CODEWORD_BITS );

	my @data = map { oct( '0b' . $_ ) }
	    unpack( '(A' . CODEWORD_BITS . ')*', $bits );

	my @pad  = @{ +PAD };
	my $next = 0;
	while ( @data < DATA_CODEWORDS ) {
		push @data, $pad[ $next++ % @pad ];
	}

	return @data;
}

# $class->_check(@data):
#	The 10 error correction codewords of @data: the remainder of
#	the data polynomial over the generator polynomial, over
#	GF(256) (QR-CODEWORDS-3).
sub _check ( $, @data )
{
	my @generator = _generator(CHECK_CODEWORDS);
	my @remainder = (0) x CHECK_CODEWORDS;

	for my $codeword (@data) {
		my $factor = $codeword ^ shift @remainder;
		push @remainder, 0;
		for my $term ( 0 .. $#remainder ) {
			$remainder[$term] ^=
			    _multiply( $generator[ $term + 1 ], $factor );
		}
	}

	return @remainder;
}

# _generator($degree):
#	The generator polynomial of degree $degree, the coefficient
#	of the highest power first. It is the product of the terms
#	(x - 2**$i) over GF(256), for $i from 0 to $degree - 1
#	(Annex A).
sub _generator ($degree)
{
	my @polynomial = (1);

	for my $power ( 0 .. $degree - 1 ) {
		my @product = ( @polynomial, 0 );
		for my $term ( 0 .. $#polynomial ) {
			$product[ $term + 1 ] ^=
			    _multiply( $polynomial[$term], $EXP[$power] );
		}
		@polynomial = @product;
	}

	return @polynomial;
}

# _multiply($left, $right):
#	The product of $left and $right over GF(256) (Annex A).
sub _multiply ( $left, $right )
{
	return 0 if $left == 0 || $right == 0;

	return $EXP[ ( $LOG[$left] + $LOG[$right] ) % 255 ];
}

1;
