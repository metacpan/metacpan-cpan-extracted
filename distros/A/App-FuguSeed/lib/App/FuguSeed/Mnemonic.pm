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
our $VERSION = '0.2.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Digest::SHA ();

use App::FuguSeed::List ();

# App::FuguSeed::Mnemonic - the word checks and the BIP39 checksum.
#
# The module proves the count and the list membership of the words
# (QR-MNEMONIC-1, LAST-WORD-1), it gives the index of each word, and
# it computes the BIP39 checksum (QR-MNEMONIC-2, LAST-WORD-4). It
# holds the parts that fuguseed-last and fuguseed-qr both call, and
# no other part.
#
# Every method is a class method, and every method is pure: it takes
# values and it returns values. The module touches no stream. A
# caller gets the failure message and prints it, and the message
# names a count or a word position, never a word (SEC-CHANNELS-2).
#
# The module runs on core perl v5.34 with Digest::SHA alone, because
# scripts/pack embeds it in fuguseed-last and fuguseed-qr (D-07).

# INDEX_BITS:
#	The bit width of one word index. The list holds 2048 words,
#	so an index needs 11 bits (BIP39).
use constant INDEX_BITS => 11;

# ENTROPY_BITS:
#	The entropy bits of 12 words. The 12 indexes give 132 bits,
#	and the 4 bits after the entropy are the checksum (BIP39).
use constant ENTROPY_BITS => 128;

# CHECKSUM_BITS:
#	The checksum bits of 12 words (BIP39). The RED column of the
#	word sheet carries them, because it gives the low 4 bits of
#	an index (D-05).
use constant CHECKSUM_BITS => 4;

# $class->fault($words, $count):
#	The failure message for the words of the array reference
#	$words, or undef when they are $count words of the list. The
#	message names a count or a word position, never a word.
sub fault ( $, $words, $count )
{
	my $found = scalar @{$words};
	return "the input holds $found words, not $count"
	    if $found != $count;

	for my $position ( 1 .. $count ) {
		my $index =
		    App::FuguSeed::List->index( $words->[ $position - 1 ] );
		return "word $position is not in the word list"
		    unless defined $index;
	}

	return;
}

# $class->indexes($words):
#	The 0-based list index of each word. The caller proves the
#	words with fault first.
sub indexes ( $, $words )
{
	return map { App::FuguSeed::List->index($_) } @{$words};
}

# $class->checksum(@index):
#	The 4 checksum bits of the 12 indexes @index, as a number.
#	The 12 indexes give 132 bits, and the first 128 bits are the
#	entropy. BIP39 takes the checksum from the first bits of the
#	SHA-256 of the 16 entropy bytes. The low 4 bits of index 12
#	are no part of the entropy, so they do not change the result.
sub checksum ( $, @index )
{
	my $bits = join q{}, map { sprintf '%0' . INDEX_BITS . 'b', $_ } @index;
	my $entropy = pack 'B' . ENTROPY_BITS, substr( $bits, 0, ENTROPY_BITS );
	my $digest  = Digest::SHA::sha256($entropy);

	return ord( substr $digest, 0, 1 ) >> ( 8 - CHECKSUM_BITS );
}

1;
