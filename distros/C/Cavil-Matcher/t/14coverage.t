# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Exercises the error and edge paths of the pure-Perl lifecycle layer (Index + Manifest): argument
# validation, no-op guards, compaction failure, corrupt/missing segments and manifests. These are the
# resilience behaviours that keep indexing a whole distribution from ever dying.
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Cavil::Matcher;
use Cavil::Matcher::Index;
use Cavil::Matcher::Manifest;
use File::Temp qw(tempdir);
use File::Spec;

my $sample = [[1, 'permission is hereby granted free of charge']];

# --- Index construction -------------------------------------------------------------------------
eval { Cavil::Matcher::Index->new };
like($@, qr/dir required/, 'Index->new without dir croaks');

my $root  = tempdir(CLEANUP => 1);
my $afile = "$root/a-file";
open my $ftmp, '>', $afile or die $!;
close $ftmp;
eval { Cavil::Matcher::Index->new(dir => $afile) };
like($@, qr/not a directory/, 'Index->new on a plain file croaks');

my $newdir = "$root/created";
ok(!-d $newdir, 'target dir does not exist yet');
my $idx = Cavil::Matcher::Index->new(dir => $newdir);
ok(-d $newdir, 'Index->new creates a missing dir');
is($idx->dir, $newdir, 'dir() accessor');

# --- No-op guards -------------------------------------------------------------------------------
is($idx->add_segment([]),    0, 'add_segment([]) is a no-op at generation 0');
is($idx->add_segment(undef), 0, 'add_segment(undef) is a no-op');
is($idx->tombstone(),        0, 'tombstone() with no ids is a no-op');
is($idx->merge(undef),       1, 'merge(undef) builds an empty base at generation 1');

# --- Compile failures croak (force by colliding the target name with a directory) ----------------
my $d2   = tempdir(CLEANUP => 1);
my $idx2 = Cavil::Matcher::Index->new(dir => $d2);
mkdir "$d2/seg-0000000001.seg";
eval { $idx2->add_segment($sample) };
like($@, qr/failed to compile segment/, 'add_segment croaks when the segment file cannot be written');

my $d3   = tempdir(CLEANUP => 1);
my $idx3 = Cavil::Matcher::Index->new(dir => $d3);
mkdir "$d3/base-0000000001.seg";
eval { $idx3->merge($sample) };
like($@, qr/failed to compile base segment/, 'merge croaks when the base file cannot be written');

# --- matcher() resilience: missing / checksum-mismatch / attach-fail segments --------------------
my $d4   = tempdir(CLEANUP => 1);
my $idx4 = Cavil::Matcher::Index->new(dir => $d4);
$idx4->add_segment($sample);    # a real segment at generation 1
my ($real_seg) = glob "$d4/seg-*.seg";

# Append a manifest entry for a segment that is not on disk.
my $man = Cavil::Matcher::Manifest->new(dir => $d4);
$man->add_segment(file => 'ghost.seg', checksum => 'deadbeef');
$man->save;

my @warns;
{
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  $idx4->matcher;    # non-quiet
}
ok((grep {/ghost\.seg missing/} @warns), 'warns about a missing segment (non-quiet)');

@warns = ();
{
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  $idx4->matcher(quiet => 1);
}
is(scalar @warns, 0, 'quiet suppresses the missing-segment warning');

# Corrupt the real segment so its bytes no longer match the manifest checksum.
open my $cf, '>>:raw', $real_seg or die $!;
print {$cf} 'zzzz';
close $cf;
@warns = ();
{
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  $idx4->matcher;
}
ok((grep {/checksum mismatch/} @warns), 'warns on a checksum mismatch');

# A segment whose manifest checksum is empty skips the checksum check but still fails validation.
my $d5   = tempdir(CLEANUP => 1);
my $idx5 = Cavil::Matcher::Index->new(dir => $d5);
open my $junk, '>:raw', "$d5/junk.seg" or die $!;
print {$junk} 'not a valid compiled segment';
close $junk;
my $m5 = Cavil::Matcher::Manifest->new(dir => $d5);
$m5->add_segment(file => 'junk.seg', checksum => '');    # empty checksum => pattern_count defaults to 0 too
$m5->save;
@warns = ();
my $eng5;
{
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  $eng5 = $idx5->matcher;
}
ok((grep {/junk\.seg failed validation/} @warns), 'warns when a segment fails to attach');
cmp_deeply($eng5->find_matches('t/fixtures/licenses/04license.1.txt'),
  [], 'index with only a bad segment finds nothing');

