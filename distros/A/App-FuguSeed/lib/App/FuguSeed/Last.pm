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

package App::FuguSeed::Last;
our $VERSION = '0.2.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use App::FuguSeed::List     ();
use App::FuguSeed::Mnemonic ();

# App::FuguSeed::Last - the face check, the check word, and the flow
# of fuguseed-last.
#
# The module reads words 1 to 11 and the YELLOW and BLUE faces of
# word 12 from standard input, and it writes the check word to
# standard output (LAST-PROGRAM-3, LAST-PROGRAM-4). It is the one
# module of the program that touches a stream, and the three standard
# streams are the one contact of the program with the computer
# (SEC-TRUST-3).
#
# A failure line names a word position, a count, or a die, never a
# word or a face. The check word leaves on standard output only
# (SEC-CHANNELS-2).

# NAME and USAGE:
#	The name of the program in a failure line, and the one usage
#	line of LAST-PROGRAM-2. The program takes no option and no
#	argument (D-12).
use constant NAME  => 'fuguseed-last';
use constant USAGE => "usage: fuguseed-last\n";

# SUCCESS, FAILURE and USAGE_ERROR:
#	The three exit codes of the program (LAST-PROGRAM-2,
#	LAST-PROGRAM-4).
use constant SUCCESS     => 0;
use constant FAILURE     => 1;
use constant USAGE_ERROR => 2;

# COUNT and FIELDS:
#	The words of the first line, and the faces of the second line
#	(LAST-PROGRAM-3).
use constant COUNT  => 11;
use constant FIELDS => 2;

# YELLOW and BLUE:
#	The faces of the d8 and of the BLUE d16 (D-05).
use constant YELLOW => 8;
use constant BLUE   => 16;

# BLOCK and ROW:
#	The words of one YELLOW block and of one BLUE row. The index
#	of a word is (Y-1)*256 + (B-1)*16 + (R-1) (D-05).
use constant BLOCK => 256;
use constant ROW   => 16;

# $class->fault($faces):
#	The failure message for the fields of the array reference
#	$faces, or undef when they are a YELLOW face and a BLUE face
#	(LAST-WORD-2). A face is one of the decimal numbers 1 to the
#	count of its faces, as a string, so "08" and "+8" fail. The
#	message names the field count or the die, never a face.
sub fault ( $, $faces )
{
	my $found = scalar @{$faces};
	return "the second line holds $found fields, not " . FIELDS
	    if $found != FIELDS;

	my ( $yellow, $blue ) = @{$faces};
	return 'the YELLOW face is not 1 to ' . YELLOW
	    unless grep { $_ eq $yellow } 1 .. YELLOW;
	return 'the BLUE face is not 1 to ' . BLUE
	    unless grep { $_ eq $blue } 1 .. BLUE;

	return;
}

# $class->check_word($words, $yellow, $blue):
#	The one word of the BLUE row of word 12 that makes the
#	checksum valid (LAST-WORD-3, LAST-WORD-4). The faces give the
#	first index of the row, and its 7 high bits are the last 7
#	entropy bits. The RED column gives the 4 checksum bits, so the
#	row holds exactly one valid word (D-04). The search is one
#	computation, and no trial loop exists. The caller proves the
#	words and the faces first.
sub check_word ( $, $words, $yellow, $blue )
{
	my $row   = ( $yellow - 1 ) * BLOCK + ( $blue - 1 ) * ROW;
	my @index = App::FuguSeed::Mnemonic->indexes($words);
	my $sum   = App::FuguSeed::Mnemonic->checksum( @index, $row );

	return App::FuguSeed::List->word( $row + $sum );
}

# $class->run(@argument):
#	Read the two lines, print the check word, and return the exit
#	code.
sub run ( $class, @argument )
{
	if (@argument) {
		print {*STDERR} USAGE;
		return USAGE_ERROR;
	}

	my $first = readline STDIN;
	my @words = split q{ }, $first // q{};

	my $second = readline STDIN;
	my @faces  = split q{ }, $second // q{};

	my $fault = App::FuguSeed::Mnemonic->fault( \@words, COUNT );
	$fault = $class->fault( \@faces ) if !defined $fault;
	if ( defined $fault ) {
		print {*STDERR} NAME . ": $fault\n";
		return FAILURE;
	}

	# A class name after print is a bareword filehandle on perl
	# v5.34, so the result reaches a variable first.
	my $word = $class->check_word( \@words, @faces );
	print "$word\n";

	return SUCCESS;
}

1;
