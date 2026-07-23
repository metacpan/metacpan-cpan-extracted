# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Segment mechanics at the engine level: multi-segment union, tombstones, and the versioned/validated
# on-disk format. A corrupt or hostile segment file must be rejected, never mis-read or crashed on.
use strict;
use warnings;
use Test::More;
use Test::Deep;
use Cavil::Matcher;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);

sub slurp          { open my $fh, '<', $_[0] or die $!; local $/; my $c = <$fh>; close $fh; $c }
sub sorted_matches { [sort { $a->[0] <=> $b->[0] || $a->[1] <=> $b->[1] } @{$_[0]}] }

# Load a handful of real patterns.
my %pat;
for my $fn (glob('t/fixtures/licenses/04license.*.pattern')) {
  $fn =~ m/\.(\d+)\.pattern$/ or next;
  $pat{$1} = slurp($fn);
}
my @ids = sort { $a <=> $b } keys %pat;

# --- Reference: one matcher with every pattern ---------------------------------------------------
my $all = Cavil::Matcher::init_matcher();
$all->add_pattern($_, Cavil::Matcher::parse_tokens($pat{$_})) for @ids;

# --- Split the same patterns across two compiled segments ----------------------------------------
my $half = int(@ids / 2);
my $ma   = Cavil::Matcher::init_matcher();
$ma->add_pattern($_, Cavil::Matcher::parse_tokens($pat{$_})) for @ids[0 .. $half - 1];
my $seg_a = "$dir/a.seg";
ok($ma->dump($seg_a), 'compiled segment A');

