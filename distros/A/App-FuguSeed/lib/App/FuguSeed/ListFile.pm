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

package App::FuguSeed::ListFile;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use App::FuguSeed::List ();
use Digest::SHA         ();
use Fugu::File          ();
use Fugu::Log           ();

# App::FuguSeed::ListFile - read a word list file and prove its
# digest (LIST-SHARE-3).
#
# Both verbs of fuguseed-words take a list file. This module is the
# one reader of that file. It computes the SHA-256 of the bytes and
# it refuses every digest but the one of the source list, which
# App::FuguSeed::List pins.
#
# The digest proves the whole file, so the module needs no other
# check: the source list holds 2048 lines, and each line holds one
# word and one line feed (LIST-SOURCE-2).
#
# A recoverable failure returns undef and reports through the log,
# because a class-method module has no error accessor to hold the
# reason.

# $class->read($path):
#	Read the word list file $path. The result is a hash reference
#	with the 2048 words under "words" and the SHA-256 of the file
#	under "digest".
#
#	The method returns undef for a file that it cannot read, and
#	for a file with another digest than the source list.
sub read ( $, $path )
{
	my $log  = Fugu::Log->default;
	my $text = Fugu::File->read($path);
	unless ( defined $text ) {
		$log->error( 'cannot read the word list %s', $path );
		return;
	}

	my $digest = Digest::SHA::sha256_hex($text);
	unless ( $digest eq App::FuguSeed::List::DIGEST() ) {
		$log->error(
			'%s is not the English word list of BIP39: '
			    . 'its SHA-256 is %s',
			$path, $digest
		);
		return;
	}

	# The digest pins the bytes, so the split gives the 2048 words
	# of the source list.
	my @words = split /\n/, $text;

	return { words => \@words, digest => $digest };
}

1;