@warns = ();
{
  local $SIG{__WARN__} = sub { push @warns, $_[0] };
  $idx5->matcher(quiet => 1);
}
is(scalar @warns, 0, 'quiet suppresses the attach-failure warning');

# A manifest entry with no checksum at all (e.g. an older manifest) skips the integrity check and
# still attaches a valid segment.
my $d7   = tempdir(CLEANUP => 1);
my $idx7 = Cavil::Matcher::Index->new(dir => $d7);
$idx7->add_segment($sample);
my ($seg7) = glob "$d7/seg-*.seg";
my $m7 = Cavil::Matcher::Manifest->new(dir => $d7);
$m7->add_segment(file => (File::Spec->splitpath($seg7))[2], checksum => undef);
$m7->save;
ok(ref $idx7->matcher(quiet => 1)->find_matches('t/fixtures/licenses/04license.1.txt') eq 'ARRAY',
  'segment with an undefined checksum still attaches');

# --- Manifest edge cases ------------------------------------------------------------------------
eval { Cavil::Matcher::Manifest->new };
like($@, qr/dir required/, 'Manifest->new without dir croaks');

my $d6 = tempdir(CLEANUP => 1);
sub write_manifest { open my $fh, '>:raw', "$d6/manifest.json" or die $!; print {$fh} $_[0]; close $fh }

write_manifest('{"format_version":999,"generation":7}');
is(Cavil::Matcher::Manifest->new(dir => $d6)->generation, 0, 'wrong format version reads as empty');

write_manifest('{"generation":5}');    # missing format_version
is(Cavil::Matcher::Manifest->new(dir => $d6)->generation, 0, 'missing format version reads as empty');

write_manifest('{"format_version":1,"segments":[]}');    # valid, but no generation key
is(Cavil::Matcher::Manifest->new(dir => $d6)->generation, 0, 'missing generation defaults to 0');

write_manifest('{"format_version":1,"generation":2,"segments":"nope","tombstones":"nope"}');
my $mm = Cavil::Matcher::Manifest->new(dir => $d6);
is($mm->generation, 2, 'generation preserved from a valid manifest');
ok(ref $mm->data eq 'HASH', 'data() accessor');
is_deeply($mm->segments,   [], 'non-array segments normalized to []');
is_deeply($mm->tombstones, [], 'non-array tombstones normalized to []');

$mm->add_segment(file => 'x.seg', checksum => 'abc');    # no pattern_count -> defaults to 0
is($mm->segments->[0]{pattern_count}, 0, 'pattern_count defaults to 0');

$mm->add_tombstones(1, 2, 3);
$mm->add_tombstones(2, 3, 4);                            # duplicates ignored
is_deeply([sort { $a <=> $b } @{$mm->tombstones}], [1, 2, 3, 4], 'tombstone ids de-duplicated');

# A structurally-malformed manifest (non-hash segments, unsafe/traversal filenames, ref checksums,
# bad pattern_count, non-integer generation, non-scalar tombstones) must be sanitized, not fatal.
write_manifest(<<'JSON');
{"format_version":1,"generation":"not-a-number",
 "segments":["a-string-not-a-hash",
             {"file":"../evil.seg"},
             {"file":"sub/dir.seg"},
             {"file":null},
             {"file":[]},
             {"file":""},
             {"file":"a..b.seg"},
             {"file":"weird.seg","checksum":{"x":1},"pattern_count":"nan"},
             {"file":"good-seg.seg","checksum":"abc","pattern_count":"5"},
             {"file":"bare.seg"},
             {"file":"countref.seg","pattern_count":{}}],
 "tombstones":[1,2,{"x":1},null,"7",4294967297,"99999999999",-5,3.5]}
JSON
my $bad = Cavil::Matcher::Manifest->new(dir => $d6);
is($bad->generation,         0, 'non-integer generation sanitized to 0');
is(scalar @{$bad->segments}, 4, 'only safe, well-formed segment entries survive');
is_deeply(
  $bad->segments,
  [
    {file => 'weird.seg',    checksum => '',    pattern_count => 0},
    {file => 'good-seg.seg', checksum => 'abc', pattern_count => 5},
    {file => 'bare.seg',     checksum => '',    pattern_count => 0},
    {file => 'countref.seg', checksum => '',    pattern_count => 0}
  ],
  'segment fields coerced (ref/empty/traversal names dropped; ref checksum -> "", bad count -> 0)'
);
is_deeply(
  [@{$bad->tombstones}],
  [1, 2, '7'],
  'tombstones sanitized: refs, undef, out-of-range (>uint32), negative and non-integer ids dropped'
);

