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

package App::FuguBench::Version;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

use Fugu;
use Fugu::CLI qw(EXIT_SUCCESS);

# App::FuguBench::Version - the version verb.
#
# The dist build stamps our $VERSION into every staged package, so a
# checkout carries no stamp and reports 0.0.0. The Fugu version is
# the version of the loaded library: the installed one in a checkout,
# and the snapshot in the pack.

use constant NO_STAMP => '0.0.0';

# App::FuguBench::Version->command($verb):
#	The entry of the Fugu::CLI table. The module holds one verb,
#	so it ignores the name.
sub command ( $, $ )
{
	return {
		summary => 'print the version',
		run     => sub ( $, @ ) {
			say __PACKAGE__->line;

			return EXIT_SUCCESS;
		},
	};
}

# App::FuguBench::Version->line:
#	The line of the verb: the version of the program and the
#	version of the Fugu library beside it.
#
#	The doctor reports this line as its version check, so the two
#	verbs never name a different version.
sub line ($)
{
	return sprintf 'fugubench %s (Fugu %s)',
	    App::FuguBench->VERSION // NO_STAMP,
	    Fugu->VERSION           // NO_STAMP;
}

1;
