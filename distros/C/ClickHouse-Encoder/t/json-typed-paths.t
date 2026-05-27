#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;
use JSON::PP ();

# JSON(name Type, ...) pins specific paths to concrete inner types.
# Those paths skip the Dynamic+Variant wrapping and emit as regular
# columns; remaining keys still go through the dynamic-paths
# discovery + Variant pipeline.

sub rt {
    my ($type_spec, $rows) = @_;
    my $enc = ClickHouse::Encoder->new(columns => [['j', $type_spec]]);
    my $bytes = $enc->encode([map [$_], @$rows]);
    my $block = ClickHouse::Encoder->decode_block($bytes);
    return $block->{columns}[0]{values};
}

# 1. Single typed path, exact match
{
    my $out = rt('JSON(age UInt32)', [
        {age => 30},
        {age => 25},
    ]);
    is_deeply($out, [{age => 30}, {age => 25}], 'single typed path');
}

# 2. Two typed paths, alphabetical sort on the wire (age before name)
{
    my $out = rt('JSON(name String, age UInt32)', [
        {name => 'alice', age => 30},
        {name => 'bob',   age => 25},
    ]);
    is_deeply($out, [{name => 'alice', age => 30},
                     {name => 'bob',   age => 25}],
              'two typed paths round-trip');
}

# 3. Typed + dynamic mix
{
    my $out = rt('JSON(name String, age UInt32)', [
        {name => 'alice', age => 30},
        {name => 'bob',   age => 25, extra => 'more'},
    ]);
    is_deeply($out, [
        {name => 'alice', age => 30},
        {name => 'bob',   age => 25, extra => 'more'},
    ], 'typed + dynamic mix');
}

# 4. Missing typed key -> default value (0 for UInt32, '' for String)
{
    my $out = rt('JSON(score UInt32, label String)', [
        {score => 10, label => 'a'},
        {},  # both missing
    ]);
    is($out->[0]{score}, 10,    'row 0 score');
    is($out->[0]{label}, 'a',   'row 0 label');
    is($out->[1]{score}, 0,     'row 1 missing UInt32 -> 0');
    is($out->[1]{label}, '',    'row 1 missing String -> ""');
}

# 5. Nullable typed paths: undef -> NULL (decoded as undef)
{
    my $out = rt('JSON(maybe Nullable(Int32))', [
        {maybe => 42},
        {},          # missing
        {maybe => undef},
    ]);
    is($out->[0]{maybe}, 42, 'Nullable: value');
    is($out->[1]{maybe}, undef, 'Nullable: missing -> undef');
    is($out->[2]{maybe}, undef, 'Nullable: explicit undef -> undef');
}

# 6. Array typed path
{
    my $out = rt('JSON(tags Array(String))', [
        {tags => ['a','b','c']},
        {tags => []},
        {},
    ]);
    is_deeply($out->[0]{tags}, ['a','b','c'], 'Array(String) typed path');
    is_deeply($out->[1]{tags}, [], 'empty Array typed path');
    is_deeply($out->[2]{tags}, [], 'missing Array typed path -> []');
}

# 7. Dotted typed path name
{
    my $out = rt('JSON(user.id UInt64)', [
        {user => {id => 1}},
        {user => {id => 2}},
    ]);
    # Decoder distributes the typed path under the dotted key, then the
    # unflatten step on dynamic paths leaves "user.id" intact because
    # the typed-path distribution stores it directly. Either nested or
    # flat is acceptable - check both shapes.
    ok(exists $out->[0]{user} || exists $out->[0]{'user.id'},
       'dotted typed path landed somewhere');
    my $v0 = ref $out->[0]{user} ? $out->[0]{user}{id} : $out->[0]{'user.id'};
    is($v0, 1, 'dotted typed path value preserved');
}

# 8. JSON(...) parse errors
{
    my $err = eval {
        ClickHouse::Encoder->new(columns => [['j', 'JSON(x)']]); 1
    } ? '' : $@;
    like($err, qr/expected 'name Type'/, 'missing type rejected');
}
{
    my $err = eval {
        ClickHouse::Encoder->new(columns => [['j', 'JSON(a Int, a String)']]);
        1
    } ? '' : $@;
    like($err, qr/duplicate typed path name/, 'duplicate name rejected');
}

# 9. Typed path inner type with a wire prefix is rejected
{
    my $err = eval {
        ClickHouse::Encoder->new(columns =>
            [['j', 'JSON(x LowCardinality(String))']]); 1
    } ? '' : $@;
    like($err, qr/wire prefixes/, 'LowCardinality rejected as typed path');
}
{
    my $err = eval {
        ClickHouse::Encoder->new(columns =>
            [['j', 'JSON(x Variant(Int32, String))']]); 1
    } ? '' : $@;
    like($err, qr/wire prefixes/, 'Variant rejected as typed path');
}

