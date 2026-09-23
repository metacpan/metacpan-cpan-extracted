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

package App::FuguSeed::Sheet;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

# App::FuguSeed::Sheet - build the printed word sheet (WORDS-BUILD).
#
# The module builds the sheet text from the list, the template, the
# style sheet, and the date. It opens no file and it writes no file
# (WORDS-BUILD-8): App::FuguSeed::Words reads the two share files and
# prints the result.
#
# The sheet is the address space of the dice. The cell in block Y,
# row B, and column R holds the word of index
# (Y-1)*256 + (B-1)*16 + (R-1), so the person does no arithmetic
# (D-05, WORDS-BUILD-6).
#
# The sheet holds no place for a decoy: no class, no identifier, no
# style attribute, no script, no comment, and no entity
# (WORDS-BUILD-3). App::FuguSeed::Check proves each of those rules on
# a built sheet, and it holds its own copy of this grammar: a defect
# of this module must not hide in the checker (WORDS-CHECK-3).

# STYLE_TOKEN and SIDES_TOKEN:
#	The two places of share/fuguseed/sheet.html that the build
#	fills. The style sheet arrives byte for byte, so the check can
#	compare the inlined text with the shipped file (D-09).
use constant STYLE_TOKEN => '{{STYLE}}';
use constant SIDES_TOKEN => '{{SIDES}}';

# SIDES, BLOCKS, ROWS and COLUMNS:
#	The shape of the sheet. Two sides of four blocks hold the
#	eight blocks of the YELLOW d8, and each block holds the 16
#	rows of the BLUE d16 and the 16 columns of the RED d16
#	(WORDS-BUILD-4, WORDS-BUILD-5).
use constant SIDES   => 2;
use constant BLOCKS  => 4;
use constant ROWS    => 16;
use constant COLUMNS => 16;

# $class->build(%argument):
#	The whole sheet as text.
#
#	%argument:
#		list     => $list	the list of App::FuguSeed::ListFile
#		template => $text	share/fuguseed/sheet.html
#		style    => $text	share/fuguseed/sheet.css
#		date     => $date	the build date, as YYYY-MM-DD
#
#	Two builds of one list on one date give one text
#	(WORDS-BUILD-7).
sub build ( $, %argument )
{
	my ( $list, $template, $style, $date ) =
	    @argument{qw(list template style date)};

	my $sides = q{};
	$sides .= _side( $_, $list, $date ) for 1 .. SIDES;

	my $sheet = _fill( $template, STYLE_TOKEN, $style );

	return _fill( $sheet, SIDES_TOKEN, $sides );
}

# _side($side, $list, $date):
#	One side of the sheet: the heading, the legend, the four
#	blocks, and the footer (WORDS-BUILD-4, WORDS-BUILD-7).
sub _side ( $side, $list, $date )
{
	my $text =
	      "<section>\n"
	    . "<h1>FuguSeed word sheet, side $side of "
	    . SIDES
	    . "</h1>\n"
	    . "<ul>\n"
	    . "<li>YELLOW d8 gives the block number, 1 to 8.</li>\n"
	    . "<li>BLUE d16 gives the row number, 1 to 16.</li>\n"
	    . "<li>RED d16 gives the column number, 1 to 16.</li>\n"
	    . "</ul>\n";

	my $first = ( $side - 1 ) * BLOCKS + 1;
	$text .= _block( $_, $list->{words} ) for $first .. $first + BLOCKS - 1;

	$text .=
	      "<footer>\n<p>Side $side of "
	    . SIDES
	    . '. The word list is the English list of BIP39.'
	    . ' Its SHA-256 is '
	    . $list->{digest}
	    . ". The build date is $date.</p>\n"
	    . "</footer>\n"
	    . "</section>\n";

	return $text;
}

# _block($block, $words):
#	One block as one table: the caption, the header row of the
#	RED columns, and the 16 rows of the BLUE die
#	(WORDS-BUILD-5, WORDS-BUILD-6).
sub _block ( $block, $words )
{
	my $text = "<table>\n<caption>YELLOW $block</caption>\n<tr><td></td>";
	$text .= "<th>RED $_</th>" for 1 .. COLUMNS;
	$text .= "</tr>\n";

	for my $row ( 1 .. ROWS ) {
		my $base =
		    ( $block - 1 ) * ROWS * COLUMNS + ( $row - 1 ) * COLUMNS;
		$text .= "<tr><th>BLUE $row</th>";
		$text .= '<td>' . $words->[ $base + $_ - 1 ] . '</td>'
		    for 1 .. COLUMNS;
		$text .= "</tr>\n";
	}

	return $text . "</table>\n";
}

# _fill($text, $token, $value):
#	$text with the one $token replaced by $value. A template
#	without the token is a defect of the share file, and the
#	build dies on it.
sub _fill ( $text, $token, $value )
{
	my $at = index $text, $token;
	die "App::FuguSeed::Sheet: the template holds no $token\n" if $at < 0;
	substr $text, $at, length $token, $value;

	return $text;
}

1;