# Generation given as a non-scalar is also sanitized rather than fatal.
write_manifest('{"format_version":1,"generation":{"x":1}}');
is(Cavil::Matcher::Manifest->new(dir => $d6)->generation, 0, 'non-scalar generation sanitized to 0');

# An over-large generation (beyond exact integer representation) is treated as corrupt and reset, so the
# next mutation cannot lose precision and derive a garbage segment filename.
write_manifest('{"format_version":1,"generation":"999999999999999999999999"}');
is(Cavil::Matcher::Manifest->new(dir => $d6)->generation, 0, 'an over-large generation is reset to 0');

# And the reader (matcher) must not die on it - it degrades to the well-formed (here: missing) segments.
my $bad_idx = Cavil::Matcher::Index->new(dir => $d6);
my $eng     = eval { $bad_idx->matcher(quiet => 1) };
ok(!$@, 'matcher() survives a malformed manifest');
cmp_deeply($eng->find_matches('t/fixtures/licenses/04license.1.txt'), [], 'malformed-manifest index finds nothing');

# --- remove_tombstones: drop named ids, no-op on empty input -------------------------------------
my $drt = tempdir(CLEANUP => 1);
my $rt  = Cavil::Matcher::Manifest->new(dir => $drt);
$rt->add_tombstones(1, 2, 3, 4);
$rt->remove_tombstones();            # no-op
is_deeply([sort { $a <=> $b } @{$rt->tombstones}], [1, 2, 3, 4], 'remove_tombstones() with no ids is a no-op');
$rt->remove_tombstones(2, 4, 99);    # 99 is not present; ignored
is_deeply([sort { $a <=> $b } @{$rt->tombstones}], [1, 3], 'remove_tombstones drops exactly the named ids');

# --- add_segment un-suppresses a re-added id -----------------------------------------------------
# Tombstoning an id then re-adding it in a new segment must clear its tombstone, so it matches again
# immediately (no wait for a merge). This is the lifecycle safety net for id reuse/restore.
my $dre = tempdir(CLEANUP => 1);
my $ire = Cavil::Matcher::Index->new(dir => $dre);
my $tgt = "$dre/target.txt";
open my $tf, '>:raw', $tgt or die $!;
print {$tf} "permission is hereby granted\n";
close $tf;
$ire->add_segment([[1, 'permission is hereby granted']]);
$ire->tombstone(1);
is(scalar @{$ire->matcher(quiet => 1)->find_matches($tgt)}, 0, 'a tombstoned id is suppressed');
$ire->add_segment([[1, 'permission is hereby granted']]);    # re-introduce id 1
is_deeply($ire->_manifest->tombstones, [], 're-adding an id clears its tombstone');
cmp_ok(scalar @{$ire->matcher(quiet => 1)->find_matches($tgt)}, '>', 0, 'the re-added id matches again');
ok(-e File::Spec->catfile($dre, '.lock'), 'a mutation takes (and leaves) the per-index advisory lock file');

# --- save() cleans up its temp file on a failed write --------------------------------------------
# Force the rename to fail by making manifest.json a directory; save must remove its manifest.json.tmp.<pid>
# rather than leaving litter, and still report the error.
my $dsv = tempdir(CLEANUP => 1);
mkdir "$dsv/manifest.json" or die $!;                        # rename onto a directory fails
my $sv = Cavil::Matcher::Manifest->new(dir => $dsv);
$sv->add_segment(file => 'x.seg', checksum => 'abc');
eval { $sv->save };
like($@, qr/cannot rename manifest/, 'save croaks when the manifest cannot be written');
is(scalar(my @leftover = glob "$dsv/manifest.json.tmp.*"), 0, 'no temp file is left behind after a failed save');

# --- tombstone() validates ids at the public boundary (like add_pattern) -------------------------
# A bad id must fail loudly, not bump the generation and record a tombstone the engine can never apply.
my $dtb = tempdir(CLEANUP => 1);
my $itb = Cavil::Matcher::Index->new(dir => $dtb);
eval { $itb->tombstone(4294967297) };
like($@, qr/out of range/, 'tombstone croaks on an id above 2^32-1');
eval { $itb->tombstone(0) };
like($@, qr/out of range/, 'tombstone croaks on id 0');
eval { $itb->tombstone('nope') };
like($@, qr/out of range/, 'tombstone croaks on a non-integer id');
eval { $itb->tombstone(undef) };
like($@, qr/out of range/, 'tombstone croaks on an undef id');
eval { $itb->tombstone(5, {}) };
like($@, qr/out of range/, 'tombstone croaks if any id is a ref');
is($itb->generation, 0, 'a rejected tombstone does not bump the generation');

