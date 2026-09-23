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

package App::FuguSeed::Text;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

# App::FuguSeed::Text - the views of a Standard SeedQR.
#
# The module renders the matrix of App::FuguSeed::Matrix as the grid
# view and the 25 zone views of QR-TEXT. A person draws one zone at a
# time, and the count of the dark modules of a zone proves the work.
#
# Every method is a class method, and every method is pure: it takes
# values and it returns values. The module touches no stream, and it
# loads no module. Each view ends with a line feed, and no line
# carries a trailing space.

# DARK and LIGHT:
#	The two characters of one module (QR-TEXT-1).
use constant DARK  => '#';
use constant LIGHT => '.';

# ZONE and ZONES:
#	A zone is 5 x 5 modules, and the matrix holds 5 zones in each
#	direction (QR-TEXT-3).
use constant ZONE  => 5;
use constant ZONES => 5;

# ROWS:
#	The letter of each row of zones, from the top (QR-TEXT-3).
use constant ROWS => [qw(A B C D E)];

# GUTTER:
#	The width of the label column of the grid view.
use constant GUTTER => 3;

# $class->grid($matrix):
#	The grid view of QR-TEXT-2: the 25 rows, with one space
#	between the zone columns and one empty line between the zone
#	rows. The letters A to E and the numbers 1 to 5 label it. The
#	view starts with one empty line, so it stands apart from the
#	digit string.
sub grid ( $, $matrix )
{
	my @lines = ( q{}, _header() );

	for my $band ( 0 .. ZONES - 1 ) {
		for my $line ( 0 .. ZONE - 1 ) {
			my $label =
			    $line == ( ZONE - 1 ) / 2
			    ? ROWS->[$band]
			    : q{};
			push @lines,
			    sprintf( '%-*s', GUTTER, $label )
			    . join( q{ },
				_chunks( $matrix, $band * ZONE + $line ) );
		}
		push @lines, q{} if $band < ZONES - 1;
	}

	return join( "\n", @lines ) . "\n";
}

# $class->zones($matrix):
#	The 25 zone views of QR-TEXT-4, in the order A-1 to E-5. A
#	zone view holds the zone name, the 5 rows of the zone, and
#	the count of the dark modules of the zone. Each view starts
#	with one empty line.
sub zones ( $class, $matrix )
{
	my @views;

	for my $band ( 0 .. ZONES - 1 ) {
		for my $stack ( 0 .. ZONES - 1 ) {
			push @views, $class->_zone( $matrix, $band, $stack );
		}
	}

	return @views;
}

# $class->_zone($matrix, $band, $stack):
#	The view of the zone in the row of zones $band and the column
#	of zones $stack, both 0-based.
sub _zone ( $, $matrix, $band, $stack )
{
	my @lines = ( q{}, ROWS->[$band] . '-' . ( $stack + 1 ) );
	my $dark  = 0;

	for my $line ( 0 .. ZONE - 1 ) {
		my @modules = @{ $matrix->[ $band * ZONE + $line ] }
		    [ $stack * ZONE .. $stack * ZONE + ZONE - 1 ];
		$dark += grep { $_ } @modules;
		push @lines, join q{}, map { $_ ? DARK : LIGHT } @modules;
	}

	push @lines, "dark $dark";

	return join( "\n", @lines ) . "\n";
}

# _header():
#	The label line of the zone columns. Each number sits over the
#	middle of its zone.
sub _header
{
	return ( q{ } x ( GUTTER + ( ZONE - 1 ) / 2 ) )
	    . join( q{ } x ZONE, 1 .. ZONES );
}

# _chunks($matrix, $row):
#	The row $row of the matrix as ZONES strings of ZONE
#	characters.
sub _chunks ( $matrix, $row )
{
	my @modules = map { $_ ? DARK : LIGHT } @{ $matrix->[$row] };

	return
	    map { join q{}, @modules[ $_ * ZONE .. $_ * ZONE + ZONE - 1 ] }
	    0 .. ZONES - 1;
}

1;
