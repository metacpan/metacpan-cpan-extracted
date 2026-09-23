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

package App::FuguSeed::QR;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use App::FuguSeed::Codewords ();
use App::FuguSeed::Matrix    ();
use App::FuguSeed::Mnemonic  ();
use App::FuguSeed::Text      ();

# App::FuguSeed::QR - the flow of fuguseed-qr.
#
# The module reads the 12 words from standard input, and it writes
# the SeedQR or the check word to standard output (QR-PROGRAM-3,
# QR-PROGRAM-4). It is the one module of the program that touches a
# stream, and the three standard streams are the one contact of the
# program with the computer (SEC-TRUST-3).
#
# A failure line names a word position or a count, never a word, and
# the check word leaves on standard output only (SEC-CHANNELS-2).

# NAME and USAGE:
#	The name of the program in a failure line, and the one usage
#	line of QR-PROGRAM-2. The program takes no option and no
#	argument (D-12).
use constant NAME  => 'fuguseed-qr';
use constant USAGE => "usage: fuguseed-qr\n";

# SUCCESS, FAILURE and USAGE_ERROR:
#	The three exit codes of the program (QR-PROGRAM-2,
#	QR-PROGRAM-4).
use constant SUCCESS     => 0;
use constant FAILURE     => 1;
use constant USAGE_ERROR => 2;

# $class->run(@argument):
#	Read the words, print the result, and return the exit code.
sub run ( $, @argument )
{
	if (@argument) {
		print {*STDERR} USAGE;
		return USAGE_ERROR;
	}

	# The pause of QR-TEXT-5 waits for a person, so each view
	# must leave the buffer before the read.
	local $| = 1;

	my $line  = readline STDIN;
	my @words = split q{ }, $line // q{};

	my $fault = App::FuguSeed::Mnemonic->fault( \@words );
	if ( defined $fault ) {
		print {*STDERR} NAME . ": $fault\n";
		return FAILURE;
	}

	# A wrong checksum is a result, not a failure: the program
	# prints the check word and it prints no SeedQR
	# (QR-MNEMONIC-4).
	# A class name after print is a bareword filehandle on perl
	# v5.34, so each result reaches a variable first.
	if ( !App::FuguSeed::Mnemonic->valid( \@words ) ) {
		my $word = App::FuguSeed::Mnemonic->check_word( \@words );
		print "$word\n";
		return SUCCESS;
	}

	my $digits    = App::FuguSeed::Mnemonic->digits( \@words );
	my @codewords = App::FuguSeed::Codewords->encode($digits);
	my $matrix    = App::FuguSeed::Matrix->build( \@codewords );
	my $grid      = App::FuguSeed::Text->grid($matrix);

	print "$digits\n";
	print $grid;

	my @views = App::FuguSeed::Text->zones($matrix);
	while ( defined( my $view = shift @views ) ) {
		print $view;

		# One line of standard input between two zones. At
		# the end of the input, the remaining zones print
		# without a pause (QR-TEXT-5).
		readline STDIN if @views;
	}

	return SUCCESS;
}

1;
