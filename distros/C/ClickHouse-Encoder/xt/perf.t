#!/usr/bin/env perl
# Smoke benchmark to catch encode/decode throughput regressions.
# Pinned to a coarse "rows per second" floor that's easy to clear on
# any developer laptop or CI runner; the goal isn't tight measurement,
# it's catching a 5-10x slowdown introduced by refactors. Adjust the
# floors in $MIN_* envs if your CI host is unusually slow.
#
# Skipped unless RELEASE_TESTING=1 (it's a perf smoke, not a unit test).

use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use Time::HiRes qw(gettimeofday tv_interval);
use ClickHouse::Encoder;

plan skip_all => 'set RELEASE_TESTING=1 to run perf smoke'
    unless $ENV{RELEASE_TESTING};

my $N = $ENV{PERF_ROWS} // 50_000;
# Conservative floors: real laptops do >1M rows/sec for these.
# Set generous defaults so CI on slow runners doesn't flap.
my $MIN_ENCODE_RPS = $ENV{PERF_MIN_ENCODE_RPS} // 50_000;
my $MIN_DECODE_RPS = $ENV{PERF_MIN_DECODE_RPS} // 50_000;

# A representative wide-ish row: mixed scalar kinds + one array + one
# Nullable. Covers the common encoder paths without going into rarely-
# exercised types.
my @cols = (
    ['id',     'UInt64'],
    ['name',   'String'],
    ['active', 'Bool'],
    ['score',  'Float64'],
    ['tags',   'Array(String)'],
    ['n',      'Nullable(Int32)'],
);
my $enc = ClickHouse::Encoder->new(columns => \@cols);

my @rows = map {
    [$_, "user_$_", $_ % 2, $_ * 0.1, ["tag_a","tag_b","tag_c"],
     $_ % 5 ? $_ : undef]
} 1..$N;

# Warm: encode once so any JIT-able PerlIO / SV-cache state stabilises.
$enc->encode([@rows[0..99]]);

my $t0 = [gettimeofday];
my $bytes = $enc->encode(\@rows);
my $enc_secs = tv_interval($t0);
my $enc_rps = $N / $enc_secs;

note sprintf("encode: %d rows in %.3fs -> %.0f rows/s, %d bytes "
             . "(%.2f MiB)",
             $N, $enc_secs, $enc_rps,
             length($bytes), length($bytes) / 1024 / 1024);
cmp_ok($enc_rps, '>=', $MIN_ENCODE_RPS,
       "encode throughput >= $MIN_ENCODE_RPS rows/s");

# Decode the same buffer.
my $t1 = [gettimeofday];
my $block = ClickHouse::Encoder->decode_block($bytes);
my $dec_secs = tv_interval($t1);
my $dec_rps = $N / $dec_secs;

note sprintf("decode: %d rows in %.3fs -> %.0f rows/s",
             $N, $dec_secs, $dec_rps);
cmp_ok($dec_rps, '>=', $MIN_DECODE_RPS,
       "decode throughput >= $MIN_DECODE_RPS rows/s");

# Light correctness check on the decoded output (a perf test shouldn't
# silently pass if the encoder produced garbage).
is($block->{nrows}, $N, 'decoded nrows matches input');
is($block->{columns}[0]{values}[0],          1,          'col 0 row 0');
is($block->{columns}[1]{values}[$N - 1], "user_$N",      'col 1 last row');

done_testing();
