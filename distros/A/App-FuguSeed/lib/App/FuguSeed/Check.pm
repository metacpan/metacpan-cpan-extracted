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

package App::FuguSeed::Check;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

# App::FuguSeed::Check - prove that a word sheet is correct
# (WORDS-CHECK).
#
# The module loads no builder module, so a defect of the builder
# cannot hide in the checker (WORDS-CHECK-3). It therefore holds its
# own copy of the grammar of the sheet. The two copies must agree,
# and t/fuguseed/sheet.t holds them to each other: the check runs on
# a built sheet on each test run.
#
# The check consumes the sheet as one strict grammar from the first
# byte to the last (D-09, WORDS-CHECK-4). Every byte of the sheet
# belongs to a literal of the grammar, to one of the 2048 cells, or
# to the digest and the date of a footer. A byte that the grammar
# does not expect ends the walk, and the defect names its offset. An
# attribute, a script, a comment, an entity, and a byte outside
# printable ASCII are therefore defects, and no rule of them needs a
# pattern of its own (WORDS-BUILD-3, WORDS-CHECK-5).
#
# The style sheet is the one part that the check reads from a share
# file. It compares the inlined text with share/fuguseed/sheet.css
# byte for byte, because a style rule can reverse or hide a row on
# paper while the text order stays correct (D-09, WORDS-CHECK-5).

# SIDES, BLOCKS, ROWS and COLUMNS:
#	The shape of the sheet (WORDS-BUILD-4, WORDS-BUILD-5).
use constant SIDES   => 2;
use constant BLOCKS  => 4;
use constant ROWS    => 16;
use constant COLUMNS => 16;

# WINDOW:
#	The bytes that the walk reads ahead of the cursor for a
#	variable part. The longest variable part is the SHA-256 of 64
#	hex digits.
use constant WINDOW => 128;

# SHOW:
#	The bytes of a defect message that name the text at the
#	cursor, and the bytes that name the expected text.
use constant SHOW => 16;

# $class->defects($sheet, $list, $style):
#	Each defect of the sheet $sheet, as one line each, or an empty
#	list for a correct sheet (WORDS-CHECK-2).
#
#	$list is the list of App::FuguSeed::ListFile, and $style is
#	the text of share/fuguseed/sheet.css.
sub defects ( $class, $sheet, $list, $style )
{
	my $self = bless {
		text    => $sheet,
		at      => 0,
		stop    => 0,
		defects => [],
		cells   => [],
		footers => [],
	}, $class;

	$self->_document($style);

	# A walk that stopped holds no cell and no footer of the bytes
	# after the first unexpected one, so the checks below would
	# report a defect of that one defect.
	return @{ $self->{defects} } if @{ $self->{defects} };

	$self->_words( $list->{words} );
	$self->_footers( $list->{digest} );

	return @{ $self->{defects} };
}

# $self->_document($style):
#	The whole sheet, from the first byte to the last.
sub _document ( $self, $style )
{
	$self->_want( "<!DOCTYPE html>\n"
		    . qq(<html lang="en">\n)
		    . "<head>\n"
		    . qq(<meta charset="utf-8">\n)
		    . "<title>FuguSeed word sheet</title>\n"
		    . "<style>\n" );
	$self->_want($style);
	$self->_want( "</style>\n" . "</head>\n" . "<body>\n" );
	$self->_side($_) for 1 .. SIDES;
	$self->_want( "</body>\n" . "</html>\n" );
	$self->_last;

	return;
}

# $self->_side($side):
#	One side: the heading, the legend, the four blocks, and the
#	footer (WORDS-BUILD-4, WORDS-BUILD-7).
sub _side ( $self, $side )
{
	$self->_want( "<section>\n"
		    . "<h1>FuguSeed word sheet, side $side of "
		    . SIDES
		    . "</h1>\n"
		    . "<ul>\n"
		    . "<li>YELLOW d8 gives the block number, 1 to 8.</li>\n"
		    . "<li>BLUE d16 gives the row number, 1 to 16.</li>\n"
		    . "<li>RED d16 gives the column number, 1 to 16.</li>\n"
		    . "</ul>\n" );

	my $first = ( $side - 1 ) * BLOCKS + 1;
	$self->_block($_) for $first .. $first + BLOCKS - 1;
	$self->_footer($side);

	return;
}

# $self->_block($block):
#	One block: the caption, the header row of the RED columns,
#	and the 16 rows of the BLUE die. Each cell reaches the cell
#	list with its block, its row, and its column
#	(WORDS-CHECK-6).
sub _block ( $self, $block )
{
	$self->_want(
		"<table>\n<caption>YELLOW $block</caption>\n<tr><td></td>");
	$self->_want("<th>RED $_</th>") for 1 .. COLUMNS;
	$self->_want("</tr>\n");

	for my $row ( 1 .. ROWS ) {
		$self->_want("<tr><th>BLUE $row</th>");
		for my $column ( 1 .. COLUMNS ) {
			$self->_want('<td>');
			my $word =
			    $self->_take( qr/[a-z]{3,8}/,
				'a word of the list' );
			$self->_want('</td>');
			push @{ $self->{cells} },
			    [ $block, $row, $column, $word ]
			    if defined $word;
		}
		$self->_want("</tr>\n");
	}
	$self->_want("</table>\n");

	return;
}

