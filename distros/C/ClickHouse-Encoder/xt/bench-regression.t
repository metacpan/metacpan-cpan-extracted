#!/usr/bin/env perl
# Pinned upper bound on a basic encode benchmark. Catches refactors
# that accidentally regress per-row encoding cost - 500k narrow rows
# should comfortably finish under a few seconds on any modern host.
# Set CHE_BENCH_BUDGET=N seconds to override the default budget.
use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use lib 'blib/lib', 'blib/arch';

plan skip_all => 'set RELEASE_TESTING=1 to run bench-regression tests'
    unless $ENV{RELEASE_TESTING};

use ClickHouse::Encoder;

my $budget_secs = $ENV{CHE_BENCH_BUDGET} // 8;   # default upper bound
my $n_rows      = $ENV{CHE_BENCH_ROWS}   // 500_000;

my $enc = ClickHouse::Encoder->new(columns => [
    ['id',   'Int64'],
    ['name', 'String'],
    ['ts',   'DateTime'],
    ['amt',  'Float64'],
    ['ok',   'Bool'],
]);

my @rows = map [
    $_,
    "row$_",
    1700000000 + $_,
    $_ * 0.5,
    $_ % 2,
], 1 .. $n_rows;

my $t0 = time();
my $bytes = $enc->encode(\@rows);
my $secs = time() - $t0;

ok(length($bytes) > 0, "encoded $n_rows rows");
cmp_ok($secs, '<', $budget_secs,
       "encode of $n_rows narrow rows under ${budget_secs}s "
     . "(took ${secs}s; set CHE_BENCH_BUDGET to override)");

# Decode budget: a touch more generous since decode allocates per-row
# SVs whereas encode just writes bytes.
$t0 = time();
my $blk = ClickHouse::Encoder->decode_block($bytes);
my $decode_secs = time() - $t0;
is($blk->{nrows}, $n_rows, 'decoded all rows');
cmp_ok($decode_secs, '<', $budget_secs * 1.5,
       "decode of $n_rows rows under "
     . sprintf('%.1f', $budget_secs * 1.5) . "s (took ${decode_secs}s)");

done_testing();
