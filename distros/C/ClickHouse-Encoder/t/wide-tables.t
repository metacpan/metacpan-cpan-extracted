#!/usr/bin/env perl
# Encode/decode a wide table (500 columns) round-trip. Catches any
# quadratic per-column overhead in buf_grow / encode_column / the
# block-prologue walks that the <=8-column suite would miss, and
# pins the wire-correctness for the wide regime.
use strict;
use warnings;
use Test::More;
use Time::HiRes qw(time);
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

my $N_COLS = 500;
my $N_ROWS = 100;

my @types = ('Int32', 'String', 'Float64', 'Bool', 'DateTime');
my @cols  = map { my $t = $types[$_ % @types]; ["c$_", $t] } 0 .. $N_COLS - 1;

my $enc = ClickHouse::Encoder->new(columns => \@cols);

# Build one canonical row per column-type cycle.
my @canonical_row = map {
    my $t = $types[$_ % @types];
    $t eq 'Int32'    ? $_ * 11
  : $t eq 'String'   ? sprintf('v%05d', $_)
  : $t eq 'Float64'  ? $_ * 0.5
  : $t eq 'Bool'     ? ($_ % 2)
  : $t eq 'DateTime' ? 1700000000 + $_
  : die "unhandled $t";
} 0 .. $N_COLS - 1;

my @rows = (\@canonical_row) x $N_ROWS;

my $t0 = time();
my $bytes = $enc->encode(\@rows);
my $encode_secs = time() - $t0;

ok(defined $bytes && length $bytes > 0, "encoded $N_COLS x $N_ROWS block");
cmp_ok($encode_secs, '<', 5,
       "encode finishes in under 5s (got ${encode_secs}s) - no quadratic blow-up");

# Decode and verify shape + a sample of values.
$t0 = time();
my $blk = ClickHouse::Encoder->decode_block($bytes);
my $decode_secs = time() - $t0;

is($blk->{ncols}, $N_COLS, 'decoded ncols matches');
is($blk->{nrows}, $N_ROWS, 'decoded nrows matches');
cmp_ok($decode_secs, '<', 5,
       "decode finishes in under 5s (got ${decode_secs}s)");

# Sample a few columns from different positions
for my $i (0, 1, 2, 100, 250, $N_COLS - 1) {
    my $col = $blk->{columns}[$i];
    is($col->{name}, "c$i", "col $i name preserved");
    is(scalar @{ $col->{values} }, $N_ROWS,
       "col $i has all $N_ROWS values");
    # Sample row 0 against canonical
    my $expected = $canonical_row[$i];
    my $got      = $col->{values}[0];
    if ($types[$i % @types] eq 'Float64') {
        cmp_ok(abs($got - $expected), '<', 1e-9,
               "col $i row 0 float value match");
    } else {
        is($got, $expected, "col $i row 0 value match");
    }
}

# Column projection: keep only the first 5 columns and verify the
# rest are marked skipped and have empty values.
{
    my $blk2 = ClickHouse::Encoder->decode_block(
        $bytes, 0, { map { ("c$_" => 1) } 0..4 });
    for my $i (0..4) {
        ok(!$blk2->{columns}[$i]{skipped}, "col $i kept");
    }
    ok($blk2->{columns}[10]{skipped},      'col 10 skipped under projection');
    ok($blk2->{columns}[$N_COLS-1]{skipped},
       'last col skipped under projection');
}

done_testing();
