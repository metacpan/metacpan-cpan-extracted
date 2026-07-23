# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# The Perl lifecycle layer: incremental add/remove without rebuilding the cache, generation pinning,
# compaction (merge), atomic manifest, and resilience to on-disk damage.
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Cavil::Matcher;
use Cavil::Matcher::Index;
use Cavil::Matcher::Manifest;
use File::Temp qw(tempdir);
use JSON::PP   qw(decode_json);

sub slurp          { open my $fh, '<:raw', $_[0] or die $!; local $/; my $c = <$fh>; close $fh; $c }
sub sorted_matches { [sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @{$_[0]}] }
sub nfiles         { my @f = glob $_[0]; scalar @f }    # glob in scalar context is an iterator, not a count

# Real patterns, split into two halves.
my %pat;
for my $fn (glob('t/fixtures/licenses/04license.*.pattern')) {
  $fn =~ m/\.(\d+)\.pattern$/ or next;
  $pat{$1} = slurp($fn);
}
my @ids   = sort { $a <=> $b } keys %pat;
my $half  = int(@ids / 2);
my @first = map { [$_, $pat{$_}] } @ids[0 .. $half - 1];
my @rest  = map { [$_, $pat{$_}] } @ids[$half .. $#ids];

# Reference matcher with every pattern.
my $all = Cavil::Matcher::init_matcher();
$all->add_pattern($_, Cavil::Matcher::parse_tokens($pat{$_})) for @ids;

my @txts = sort glob('t/fixtures/licenses/04license.*.txt');

# --- Empty index finds nothing (bootstrapping) ---------------------------------------------------
my $dir = tempdir(CLEANUP => 1);
my $idx = Cavil::Matcher::Index->new(dir => $dir);
is($idx->generation, 0, 'fresh index at generation 0');
cmp_deeply($idx->matcher->find_matches($txts[0]), [], 'empty index matches nothing');

# --- Incremental add: first segment --------------------------------------------------------------
my $g1 = $idx->add_segment(\@first);
is($g1, 1, 'first add is generation 1');
my $seg1_path  = (glob("$dir/seg-*.seg"))[0];
my $seg1_bytes = slurp($seg1_path);

# --- Incremental add: second segment. The first segment file must be byte-unchanged (no rebuild) ---
my $g2 = $idx->add_segment(\@rest);
is($g2,                      2,           'second add is generation 2');
is(slurp($seg1_path),        $seg1_bytes, 'existing segment file is byte-identical after an add (no rebuild)');
is(nfiles("$dir/seg-*.seg"), 2,           'two segment files on disk');

# Union of the two incrementally-added segments equals the single all-patterns matcher.
for my $fn (@txts) {
  cmp_deeply(
    sorted_matches($idx->matcher->find_matches($fn)),
    sorted_matches($all->find_matches($fn)),
    "incremental index equals full matcher for $fn"
  );
}

# --- Tombstone: equals a corpus that never had the victim ----------------------------------------
my $victim = $ids[0];
my $g3     = $idx->tombstone($victim);
is($g3, 3, 'tombstone bumps generation');
my $without = Cavil::Matcher::init_matcher();
$without->add_pattern($_, Cavil::Matcher::parse_tokens($pat{$_})) for grep { $_ != $victim } @ids;
for my $fn (@txts) {
  cmp_deeply(
    sorted_matches($idx->matcher->find_matches($fn)),
    sorted_matches($without->find_matches($fn)),
    "tombstoned index equals corpus-without-victim for $fn"
  );
}

# --- merge: compaction to a single base segment, tombstones baked away ----------------------------
# The authoritative set for the merge is "all patterns except the tombstoned victim".
my @authoritative = map { [$_, $pat{$_}] } grep { $_ != $victim } @ids;
my $g4            = $idx->merge(\@authoritative);
is($g4,                                 4, 'merge bumps generation');
is(nfiles("$dir/base-*.seg"),           1, 'one base segment after merge');
is(scalar @{$idx->_manifest->segments}, 1, 'manifest holds only the base after merge (deltas retired)');
like($idx->_manifest->segments->[0]{file}, qr/^base-/, 'the sole active segment is the base');
is(scalar @{$idx->_manifest->tombstones}, 0, 'tombstones cleared after merge');

# The engine exposes the generation it was pinned to, race-free (no re-read of the index needed), so a
# report can record exactly the generation it scanned with.
is($idx->matcher->generation, $g4, 'the built engine reports its pinned generation');

# Deferred deletion: the retired delta files stay on disk one more cycle so a reader that read the old
# manifest can still mmap them (readers do not lock); the next merge collects them. (The next-merge
# collection itself is covered in t/14coverage.t.)
is(nfiles("$dir/seg-*.seg"), 2, 'retired delta segments remain on disk until the next merge');
for my $fn (@txts) {
  cmp_deeply(
    sorted_matches($idx->matcher->find_matches($fn)),
    sorted_matches($without->find_matches($fn)),
    "merged index still equals corpus-without-victim for $fn"
  );
}

# --- Manifest is valid, pretty JSON with the expected shape, and no temp files linger --------------
my $manifest = decode_json(slurp("$dir/manifest.json"));
is($manifest->{format_version}, 1, 'manifest format version');
is($manifest->{generation},     4, 'manifest generation persisted');
ok(ref $manifest->{segments} eq 'ARRAY', 'manifest lists segments');
is(nfiles("$dir/manifest.json.tmp.*"), 0, 'no temp manifest left behind');

# --- Resilience: a corrupted segment on disk is skipped, never crashes ----------------------------
my $base = (glob("$dir/base-*.seg"))[0];
open my $cfh, '>:raw', $base or die $!;
print {$cfh} 'corrupted';    # truncate/garble the compiled segment
close $cfh;
my $res = eval { $idx->matcher(quiet => 1)->find_matches($txts[0]) };
ok(!$@, 'corrupted segment does not crash matcher()');
cmp_deeply($res, [], 'corrupted segment is skipped (checksum/validation), index degrades to empty');

# --- Resilience: a totally unreadable manifest reads as empty -------------------------------------
my $dir2 = tempdir(CLEANUP => 1);
open my $bad, '>:raw', "$dir2/manifest.json" or die $!;
print {$bad} "\x00\x01 not json at all";
close $bad;
my $idx2 = Cavil::Matcher::Index->new(dir => $dir2);
is($idx2->generation, 0, 'unparseable manifest reads as empty');
cmp_deeply($idx2->matcher->find_matches($txts[0]), [], 'index with unreadable manifest finds nothing');

done_testing();
