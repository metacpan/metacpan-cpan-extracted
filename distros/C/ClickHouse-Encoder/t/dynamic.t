#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use JSON::PP ();

# Round-trip helper for a Dynamic column.
sub rt {
    my ($rows) = @_;
    my $enc = ClickHouse::Encoder->new(columns => [['d', 'Dynamic']]);
    my $bytes = $enc->encode([map [$_], @$rows]);
    my $block = ClickHouse::Encoder->decode_block($bytes);
    return $block->{columns}[0]{values};
}

# Mixed scalar types
{
    my $out = rt([1, "hello", 3.14, JSON::PP::true(), undef]);
    is($out->[0], 1,       'Int64 value');
    is($out->[1], "hello", 'String value');
    cmp_ok($out->[2], '>', 3.13, 'Float64 value');
    is($out->[3], 1,       'Bool true');
    is($out->[4], undef,   'null');
}

# Array values in Dynamic
{
    my $out = rt([[1, 2, 3], ["a", "b"], 42]);
    is_deeply($out->[0], [1, 2, 3], 'Array(Int64) in Dynamic');
    is_deeply($out->[1], ["a", "b"], 'Array(String) in Dynamic');
    is($out->[2], 42, 'scalar alongside arrays');
}

# All null Dynamic column
{
    my $out = rt([undef, undef, undef]);
    is_deeply($out, [undef, undef, undef], 'all-null Dynamic');
}

# Reject hashref in Dynamic (use JSON for objects)
{
    my $enc = ClickHouse::Encoder->new(columns => [['d', 'Dynamic']]);
    my $err = eval { $enc->encode([[{a => 1}]]); 1 } ? "" : $@;
    like($err, qr/hash refs are not supported/, 'hashref rejected');
}

# Multiple Dynamic columns side-by-side
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['a', 'Dynamic'], ['b', 'Dynamic']]);
    my $bytes = $enc->encode([
        [1, "x"],
        [3.14, undef],
        [["a","b"], 42],
    ]);
    my $block = ClickHouse::Encoder->decode_block($bytes);
    is_deeply($block->{columns}[0]{values}, [1, 3.14, ["a","b"]],
              'first Dynamic column');
    is_deeply($block->{columns}[1]{values}, ["x", undef, 42],
              'second Dynamic column');
}

done_testing();