# $self->_footer($side):
#	The footer of one side. It names the side, the standard, the
#	SHA-256 of the list, and the build date (WORDS-BUILD-7). The
#	digest and the date reach the footer list, and _footers holds
#	them to the list file below.
sub _footer ( $self, $side )
{
	$self->_want( "<footer>\n<p>Side $side of "
		    . SIDES
		    . '. The word list is the English list of BIP39.'
		    . ' Its SHA-256 is ' );
	my $digest =
	    $self->_take( qr/[0-9a-f]{64}/, 'a SHA-256 of 64 hex digits' );
	$self->_want('. The build date is ');
	my $date =
	    $self->_take( qr/[0-9]{4}-[0-9]{2}-[0-9]{2}/, 'a date YYYY-MM-DD' );
	$self->_want( ".</p>\n" . "</footer>\n" . "</section>\n" );

	push @{ $self->{footers} }, { digest => $digest, date => $date }
	    if defined $digest && defined $date;

	return;
}

# $self->_words($words):
#	Hold each of the 2048 cells to the word of its position, and
#	hold each word to one appearance (WORDS-CHECK-6).
sub _words ( $self, $words )
{
	my %count;
	for my $cell ( @{ $self->{cells} } ) {
		my ( $block, $row, $column, $word ) = @{$cell};
		$count{$word}++;

		my $index =
		    ( $block - 1 ) * ROWS * COLUMNS +
		    ( $row - 1 ) * COLUMNS +
		    ( $column - 1 );
		next if $word eq $words->[$index];

		push @{ $self->{defects} },
		    sprintf 'YELLOW %d BLUE %d RED %d: the sheet holds %s, '
		    . 'and the list holds %s',
		    $block, $row, $column, $word, $words->[$index];
	}

	for my $word ( sort grep { $count{$_} > 1 } keys %count ) {
		push @{ $self->{defects} },
		    sprintf 'the sheet holds the word %s %d times', $word,
		    $count{$word};
	}

	return;
}

# $self->_footers($digest):
#	Hold each footer to the digest of the list file, and hold the
#	two sides to one build date (WORDS-CHECK-6).
sub _footers ( $self, $digest )
{
	my $side = 0;
	for my $footer ( @{ $self->{footers} } ) {
		$side++;
		next if $footer->{digest} eq $digest;
		push @{ $self->{defects} },
		    sprintf 'side %d: the footer names the SHA-256 %s, '
		    . 'and the list file has the SHA-256 %s',
		    $side, $footer->{digest}, $digest;
	}

	push @{ $self->{defects} }, 'the two sides name two build dates'
	    if $self->{footers}[0]{date} ne $self->{footers}[1]{date};

	return;
}

# $self->_want($literal):
#	Consume $literal at the cursor. Another byte is a defect: the
#	message names the offset of the first unexpected byte, and the
#	walk stops (WORDS-CHECK-4).
sub _want ( $self, $literal )
{
	return if $self->{stop};

	my $length = length $literal;
	my $found  = substr $self->{text}, $self->{at}, $length;
	if ( $found eq $literal ) {
		$self->{at} += $length;
		return;
	}

	my $same = 0;
	$same++
	    while $same < length $found
	    && substr( $found, $same, 1 ) eq substr( $literal, $same, 1 );

	my $at = $self->{at} + $same;
	push @{ $self->{defects} },
	    sprintf
	    'byte %d: the sheet holds "%s", and the sheet must hold "%s"',
	    $at, _show( substr $self->{text}, $at, SHOW ),
	    _show( substr $literal, $same, SHOW );
	$self->{stop} = 1;

	return;
}

# $self->_take($pattern, $form):
#	Consume one variable part at the cursor and give its text.
#	Text that $pattern does not match is a defect, and the walk
#	stops (WORDS-CHECK-4).
sub _take ( $self, $pattern, $form )
{
	return if $self->{stop};

	my $rest = substr $self->{text}, $self->{at}, WINDOW;
	if ( $rest =~ /\A($pattern)/ ) {
		$self->{at} += length $1;
		return $1;
	}

	push @{ $self->{defects} },
	    sprintf 'byte %d: the sheet holds "%s", and the sheet must hold %s',
	    $self->{at}, _show( substr $rest, 0, SHOW ), $form;
	$self->{stop} = 1;

	return;
}

# $self->_last:
#	The grammar ends at the last byte of the sheet. A byte after
#	it is a defect (WORDS-CHECK-4).
sub _last ($self)
{
	return if $self->{stop};

	my $length = length $self->{text};
	return if $self->{at} == $length;

	push @{ $self->{defects} },
	    sprintf 'byte %d: the sheet holds a byte after the last '
	    . 'byte of the grammar',
	    $self->{at};
	$self->{stop} = 1;

	return;
}

# _show($text):
#	$text for a defect message: one line of printable ASCII. A
#	defect holds one line, so each other byte reads as its
#	hexadecimal value (WORDS-CHECK-2).
sub _show ($text)
{
	$text =~ s/([^\x20-\x7e])/sprintf '\\x%02x', ord $1/ge;

	return $text;
}

1;