# A valid id is still recorded normally.
$itb->add_segment([[5, 'permission is hereby granted']]);
$itb->tombstone(5);
is_deeply($itb->_manifest->tombstones, [5], 'a valid tombstone id is recorded');

# --- Empty-normalized patterns are not recorded as indexed (honest pattern_count) ----------------
# A row that is all punctuation/ignored words parses to no tokens and can never match; it must not bump
# the generation or inflate pattern_count with a phantom "indexed" pattern.
my $dep = tempdir(CLEANUP => 1);
my $iep = Cavil::Matcher::Index->new(dir => $dep);
is($iep->add_segment([[1, ' *;,: ']]),  0, 'adding only an empty-normalized pattern is a no-op (no generation bump)');
is(scalar @{$iep->_manifest->segments}, 0, 'no segment is written for an empty-normalized pattern');

# A mixed batch records only the compilable rows in pattern_count.
$iep->add_segment([[2, ' .. '], [3, 'permission is hereby granted']]);
is($iep->_manifest->segments->[0]{pattern_count}, 1, 'pattern_count reflects compiled patterns, not requested rows');

# --- merge defers deleting retired segments so a racing reader can still mmap them ----------------
# merge must NOT delete the segments it retires (a reader that read the old manifest may be about to open
# them); it deletes only orphans left by a PREVIOUS merge. So the retired file survives one merge and is
# collected by the next.
my $dmg = tempdir(CLEANUP => 1);
my $img = Cavil::Matcher::Index->new(dir => $dmg);
$img->add_segment([[1, 'permission is hereby granted']]);
my ($seg1) = map { (File::Spec->splitpath($_))[2] } glob "$dmg/seg-*.seg";
ok($seg1, 'a delta segment exists after add_segment');

$img->merge([[1, 'permission is hereby granted'], [2, 'redistributions of source code']]);
my ($base2) = map { (File::Spec->splitpath($_))[2] } glob "$dmg/base-*.seg";
ok(-e "$dmg/$seg1", 'merge keeps the just-retired delta segment (racing readers can still open it)');
is_deeply([map { $_->{file} } @{$img->_manifest->segments}], [$base2], 'manifest references only the new base');

$img->merge([[1, 'permission is hereby granted']]);
ok(!-e "$dmg/$seg1", 'the next merge finally collects the earlier retired delta segment');
ok(-e "$dmg/$base2", 'the base retired by THIS merge is itself kept one more cycle');

my $mtgt = "$dmg/probe.txt";
open my $mf, '>:raw', $mtgt or die $!;
print {$mf} "permission is hereby granted\n";
close $mf;
cmp_ok(scalar @{$img->matcher(quiet => 1)->find_matches($mtgt)}, '>', 0, 'the merged index still matches throughout');
ok($img->matcher(strict => 1), 'strict matcher() returns an engine when the index is healthy');

# A crash-leftover temp file (a hard kill between write and rename) is swept by the next merge.
my $stale = "$dmg/base-0000000099.seg.tmp.12345";
open my $sfh, '>:raw', $stale or die $!;
print {$sfh} 'junk';
close $sfh;
$img->merge([[1, 'permission is hereby granted']]);
ok(!-e $stale, 'merge sweeps a crash-leftover .tmp file');

# --- strict mode fails closed on a degraded index -----------------------------------------------
# Default is best-effort (warn + skip a bad segment, still return an engine); strict => 1 refuses to
# build a matcher against an incomplete index, so an authoritative scan cannot silently miss licenses.
my $dst = tempdir(CLEANUP => 1);
my $ist = Cavil::Matcher::Index->new(dir => $dst);
$ist->add_segment([[1, 'permission is hereby granted']]);
my $mst = Cavil::Matcher::Manifest->new(dir => $dst);
$mst->add_segment(file => 'ghost.seg', checksum => 'deadbeef');    # names a segment not on disk
$mst->save;
ok($ist->matcher(quiet => 1), 'default matcher() returns a usable engine despite a missing segment');
eval { $ist->matcher(quiet => 1, strict => 1) };
like($@, qr/failed to load \(strict\)/, 'strict matcher() croaks on a degraded index');

done_testing();
