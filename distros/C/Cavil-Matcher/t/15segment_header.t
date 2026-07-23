# SPDX-FileCopyrightText: SUSE LLC
# SPDX-License-Identifier: GPL-2.0-or-later
#
# Semantic header-invariant validation. The payload CRC proves the bytes are the ones the writer
# produced, but NOT that a malicious or buggy writer produced *sane* values - and the CRC deliberately
# does not even cover the header. These fields steer the scan (notably longest_pattern, which sizes the
# sliding window in find_matches), so a crafted or corrupt local cache file with an intact CRC but an
# impossible header must be rejected by attach(), never trusted. This test tampers header fields (no CRC
# recompute needed) and one payload field (with a recomputed CRC) and asserts each is refused.
use strict;
use warnings;
use Test::More;
use Cavil::Matcher;
use File::Temp qw(tempdir);

my $dir = tempdir(CLEANUP => 1);

sub slurp { open my $fh, '<:raw', $_[0] or die $!; local $/; my $c = <$fh>; close $fh; $c }
sub spew { my ($p, $b) = @_; open my $o, '>:raw', $p or die $!; print {$o} $b; close $o; return $p }

# Attach a segment buffer via a throwaway matcher; return true iff it was accepted.
my $probe = 0;

sub accepts {
  my ($bytes) = @_;
  my $p       = spew("$dir/probe-" . $probe++, $bytes);
  my $e       = Cavil::Matcher::init_matcher;
  return $e->attach($p) ? 1 : 0;
}

# Pure-Perl CRC32 (IEEE, reflected, poly 0xEDB88320) - matches cavil_crc32 in src/segment.cc.
my @CRC_TABLE = map {
  my $c = $_;
  $c = ($c & 1) ? (0xEDB88320 ^ ($c >> 1)) : ($c >> 1) for 1 .. 8;
  $c & 0xFFFFFFFF;
} 0 .. 255;

sub crc32 {
  my $crc = 0xFFFFFFFF;
  $crc = $CRC_TABLE[($crc ^ $_) & 0xFF] ^ ($crc >> 8) for unpack 'C*', $_[0];
  return ($crc ^ 0xFFFFFFFF) & 0xFFFFFFFF;
}

# Build one real, valid segment on disk (a pattern with a skip so the payload has a FlatSkip to poke).
my $seg = "$dir/base.seg";
{
  my $e = Cavil::Matcher::init_matcher;
  $e->add_pattern(1, Cavil::Matcher::parse_tokens('permission is hereby granted $SKIP2 all copies'));
  ok($e->dump($seg), 'built a valid segment on disk');
}
my $good = slurp($seg);

# Sanity: untouched, it attaches; and our CRC32 matches the stored one (so the recompute cases below are
# trustworthy). Header layout (packed): flags@12, longest_pattern@24 (i64), node_count@32, child_count@36,
# skip_count@40, pattern_count@44, payload_crc32@48, longest_span@52; payload begins at 56.
is(accepts($good),           1,                                 'the untampered segment attaches');
is(crc32(substr($good, 56)), unpack('V', substr($good, 48, 4)), 'pure-Perl CRC32 matches the stored payload CRC');

my $node_count  = unpack('V', substr($good, 32, 4));
my $child_count = unpack('V', substr($good, 36, 4));
my $skip_count  = unpack('V', substr($good, 40, 4));
cmp_ok($skip_count, '>=', 1, 'the fixture segment has at least one skip to tamper');

# --- Header fields: CRC unaffected (it does not cover the header), only the semantic checks catch these.
{
  my $b = $good;
  substr($b, 12, 4) = pack('V', 1);
  is(accepts($b), 0, 'nonzero flags rejected');
}

# longest_span sizes the streaming window; it must be in [longest_pattern, longest_pattern * MAX_SKIP].
my $longest_pattern = unpack('q<', substr($good, 24, 8));
{
  my $b = $good;
  substr($b, 52, 4) = pack('V', $longest_pattern - 1);    # below longest_pattern: impossible
  is(accepts($b), 0, 'a longest_span smaller than longest_pattern is rejected');
}
{
  my $b = $good;
  substr($b, 52, 4) = pack('V', 1_000_000);               # far above longest_pattern * MAX_SKIP
  is(accepts($b), 0, 'an out-of-range longest_span (would bloat the scan window) is rejected');
}
{
  my $b = $good;
  substr($b, 24, 8) = pack('q<', 1_000_000_000);          # longest_pattern >> node_count
  is(accepts($b), 0, 'an out-of-range longest_pattern (would blow up the scan window) is rejected');
}
{
  my $b = $good;
  substr($b, 24, 8) = pack('q<', -1);
  is(accepts($b), 0, 'a negative longest_pattern is rejected');
}

# --- Payload field: skip_value lives in a FlatSkip, so tampering it needs a recomputed CRC to isolate
# the semantic check from the CRC check. FlatSkip is {u32 child_node; u8 skip_value; u8 pad[3]} = 8 bytes;
# the skip array starts after the header, the FlatNode array and the FlatChild array.
my $skip_off     = 56 + $node_count * 20 + $child_count * 16;    # first FlatSkip
my $skip_val_off = $skip_off + 4;                                # its skip_value byte

sub with_skip_value {
  my ($v) = @_;
  my $b = $good;
  substr($b, $skip_val_off, 1) = pack('C', $v);
  substr($b, 48, 4) = pack('V', crc32(substr($b, 56)));               # re-seal the payload
  return $b;
}
is(accepts(with_skip_value(3)),
  1, 'a re-sealed segment with a valid skip width still attaches (CRC recompute is sound)');
is(accepts(with_skip_value(0)),   0, 'a zero skip width is rejected');
is(accepts(with_skip_value(200)), 0, 'a skip width above MAX_SKIP is rejected');

# pattern_count is NOT a structural bound: many patterns that normalize to the same token sequence
# collapse onto one terminal node (newer id wins) yet each counts, so pattern_count legitimately exceeds
# node_count. Such a segment must still attach - treating pattern_count as a bound would reject it.
{
  my $e = Cavil::Matcher::init_matcher;
  $e->add_pattern($_, Cavil::Matcher::parse_tokens('copyleft')) for 1 .. 50;
  my $dup = "$dir/dup.seg";
  ok($e->dump($dup), 'built a segment with 50 duplicate-normalized patterns');
  my $raw = slurp($dup);
  cmp_ok(
    unpack('V', substr($raw, 44, 4)),
    '>',
    unpack('V', substr($raw, 32, 4)),
    'the duplicate segment really does have pattern_count > node_count'
  );
  is(accepts($raw), 1, 'a segment whose pattern_count exceeds node_count still attaches');
}

done_testing();