my $mb = Cavil::Matcher::init_matcher();
$mb->add_pattern($_, Cavil::Matcher::parse_tokens($pat{$_})) for @ids[$half .. $#ids];
my $seg_b = "$dir/b.seg";
ok($mb->dump($seg_b), 'compiled segment B');

my $multi = Cavil::Matcher::init_matcher();
ok($multi->attach($seg_a), 'attach segment A');
ok($multi->attach($seg_b), 'attach segment B');

# Union of two segments equals the single all-patterns matcher (compared as sets).
for my $fn (sort glob('t/fixtures/licenses/04license.*.txt')) {
  cmp_deeply(
    sorted_matches($multi->find_matches($fn)),
    sorted_matches($all->find_matches($fn)),
    "two-segment union equals single matcher for $fn"
  );
}

# --- Tombstones: drop one pattern id; its matches vanish, others remain --------------------------
# Pick a pattern id that actually matches somewhere.
my ($victim, $victim_file);
for my $fn (sort glob('t/fixtures/licenses/04license.*.txt')) {
  for my $m (@{$all->find_matches($fn)}) { ($victim, $victim_file) = ($m->[0], $fn); last; }
  last if $victim;
}
ok($victim, "found a matching pattern id ($victim) to tombstone");

my $tomb = Cavil::Matcher::init_matcher();
$tomb->attach($seg_a);
$tomb->attach($seg_b);
$tomb->set_tombstones([$victim]);
my @still = grep { $_->[0] == $victim } @{$tomb->find_matches($victim_file)};
is(scalar @still, 0, 'tombstoned pattern produces no matches');

# The real invariant: tombstoning a pattern yields exactly the same result as a corpus that never
# contained it - because tombstones are filtered *before* overlap resolution, removing a match can
# correctly reveal smaller matches it used to suppress. Compare against a matcher built without the
# victim across every fixture (as sets).
my $without = Cavil::Matcher::init_matcher();
$without->add_pattern($_, Cavil::Matcher::parse_tokens($pat{$_})) for grep { $_ != $victim } @ids;
for my $fn (sort glob('t/fixtures/licenses/04license.*.txt')) {
  cmp_deeply(
    sorted_matches($tomb->find_matches($fn)),
    sorted_matches($without->find_matches($fn)),
    "tombstoning $victim equals a corpus without it for $fn"
  );
}

# --- Format safety: corrupt segments are rejected, never mis-read or crashed on -------------------
my $good = slurp($seg_a);

sub attach_bytes {
  my $bytes = shift;
  my $f     = "$dir/corrupt.$$." . int(rand(1e9));
  open my $fh, '>', $f or die $!;
  binmode $fh;
  print {$fh} $bytes;
  close $fh;
  my $m  = Cavil::Matcher::init_matcher();
  my $ok = $m->attach($f);
  unlink $f;
  return $ok;
}

is(attach_bytes($good), 1, 'a valid segment attaches');

my $bad_magic = $good;
substr($bad_magic, 0, 1) = 'X';
is(attach_bytes($bad_magic), 0, 'wrong magic rejected');

my $bad_version = $good;
substr($bad_version, 8, 4) = pack('L', 999);
is(attach_bytes($bad_version), 0, 'wrong format version rejected');

my $bad_crc = $good;
substr($bad_crc, length($bad_crc) - 1, 1) = chr((ord(substr($bad_crc, length($bad_crc) - 1, 1)) ^ 0xFF));
is(attach_bytes($bad_crc), 0, 'flipped payload byte fails CRC');

is(attach_bytes(substr($good, 0, 20)),                                0, 'truncated file rejected');
is(attach_bytes(''),                                                  0, 'empty file rejected');
is(attach_bytes('not a segment at all, just random text bytes here'), 0, 'garbage file rejected');
is(attach_bytes($good . 'trailing junk'),                             0, 'trailing bytes after payload rejected');

# A matcher whose only segment failed to attach simply finds nothing (no crash).
my $none = Cavil::Matcher::init_matcher();
$none->attach("$dir/does-not-exist.seg");
cmp_deeply($none->find_matches('t/fixtures/licenses/04license.1.txt'), [], 'missing segment => no matches, no crash');

# --- NUL contract (pinned) -----------------------------------------------------------------------
# A NUL byte terminates tokenization of the line it is on (a deliberate parity with the previous
# engine), so text after a NUL *within the same line* is not matched - but text on a later line is.
# This characterizes the contract so it cannot change silently (it would alter matches and stored
# hashes on every NUL-bearing file).
{
  my $nulm = Cavil::Matcher::init_matcher();
  $nulm->add_pattern(1, Cavil::Matcher::parse_tokens('permission is hereby granted'));

  my $after_nul = "$dir/after_nul";
  open my $a, '>:raw', $after_nul or die $!;
  print {$a} "prefix\0permission is hereby granted\n";
  close $a;
  cmp_deeply($nulm->find_matches($after_nul), [], 'text after a NUL on the same line is not matched');

  # A NUL *before* the newline must not hide the newline: strlen()-based detection would stop at the NUL
  # and mis-number every following line. The match below is physically on line 2 and must be reported
  # there (not line 1), and read_lines must agree.
  my $next_line = "$dir/next_line";
  open my $b, '>:raw', $next_line or die $!;
  print {$b} "prefix\0junk\npermission is hereby granted\n";
  close $b;
  cmp_deeply(
    $nulm->find_matches($next_line),
    [[1, 2, 2]],
    'a NUL before the newline does not corrupt the next line number (match is on line 2)'
  );
  my $nul_rl = Cavil::Matcher::read_lines($next_line, {2 => 1});
  is($nul_rl->[0][0], 2, 'read_lines agrees the post-NUL match is on line 2');
}

# --- Chunk-as-line contract for very long physical lines (pinned) --------------------------------
# Line numbers count physical newlines, not read chunks: a very long single physical line is read in
# several internal chunks but the match must still be reported on line 1. (A regression here would put
# reviewers/UI on the wrong line.)
{
  my $lm = Cavil::Matcher::init_matcher();
  $lm->add_pattern(1, Cavil::Matcher::parse_tokens('permission is hereby granted'));

  my $longline = "$dir/longline";
  open my $fh, '>:raw', $longline or die $!;
  print {$fh} ('z ' x 4200) . "permission is hereby granted\n";    # >8000 bytes before the pattern
  close $fh;
  cmp_deeply($lm->find_matches($longline), [[1, 1, 1]], 'match in a very long single line is reported on line 1');

  # read_lines must return the WHOLE physical line (not just the first 8KB chunk), so the extracted
  # snippet text actually contains the matched region past the first chunk.
  my $long_rl = Cavil::Matcher::read_lines($longline, {1 => 1});
  is($long_rl->[0][0], 1, 'read_lines returns line 1 of the long line');
  cmp_ok(length($long_rl->[0][2]), '>', 8000, 'read_lines returns the full long line, not one chunk');
  like($long_rl->[0][2], qr/permission is hereby granted/, 'the matched text is present in the returned line');

  # And a match on a genuinely later line still gets the right number, even after a long first line.
  my $twolines = "$dir/twolines";
  open my $fh2, '>:raw', $twolines or die $!;
  print {$fh2} ('z ' x 4200) . "filler\npermission is hereby granted\n";
  close $fh2;
  cmp_deeply($lm->find_matches($twolines), [[1, 2, 2]], 'the following line is correctly numbered 2, not 3+');

  # read_lines uses the same numbering, so it agrees with find_matches.
  my $rl = Cavil::Matcher::read_lines($twolines, {2 => 1});
  is($rl->[0][0], 2, 'read_lines agrees: the pattern is on line 2');
}

# --- $SKIP<n> semantics (pinned): one to N words, never zero ---------------------------------------
# $SKIP matches at least one and at most N words - it does NOT match a zero-word gap. This is the
# documented contract and matches the previous engine; a change would alter matches across the corpus.
{
  my $sk = Cavil::Matcher::init_matcher();
  $sk->add_pattern(1, Cavil::Matcher::parse_tokens('hello $SKIP2 world'));
  my $gap = sub {
    my $probe = "$dir/skipprobe";
    open my $fh, '>:raw', $probe or die $!;
    print {$fh} "$_[0]\n";
    close $fh;
    my $n = scalar @{$sk->find_matches($probe)};
    unlink $probe;
    return $n;
  };
  is($gap->('hello world'),          0, '$SKIP2 does not match a zero-word gap');
  is($gap->('hello xx world'),       1, '$SKIP2 matches a one-word gap');
  is($gap->('hello xx yy world'),    1, '$SKIP2 matches a two-word gap');
  is($gap->('hello xx yy zz world'), 0, '$SKIP2 does not match a gap wider than N');
}

# --- Single-token pattern at end of file (regression) --------------------------------------------
# A one-token pattern whose terminal node sits exactly at EOF must still match; the previous engine
# missed this because its guard returned before checking the terminal node.
{
  my $stm = Cavil::Matcher::init_matcher();
  $stm->add_pattern(1, Cavil::Matcher::parse_tokens('copyleft'));

  my $eof = "$dir/single_eof";
  open my $fh, '>:raw', $eof or die $!;
  print {$fh} 'some text then copyleft';    # last token, no trailing newline
  close $fh;
  cmp_deeply($stm->find_matches($eof), [[1, 1, 1]], 'single-token pattern as the last token of the file matches');

  my $only = "$dir/single_only";
  open my $f2, '>:raw', $only or die $!;
  print {$f2} "copyleft\n";
  close $f2;
  cmp_deeply($stm->find_matches($only), [[1, 1, 1]], 'single-token pattern alone in the file matches');
}

# --- Out-of-range tombstone ids are ignored, not wrapped -----------------------------------------
# (uint32_t) truncation would turn 2^32+1 into 1; set_tombstones must ignore such values instead of
# suppressing an unrelated pattern.
{
  my $tm = Cavil::Matcher::init_matcher();
  $tm->add_pattern(1, Cavil::Matcher::parse_tokens('permission is hereby granted'));
  my $probe = "$dir/tombprobe";
  open my $fh, '>:raw', $probe or die $!;
  print {$fh} "permission is hereby granted\n";
  close $fh;
  $tm->set_tombstones([4294967297]);    # 2^32 + 1: must NOT wrap to 1
  is(scalar @{$tm->find_matches($probe)}, 1, 'an out-of-range tombstone id does not suppress pattern 1');
}

# --- Pattern id range is enforced at the boundary (no silent 32-bit truncation) ------------------
# An id outside 1..2^32-1 would truncate to a different value (2^32+1 -> 1) and produce wrong match
# identities; add_pattern must reject it loudly. 0 is the reserved "no pattern" sentinel.
{
  my $e = Cavil::Matcher::init_matcher();
  eval { $e->add_pattern(4294967297, Cavil::Matcher::parse_tokens('permission is hereby granted')) };
  like($@, qr/out of range/, 'add_pattern croaks on an id above 2^32-1 instead of truncating');
  eval { $e->add_pattern(0, Cavil::Matcher::parse_tokens('permission is hereby granted')) };
  like($@, qr/out of range/, 'add_pattern croaks on id 0 (the no-pattern sentinel)');

  # An in-range id still works.
  $e->add_pattern(7, Cavil::Matcher::parse_tokens('permission is hereby granted'));
  my $ok = "$dir/idok";
  open my $fh, '>:raw', $ok or die $!;
  print {$fh} "permission is hereby granted\n";
  close $fh;
  cmp_deeply($e->find_matches($ok), [[7, 1, 1]], 'an in-range id matches normally');
}

# --- Malformed token arrays are rejected, so one bad pattern cannot invalidate the whole segment ---
# add_pattern's tokens come from parse_tokens (real hashes, or skip widths 1..99). Token 0 would build a
# zero-width skip node the reader rejects - invalidating the segment and dropping every other pattern in
# it (the reported failure). A leading/trailing skip makes an unanchored pattern. Both must croak.
{
  my $big = 12345678901234;                   # a stand-in "real" token hash (well above MAX_SKIP)
  my $e   = Cavil::Matcher::init_matcher();
  $e->add_pattern(1, Cavil::Matcher::parse_tokens('permission is hereby granted'));
  eval { $e->add_pattern(2, [0]) };
  like($@, qr/invalid token 0/, 'add_pattern croaks on token 0 instead of corrupting the segment');
  eval { $e->add_pattern(3, [5, $big]) };
  like($@, qr/begin or end with a skip/, 'add_pattern croaks on a leading skip');
  eval { $e->add_pattern(4, [$big, 5]) };
  like($@, qr/begin or end with a skip/, 'add_pattern croaks on a trailing skip');

  # The valid pattern added earlier is untouched by the rejected calls.
  my $f = "$dir/tokprobe";
  open my $fh, '>:raw', $f or die $!;
  print {$fh} "permission is hereby granted\n";
  close $fh;
  cmp_deeply($e->find_matches($f), [[1, 1, 1]], 'a rejected malformed pattern does not disturb valid ones');
}

# --- load() preserves the current matcher when the new segment fails to load ----------------------
# load() replaces all state with one segment file, but only on success: a missing/corrupt file must
# leave the existing matcher usable (swap-on-success, like Bag::load), not silently empty it.
{
  my $good_seg = "$dir/loadgood.seg";
  my $builder  = Cavil::Matcher::init_matcher();
  $builder->add_pattern(1, Cavil::Matcher::parse_tokens('permission is hereby granted'));
  ok($builder->dump($good_seg), 'built a good segment to load');
  is(scalar(() = glob "$dir/*.tmp.*"), 0, 'matcher dump (temp+rename) leaves no temp file behind');

  my $probe = "$dir/loadprobe";
  open my $pf, '>:raw', $probe or die $!;
  print {$pf} "permission is hereby granted\n";
  close $pf;

  my $e = Cavil::Matcher::init_matcher();
  ok($e->load($good_seg), 'load a good segment');
  cmp_deeply($e->find_matches($probe), [[1, 1, 1]], 'the loaded segment matches');

  # A corrupt segment (flipped payload byte -> CRC failure) fails to load...
  my $bad_bytes = slurp($good_seg);
  substr($bad_bytes, length($bad_bytes) - 1, 1) = chr(ord(substr($bad_bytes, length($bad_bytes) - 1, 1)) ^ 0xFF);
  my $bad_seg = "$dir/loadbad.seg";
  open my $bf, '>:raw', $bad_seg or die $!;
  print {$bf} $bad_bytes;
  close $bf;
  is($e->load($bad_seg), 0, 'loading a corrupt segment fails');

  # ...and the previously-loaded segment is still usable, not silently emptied.
  cmp_deeply($e->find_matches($probe), [[1, 1, 1]], 'the working matcher survives a failed load');

  # A missing file likewise fails without destroying state.
  is($e->load("$dir/does-not-exist.seg"), 0, 'loading a missing file fails');
  cmp_deeply($e->find_matches($probe), [[1, 1, 1]], 'the working matcher survives a missing-file load');
}

# --- A wide $SKIP spanning the streaming flush boundary still matches -----------------------------
# The streaming window must be sized on the skip-expanded match SPAN, not the pattern token count. With
# "alpha $SKIP99 omega" (3 tokens but up to 101 file tokens) and the two anchors ~100 tokens apart in a
# 500-token file, the previous logic evicted (and finalized) alpha before omega was read, dropping the
# match. It must be found, reported across the physical lines of the two anchors.
{
  my $sk = Cavil::Matcher::init_matcher();
  $sk->add_pattern(1, Cavil::Matcher::parse_tokens('alpha $SKIP99 omega'));

  my @lines = (('filler') x 249, 'alpha', ('filler') x 99, 'omega', ('filler') x 150);    # alpha@250, omega@350
  my $wide  = "$dir/wideskip";
  open my $fh, '>:raw', $wide or die $!;
  print {$fh} join("\n", @lines), "\n";
  close $fh;
  cmp_deeply(
    $sk->find_matches($wide),
    [[1, 250, 350]],
    'a $SKIP99 match whose anchors straddle the old flush boundary is found'
  );
}

# --- A skip match survives an ACTUAL streaming eviction (retention = span) -------------------------
# With a smaller skip the window threshold (span*100) is low enough that a big file really does trigger
# eviction. The match must still be found: retaining the last `span` tokens guarantees the far anchor is
# present when the near one is finalized during eviction.
{
  my $sk = Cavil::Matcher::init_matcher();
  $sk->add_pattern(1, Cavil::Matcher::parse_tokens('alpha $SKIP9 omega'));    # span 11 => evicts past ~1100 tokens

  my @lines = (('filler') x 1089, 'alpha', ('filler') x 9, 'omega', ('filler') x 200);    # alpha@1090, omega@1100
  my $big   = "$dir/evictskip";
  open my $fh, '>:raw', $big or die $!;
  print {$fh} join("\n", @lines), "\n";
  close $fh;
  cmp_deeply(
    $sk->find_matches($big),
    [[1, 1090, 1100]],
    'a skip match is found even when its near anchor is finalized during an eviction'
  );
}

done_testing();
