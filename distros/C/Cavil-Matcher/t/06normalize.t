# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# normalize() turns text into [line, token, hash] rows using the same tokenizer as parse_tokens. The
# hashes are pinned (they must never drift, or stored snippet checksums would change).
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Cavil::Matcher;

# Known token hashes (also asserted in t/02parse.t).
my $HELLO = 11695443286496022098;
my $WORLD = 14227499413149678217;

cmp_deeply(
  Cavil::Matcher::normalize('Hello World'),
  [[1, 'hello', $HELLO], [1, 'world', $WORLD]],
  'single line: tokens, lower-cased, with line 1'
);

cmp_deeply(
  Cavil::Matcher::normalize("Hello\nWorld"),
  [[1, 'hello', $HELLO], [2, 'world', $WORLD]],
  'line numbers advance across newlines'
);

# Punctuation and markup noise is dropped; comment leaders never need literal matching.
cmp_deeply(Cavil::Matcher::normalize(' *;,: '), [], 'punctuation-only normalizes to nothing');
cmp_deeply(Cavil::Matcher::normalize(''),       [], 'empty input normalizes to nothing');

# $SKIP is only meaningful in patterns, never in scanned/normalized text: here it is a literal token.
my $norm = Cavil::Matcher::normalize('hello $SKIP5 world');
is(scalar @$norm,      3, 'skip token kept as a literal word in normalized text');
is($norm->[1][2] > 99, 1, 'the literal "$skip5" hashes to a real token, not a skip value');

done_testing();
