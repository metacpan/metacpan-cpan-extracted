# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# distance() is a *compatibility* token distance over normalize() output - deliberately NOT strict
# Levenshtein: it reproduces the previous engine's off-by-one (see the note in Cavil::Matcher's POD), so
# do not "fix" it toward true Levenshtein without breaking byte-parity. Self-contained: a pinned value on
# the fixtures, identity, and robustness on degenerate input.
use strict;
use warnings;
use Test::More;
use Cavil::Matcher;

sub slurp { open my $fh, '<:raw', $_[0] or die $!; local $/; my $c = <$fh>; close $fh; $c }

my $p1 = Cavil::Matcher::normalize(slurp('t/fixtures/text/07close.p1'));
my $p2 = Cavil::Matcher::normalize(slurp('t/fixtures/text/07close.p2'));

is(Cavil::Matcher::distance($p1, $p2), 4, 'pinned distance between the two close fixtures');
is(Cavil::Matcher::distance($p1, $p1), 0, 'distance to self is zero');

# Never crash on empty / single-token inputs (av_len is -1 for an empty array).
for my $pair (
  [[],                               []],
  [Cavil::Matcher::normalize(''),    Cavil::Matcher::normalize('word')],
  [Cavil::Matcher::normalize('one'), Cavil::Matcher::normalize('two words here')]
  )
{
  my $d = Cavil::Matcher::distance($pair->[0], $pair->[1]);
  ok(defined $d && $d >= 0, 'distance stays sane on degenerate input');
}

# distance() is public, so it must never crash even on arrays that are not normalize() output -
# plain scalars, wrong-shaped rows, non-array refs, sparse arrays. Malformed cells count as hash 0.
for my $pair (
  [[1, 2, 3],                          [4, 5, 6]],         # plain scalars, not array refs
  [[{}, {}],                           [[1, 'a', 99]]],    # hash refs where rows expected
  [['x'],                              [\1]],              # scalar + scalar ref
  [[[1, 'a', 5]],                      [[1, 'a']]],        # a row missing the hash column
  [Cavil::Matcher::normalize('a b c'), [1, 2, 3]]          # one valid side, one malformed
  )
{
  my $d = eval { Cavil::Matcher::distance($pair->[0], $pair->[1]) };
  ok(!$@ && defined $d && $d >= 0, 'distance never crashes on malformed input');
}

done_testing();
