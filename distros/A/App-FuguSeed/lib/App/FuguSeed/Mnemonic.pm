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

package App::FuguSeed::Mnemonic;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Digest::SHA ();

use App::FuguSeed::List ();

# App::FuguSeed::Mnemonic - the 12 seed words of a SeedQR.
#
# The module proves the count and the list membership of 12 words
# (QR-MNEMONIC-1), it proves the BIP39 checksum (QR-MNEMONIC-2), it
# gives the digit string (QR-MNEMONIC-3), and it finds the check word
# (QR-MNEMONIC-4).
#
# Every method is a class method, and every method is pure: it takes
# values and it returns values. The module touches no stream. A
# caller gets the failure message and prints it, and the message
# names a count or a word position, never a word (SEC-CHANNELS-2).
#
# The module runs on core perl v5.34 with Digest::SHA alone, because
# scripts/pack embeds it in fuguseed-qr (QR-PROGRAM-5).

# COUNT:
#	The word count of one seed (D-04).
use constant COUNT => 12;

# INDEX_BITS:
#	The bit width of one word index. The list holds 2048 words,
#	so an index needs 11 bits (BIP39).
use constant INDEX_BITS => 11;

# ENTROPY_BITS:
#	The entropy bits of 12 words. The 12 indexes give 132 bits,
#	and the 4 bits after the entropy are the checksum (BIP39,
#	QR-MNEMONIC-2).
use constant ENTROPY_BITS => 128;

# CHECKSUM_BITS:
#	The checksum bits of 12 words (BIP39). The RED column of the
#	word sheet carries them, because it gives the low 4 bits of
#	an index (D-05).
use constant CHECKSUM_BITS => 4;

# DIGITS:
#	The decimal digits of one index in the digit string
#	(QR-MNEMONIC-3).
use constant DIGITS => 4;

# $class->fault($words):
#	The failure message for the words of the array reference
#	$words, or undef when the words pass QR-MNEMONIC-1. The
#	message names a count or a word position, never a word.
sub fault ( $, $words )
{
	my $count = scalar @{$words};
	return "the input holds $count words, not " . COUNT
	    if $count != COUNT;

	for my $position ( 1 .. COUNT ) {
		my $index =
		    App::FuguSeed::List->index( $words->[ $position - 1 ] );
		return "word $position is not in the word list"
		    unless defined $index;
	}

	return;
}

# $class->digits($words):
#	The digit string of QR-MNEMONIC-3: the 12 indexes, 0-based,
#	each as 4 decimal digits with leading zeros, in word order.
#	The caller proves the words with fault first.
sub digits ( $class, $words )
{
	return join q{},
	    map { sprintf '%0' . DIGITS . 'd', $_ } $class->_indexes($words);
}

# $class->valid($words):
#	True when the 4 checksum bits of the words are the bits that
#	BIP39 requires (QR-MNEMONIC-2).
sub valid ( $class, $words )
{
	my $bits  = $class->_bits($words);
	my $typed = substr $bits, ENTROPY_BITS;

	return oct( '0b' . $typed ) == $class->_checksum($bits);
}

# $class->check_word($words):
#	The one word of the BLUE row of word 12 that makes the
#	checksum valid (QR-MNEMONIC-4). The YELLOW block and the BLUE
#	row of the typed word 12 give the 7 entropy bits of that
#	word, and the RED column gives the 4 checksum bits (D-05), so
#	the row holds exactly one valid word. The search is one
#	computation, and no trial loop exists.
sub check_word ( $class, $words )
{
	my $bits    = $class->_bits($words);
	my @indexes = $class->_indexes($words);
	my $row     = $indexes[-1] - $indexes[-1] % ( 2**CHECKSUM_BITS );

	return App::FuguSeed::List->word( $row + $class->_checksum($bits) );
}

# $class->_indexes($words):
#	The 0-based list index of each word.
sub _indexes ( $, $words )
{
	return map { App::FuguSeed::List->index($_) } @{$words};
}

# $class->_bits($words):
#	The 132 bits of the 12 indexes, as a string of "0" and "1".
sub _bits ( $class, $words )
{
	return join q{},
	    map { sprintf '%0' . INDEX_BITS . 'b', $_ }
	    $class->_indexes($words);
}

# $class->_checksum($bits):
#	The 4 checksum bits of the first 128 bits of $bits, as a
#	number. BIP39 takes them from the first bits of the SHA-256
#	of the 16 entropy bytes.
sub _checksum ( $, $bits )
{
	my $entropy = pack 'B' . ENTROPY_BITS, substr( $bits, 0, ENTROPY_BITS );
	my $digest  = Digest::SHA::sha256($entropy);

	return ord( substr $digest, 0, 1 ) >> ( 8 - CHECKSUM_BITS );
}

1;
