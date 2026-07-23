# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# The content hash must be bit-identical to the previous engine so that snippets.hash and
# ignored_lines.hash stay valid across the engine swap (no rehash migration). Values are copied
# verbatim from Spooky::Patterns::XS t/06hash.t.
use strict;
use warnings;
use Test::More;
use Cavil::Matcher;
use utf8;

my $h = Cavil::Matcher::init_hash(0, 0);
$h->add("Hállöchen\n");
$h->add("abc\x{300}");
is($h->hex,    'd6d58320114a2d3c1d6dd671ab0383ec', 'hex digest identical to previous engine');
is($h->hash64, 15480423467908214076,               'hash64 identical to previous engine');

$h = Cavil::Matcher::init_hash(0, 0);
$h->add("/* \n");
$h->add("** Invoke the authorization callback for permission to read column zCol from \n");
$h->add("** table zTab in database zDb. This function assumes that an authorization\n");
is($h->hex, '06a8354a1a3a0934b5b4c88496411563', 'chunked add digest identical');

done_testing();
