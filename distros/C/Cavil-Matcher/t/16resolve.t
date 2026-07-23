# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Overlap resolution: the frozen semantics (longer match wins; exact tie -> higher/newer id; results
# emitted in that priority order) must hold, and it must stay fast when a file produces very many
# matches. The resolver is O(R log R) in the number of raw matches R; the previous rescan-the-whole-set
# approach was O(R^2), a real risk on keyword-heavy files. The exhaustive parity check against the old
# engine over the real corpus lives in xt/differential.t; this pins the semantics on hand-verifiable
# cases and guards the many-matches scale case the corpus does not stress.
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Cavil::Matcher;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);

sub write_file {
  my ($name, $content) = @_;
  my $p = "$dir/$name";
  open my $fh, '>:raw', $p or die $!;
  print {$fh} $content;
  close $fh;
  return $p;
}

# (Words are chosen to avoid the tokenizer's ignore list - e.g. "cc", "a", "c", "n", "r" are dropped.)

# --- Longer match wins; overlapped shorter matches are dropped ------------------------------------
{
  my $m = Cavil::Matcher::init_matcher;
  $m->add_pattern(10, Cavil::Matcher::parse_tokens('alpha bravo charlie'));
  $m->add_pattern(11, Cavil::Matcher::parse_tokens('bravo charlie'));
  $m->add_pattern(12, Cavil::Matcher::parse_tokens('charlie delta'));
  my $f = write_file('longest', "alpha bravo charlie delta\n");
  cmp_deeply($m->find_matches($f), [[10, 1, 1]], 'the longest match wins and suppresses overlapping shorter ones');
}

# --- Non-overlapping matches all survive, emitted longest-first then by descending id -------------
{
  my $m = Cavil::Matcher::init_matcher;
  $m->add_pattern(30, Cavil::Matcher::parse_tokens('alpha bravo'));
  $m->add_pattern(31, Cavil::Matcher::parse_tokens('charlie delta'));
  my $f = write_file('tie', "alpha bravo charlie delta\n");

  # Both matches are length 2 and do not overlap, so both survive; on the length tie the higher id is
  # emitted first (frozen tie-break).
  cmp_deeply($m->find_matches($f), [[31, 1, 1], [30, 1, 1]], 'tie in length -> higher id emitted first, both kept');
}

# --- Removing a long match reveals a later, disjoint short one -----------------------------------
{
  my $m = Cavil::Matcher::init_matcher;
  $m->add_pattern(20, Cavil::Matcher::parse_tokens('alpha bravo charlie delta echo'));
  $m->add_pattern(21, Cavil::Matcher::parse_tokens('golf hotel'));
  my $f = write_file('disjoint', "alpha bravo charlie delta echo foxtrot golf hotel\n");
  cmp_deeply($m->find_matches($f), [[20, 1, 1], [21, 1, 1]], 'disjoint matches both survive, longest first');
}

# --- Scale: many non-overlapping matches (the keyword-heavy case) resolve correctly and quickly ---
# This is the regression guard for the old O(R^2) resolver: at O(R^2) this many matches would be slow;
# correctness is what we assert (one match per line, in order), which also proves nothing is dropped.
{
  my $m = Cavil::Matcher::init_matcher;
  $m->add_pattern(1, Cavil::Matcher::parse_tokens('permission is hereby granted'));

  my $n        = 8000;
  my $f        = write_file('many', ("permission is hereby granted\n" x $n));
  my $got      = $m->find_matches($f);
  my $expected = [map { [1, $_, $_] } 1 .. $n];
  is(scalar @$got, $n, "all $n non-overlapping matches are resolved (none dropped)");
  cmp_deeply($got, $expected, 'each match is pattern 1 on its own line, in file order');
}

done_testing();
