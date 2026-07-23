# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Self-contained matching regression: the curated license fixtures scanned against all their patterns
# must produce exactly these matches (pattern id, start line, end line). The expectations are pinned
# here so the suite validates Cavil::Matcher on its own, with no reference engine. The equivalent
# cross-check against the previous engine lives in xt/differential.t (developer-only).
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Cavil::Matcher;

sub slurp { open my $fh, '<:raw', $_[0] or die $!; local $/; my $c = <$fh>; close $fh; $c }

my %pat;
for my $fn (glob('t/fixtures/licenses/04license.*.pattern')) {
  $fn =~ m/\.(\d+)\.pattern$/ or next;
  $pat{$1} = slurp($fn);
}
ok(keys %pat, 'loaded license patterns');

my $m = Cavil::Matcher::init_matcher();
$m->add_pattern($_, Cavil::Matcher::parse_tokens($pat{$_})) for sort { $a <=> $b } keys %pat;

# Pinned expected matches (regenerate deliberately if the pattern language changes).
my %EXPECTED = (
  1  => [[1, 1, 165]],
  2  => [[2, 2, 23]],
  3  => [[7, 6, 7], [4, 10, 10]],
  4  => [[11, 35, 59], [12, 6, 18], [4, 2, 2], [4, 27, 27]],
  5  => [[13, 1, 502]],
  6  => [[15, 5, 17], [4, 2, 2]],
  7  => [[16, 1, 1]],
  8  => [[19, 7, 18], [18, 5, 5], [4, 3, 3]],
  9  => [[20, 1, 29]],
  10 => [[22, 113, 114], [4, 112, 112], [3, 109, 109]],
  11 => [[25, 4, 15], [23, 2, 2], [4, 2, 2]],
  12 => [[29, 1, 115]],
  13 => [[31, 1, 1], [30, 5, 5]],
);

for my $num (sort { $a <=> $b } keys %EXPECTED) {
  cmp_deeply($m->find_matches("t/fixtures/licenses/04license.$num.txt"), $EXPECTED{$num}, "matches for fixture $num");
}

# Compiled-segment round-trip: dump the in-memory delta to a versioned segment, load it into a fresh
# matcher, and confirm matching is unchanged.
my $seg = "t/fixtures/licenses/roundtrip.$$.seg";
ok($m->dump($seg), 'dump compiled segment');
my $loaded = Cavil::Matcher::init_matcher();
ok($loaded->load($seg), 'load compiled segment');
for my $num (sort { $a <=> $b } keys %EXPECTED) {
  cmp_deeply($loaded->find_matches("t/fixtures/licenses/04license.$num.txt"),
    $EXPECTED{$num}, "loaded-segment matches for fixture $num");
}
unlink $seg;

done_testing();
