# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# parse_tokens and the token hashes must be bit-identical to the previous engine
# (Spooky::Patterns::XS), so stored pattern checksums stay valid with no migration.
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Cavil::Matcher;

Cavil::Matcher::init_matcher();

# Exact values from Spooky::Patterns::XS t/02compile.t - proves identical tokenizer + SpookyHash.
cmp_deeply(
  Cavil::Matcher::parse_tokens('Hello World'),
  [11695443286496022098, 14227499413149678217],
  'two tokens, identical hashes'
);

# Leading and trailing skips are stripped; a pattern is anchored on real words at both ends.
my $skip_start = Cavil::Matcher::parse_tokens('$SKIP5 hello world');
is($skip_start->[0],     11695443286496022098, 'leading skip dropped');
is(scalar(@$skip_start), 2,                    'leading skip leaves two real tokens');

my $skip_end = Cavil::Matcher::parse_tokens('hello world $SKIP5');
is(scalar(@$skip_end), 2, 'trailing skip dropped');

# A middle skip stays, represented by its small integer value (1..99).
my $skip_mid = Cavil::Matcher::parse_tokens('hello $SKIP5 world');
cmp_deeply($skip_mid, [11695443286496022098, 5, 14227499413149678217], 'middle skip kept as value');

# $SKIP over the cap is not a skip - it becomes a literal token.
my $big = Cavil::Matcher::parse_tokens('hello $SKIP500 world');
is(scalar(@$big), 3, 'oversized skip becomes a literal token');
cmp_ok($big->[1], '>', 99, 'oversized skip is a real hash, not a skip value');

# Empty and punctuation-only input yield no tokens.
cmp_deeply(Cavil::Matcher::parse_tokens(''),       [], 'empty string, no tokens');
cmp_deeply(Cavil::Matcher::parse_tokens(' *;,: '), [], 'punctuation only, no tokens');

done_testing();
