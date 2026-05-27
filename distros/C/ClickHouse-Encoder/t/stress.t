use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;
use Digest::SHA qw(sha1_hex);

# Sanity-check that the encoder has no shared mutable state between calls or
# between distinct encoder instances. These are insurance tests against
# accidental statics or globals if the XS gets refactored.

# 1) The same encoder, same input, must produce identical bytes every time.
{
    my $enc = ClickHouse::Encoder->new(columns => [
        ['id',   'UInt32'],
        ['name', 'String'],
        ['tags', 'Array(String)'],
    ]);
    my $rows = [[1, 'alice', ['x','y']], [2, 'bob', []]];
    my $first = sha1_hex($enc->encode($rows));
    my $stable = 1;
    for (1 .. 50) {
        $stable = 0 if sha1_hex($enc->encode($rows)) ne $first;
    }
    ok($stable, 'same encoder + same input -> identical bytes across 50 calls');
}

# 2) Many encoders for the SAME schema produce identical bytes for the same
# input. (No per-instance state should leak into the wire format.)
{
    my $rows = [[1, 'x'], [2, 'y'], [3, 'z']];
    my $first;
    my $stable = 1;
    for (1 .. 50) {
        my $enc = ClickHouse::Encoder->new(columns => [
            ['id', 'UInt32'], ['s', 'String'],
        ]);
        my $bin = $enc->encode($rows);
        $first //= $bin;
        $stable = 0 if $bin ne $first;
    }
    ok($stable, 'fresh encoders for same schema -> identical bytes');
}

# 3) Alternating between two encoders with different schemas: each must
# produce its own correct output (no cross-contamination).
{
    my $a = ClickHouse::Encoder->new(columns => [['v', 'UInt8']]);
    my $b = ClickHouse::Encoder->new(columns => [['v', 'String']]);
    my $bin_a = $a->encode([[42]]);
    my $bin_b = $b->encode([['hi']]);
    for (1 .. 50) {
        is($a->encode([[42]]),   $bin_a, "encoder A stable iter $_") if $_ <= 1;
        is($b->encode([['hi']]), $bin_b, "encoder B stable iter $_") if $_ <= 1;
        die "A drift" if $a->encode([[42]])   ne $bin_a;
        die "B drift" if $b->encode([['hi']]) ne $bin_b;
    }
    ok(1, 'alternating two distinct encoders -> no cross-contamination');
}

# 4) Build and destroy many encoders; should not grow memory or leave
# dangling state. (This is best run under valgrind too, see xt/leaks.t.)
{
    for (1 .. 1000) {
        my $enc = ClickHouse::Encoder->new(columns => [
            ['a', 'Array(Tuple(Int32, Nullable(String)))'],
            ['b', 'Decimal64(2)'],
            ['c', "Enum8('x' = 1, 'y' = 2)"],
        ]);
        my $bin = $enc->encode([
            [[[1, 'one'], [2, undef]], '12.34', 'x'],
            [[],                       '0',     'y'],
        ]);
    }
    ok(1, '1000 build+encode+destroy cycles complete');
}

# 5) One large batch: 50_000 rows, varied content. Verifies that the
# allocator handles sustained growth and that varint length transitions
# (offset table for arrays) don't break.
{
    my $enc = ClickHouse::Encoder->new(columns => [
        ['id',   'UInt32'],
        ['tags', 'Array(String)'],
    ]);
    my @rows;
    for my $i (1 .. 50_000) {
        push @rows, [$i, ["t$i", "ten$i", "twenty$i"]];
    }
    my $bin = $enc->encode(\@rows);
    cmp_ok(length($bin), '>', 50_000 * 10, '50k rows produce >500KB');
}

done_testing();
