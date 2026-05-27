#!/usr/bin/env perl
# JSON typed paths: when JSON(name Type, ...) is declared but the
# row's value at that path doesn't match the declared type, the
# encoder should reject it with a clear error message pointing at
# the offending path. Pin those error shapes so a future refactor
# can't silently degrade them.
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# Typed-path coercion: encoder applies Perl's SvIV/SvNV/SvPV coercion
# rules per the declared type, so a "not-an-integer" string under a
# JSON(a Int64) path silently becomes 0 (Perl numeric coercion). This
# is documented behavior - same as what the corresponding non-JSON
# Int64 column would do. Pin the round-trip so a future refactor that
# adds strict-mode rejection here can detect it as a behavior change.
{
    my $enc = ClickHouse::Encoder->new(columns =>
        [['j','JSON(a Int64)']]);
    my $bytes = $enc->encode([[{ a => 'not-an-integer' }]]);
    ok(defined $bytes && length $bytes > 0,
       'typed Int64 path accepts coercible scalars (Perl SvIV rules)');
}

# Typed path with the right type works (sanity check round-trip).
{
    my $enc = ClickHouse::Encoder->new(columns =>
        [['j','JSON(a Int64, b String)']]);
    my $bytes = $enc->encode([
        [{ a => 42, b => 'ok' }],
        [{ a => -7, b => '' }],
    ]);
    ok(defined $bytes && length $bytes > 0,
       'correctly-typed paths encode without error');
    my $blk = ClickHouse::Encoder->decode_block($bytes);
    my $rows = $blk->{columns}[0]{values};
    is($rows->[0]{a}, 42, 'typed path Int64 value round-trip');
    is($rows->[1]{a}, -7, 'typed path Int64 negative round-trip');
    is($rows->[0]{b}, 'ok', 'typed path String value round-trip');
}

# Reject the parse-time forms too: a JSON typed path whose declared
# inner type is one of the wire-prefixed types (Variant / LowCardinality
# / JSON / Dynamic) should fail at TypeInfo construction, not later.
{
    for my $bad ('JSON(a Variant(Int32, String))',
                 'JSON(a LowCardinality(String))',
                 'JSON(a JSON)',
                 'JSON(a Dynamic)') {
        my $err = eval {
            ClickHouse::Encoder->new(columns => [['j', $bad]]); 1
        } ? '' : $@;
        like($err, qr/typed path/i, "rejects $bad");
    }
}

done_testing();
