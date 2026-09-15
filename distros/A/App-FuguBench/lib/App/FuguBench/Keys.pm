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

package App::FuguBench::Keys;
our $VERSION = '0.1.0';

use v5.34;
use warnings;
use experimental 'signatures';
no feature qw(indirect multidimensional bareword_filehandles);

# App::FuguBench::Keys - the embedded release keys.
#
# The program embeds the release public keys of the organization in
# one module (DIST-KEY-1). A release then carries the keys that verify
# the next release, and no file of the host decides what it trusts.
#
# The keys are those of deps/KEYS.txt of the org pack, and
# t/fugubench/keys.t holds this module to that file.
#
# The line order of that file is the trust order, and the current key
# comes first. A rotation is a release of the program, and the old key
# stays in the list for one release after the new key enters it
# (DIST-KEY-3).
#
# DIST-KEY-2 gives this list to `update` alone. The `deps` verb
# verifies with the keys of the consumer, because a consumer decides
# what it trusts.
#
# A body is the 56 base64 characters of a signify public key: the
# second line of a .pub file. A public key carries no secret, so the
# list is source.

use constant KEYS => [ [
		'fugubsd-1-release',
		'RWRKSCtmq6YKnnWf4QcNV24EEspYWDvMZO7QhWrSKCqRpdWY+XYQsm9g'
	],
];

# App::FuguBench::Keys->keys:
#	The [name, body] pair of each release key, in trust order.
sub keys ($)
{
	return @{ +KEYS };
}

1;
