use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# estimate_size is a sizing heuristic for batch-split decisions, not a
# byte-exact predictor (the block header is approximated by a small
# constant). The contracts worth pinning: (1) for all-fixed-width
# schemas it tracks the real size to within a handful of bytes,
# (2) it scales linearly with row count, (3) for variable-width columns
# the actual encoded size stays within a sane band of the estimate when
# the avg_string_size hint is realistic.

# --- tight for fixed-width columns ------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [
        ['a', 'UInt64'],   # 8
        ['b', 'Int32'],    # 4
        ['c', 'Float64'],  # 8
        ['d', 'DateTime'], # 4
    ]);
    my @rows = map { [$_, -$_, $_ / 2, 1700000000 + $_] } 1 .. 50;
    my $actual   = length $enc->encode(\@rows);
    my $estimate = $enc->estimate_size(\@rows);
    # Per-row bytes are exact for fixed-width types; only the small
    # block-header approximation introduces a few bytes of slack.
    cmp_ok(abs($estimate - $actual), '<=', 8,
           'fixed-width schema: estimate within a few bytes of actual')
        or diag "actual=$actual estimate=$estimate";
}

# --- linear scaling ----------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Int32']]);
    my $e0   = $enc->estimate_size(0);
    my $e100 = $enc->estimate_size(100);
    my $e200 = $enc->estimate_size(200);
    # estimate(n) = const + n * per_row, so equal-width row spans cost
    # the same: rows 1..100 and rows 101..200 are both 100 * per_row.
    is($e200 - $e100, $e100 - $e0,
       'equal row spans cost the same (linear in row count)')
        or diag "e0=$e0 e100=$e100 e200=$e200";
    cmp_ok(($e100 - $e0) / 100, '>', 0, 'per-row cost is positive');
}

# --- accepts both a rowcount and a rows arrayref ----------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'UInt8']]);
    my @rows = map { [$_ % 256] } 1 .. 30;
    is($enc->estimate_size(\@rows), $enc->estimate_size(30),
       'rows arrayref and explicit count give the same estimate');
}

# --- variable-width columns: estimate is a sane upper-ballpark --------
{
    my $enc = ClickHouse::Encoder->new(columns => [
        ['id',   'UInt32'],
        ['name', 'String'],
    ]);
    # Names sized to match the default avg_string_size hint (16).
    my @rows = map { [$_, 'x' x 16] } 1 .. 100;
    my $actual   = length $enc->encode(\@rows);
    my $estimate = $enc->estimate_size(\@rows);
    # With a matching hint the estimate should bracket the real size
    # within a factor of two either way - good enough for batch sizing.
    cmp_ok($estimate, '>', $actual / 2, 'estimate not wildly low');
    cmp_ok($estimate, '<', $actual * 2, 'estimate not wildly high');
}

# --- avg_string_size hint moves the estimate -------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['s', 'String']]);
    my $small = $enc->estimate_size(100, avg_string_size => 8);
    my $big   = $enc->estimate_size(100, avg_string_size => 256);
    cmp_ok($big, '>', $small,
           'larger avg_string_size hint yields a larger estimate');
}

done_testing();