# 10. Empty JSON() has no typed paths; the column data section (after
# the type-string header) is identical to plain JSON.
{
    my $b1 = ClickHouse::Encoder->new(columns => [['j','JSON']])
        ->encode([[{a => 1}]]);
    my $b2 = ClickHouse::Encoder->new(columns => [['j','JSON()']])
        ->encode([[{a => 1}]]);
    # The two buffers differ only in the type-string column header.
    # Decode both and compare values.
    my $v1 = ClickHouse::Encoder->decode_block($b1)->{columns}[0]{values};
    my $v2 = ClickHouse::Encoder->decode_block($b2)->{columns}[0]{values};
    is_deeply($v1, $v2, 'JSON() with no typed paths == JSON (decoded)');
}

# 11. Typed path with Boolean
{
    my $out = rt('JSON(active Bool)', [
        {active => 1},
        {active => 0},
    ]);
    is($out->[0]{active}, 1, 'Bool true');
    is($out->[1]{active}, 0, 'Bool false');
}

# 12. Zero-row encode + decode with typed paths (must not segfault)
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['j', 'JSON(name String, age UInt32)']]);
    my $bytes = $enc->encode([]);
    my $block = ClickHouse::Encoder->decode_block($bytes);
    is($block->{nrows}, 0, 'zero-row block: nrows=0');
    is_deeply($block->{columns}[0]{values}, [],
              'zero-row block: empty values');
}

# 13. Trailing-dot path name rejected
{
    my $err = eval {
        ClickHouse::Encoder->new(columns => [['j', 'JSON(a. Int32)']]); 1
    } ? '' : $@;
    like($err, qr/must not end with '\.'/, 'trailing-dot rejected');
}

# 14. Double-dot path name rejected
{
    my $err = eval {
        ClickHouse::Encoder->new(columns => [['j', 'JSON(a..b Int32)']]); 1
    } ? '' : $@;
    like($err, qr/consecutive dots/, 'double-dot rejected');
}

# 15. Explicit undef on a non-Nullable typed key: encode the default,
# do NOT leak the key into dynamic paths.
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['j', 'JSON(score UInt32)']]);
    my $bytes = $enc->encode([[{score => undef}]]);
    my $block = ClickHouse::Encoder->decode_block($bytes);
    is_deeply($block->{columns}[0]{values}, [{score => 0}],
              'undef on non-Nullable typed key -> default, no leak');
}

# 16a. Nullable(Map(...)) typed path - flatten must still stop at the
# typed path name even though the immediate type is Nullable.
{
    my $out = rt('JSON(attrs Nullable(Map(String, UInt32)))', [
        {attrs => {a => 1}},
        {attrs => undef},
        {},
    ]);
    is(ref $out->[0]{attrs}, 'ARRAY',
       'Nullable(Map) typed path: value as arrayref pairs');
    my %got = map { @$_ } @{ $out->[0]{attrs} };
    is_deeply(\%got, {a => 1},
              'Nullable(Map) typed path: contents preserved');
    is($out->[1]{attrs}, undef, 'Nullable(Map): explicit undef -> undef');
    is($out->[2]{attrs}, undef, 'Nullable(Map): missing -> undef');
}

# 16b. Dotted typed path with Map inner - combines stop_paths + dotted.
{
    my $out = rt('JSON(user.profile Map(String, UInt32))', [
        {user => {profile => {a => 1, b => 2}}},
    ]);
    # Stored at the dotted-path key after the decoder's unflatten step.
    my $v = $out->[0]{user}{profile} // $out->[0]{'user.profile'};
    ok($v, 'dotted Map typed path produces a value');
    is(ref $v, 'ARRAY',
       'dotted Map typed path: arrayref-of-pairs');
}

# 16. Map typed path (exercises type_can_be_typed_path's T_MAP branch).
# Map decodes as Array(Tuple(K,V)) on the wire; encode accepts either
# hashref or arrayref-of-pairs and the decoder returns arrayref-of-pairs.
{
    my $out = rt('JSON(attrs Map(String, UInt32))', [
        {attrs => {a => 1, b => 2}},
        {},
    ]);
    is(ref $out->[0]{attrs}, 'ARRAY', 'Map typed path decodes as arrayref');
    my %got = map { @$_ } @{ $out->[0]{attrs} };
    is_deeply(\%got, {a => 1, b => 2}, 'Map typed path values');
    is_deeply($out->[1]{attrs}, [], 'missing Map typed path -> []');
}

done_testing();
