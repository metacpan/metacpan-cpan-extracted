#!/usr/bin/env perl
use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# JSON::PP is core - use it to get booleans
use JSON::PP ();

my $enc = ClickHouse::Encoder->new(columns => [['j', 'JSON']]);

sub roundtrip {
    my ($rows) = @_;
    my $bytes = $enc->encode([map [$_], @$rows]);
    my $block = ClickHouse::Encoder->decode_block($bytes);
    return [map $_->{values}, @{ $block->{columns} }]->[0];
}

# Basic single int
{
    my $out = roundtrip([{a => 42}]);
    is_deeply($out, [{a => 42}], 'single int path');
}

# Multi-row with missing paths
{
    my $out = roundtrip([
        {a => 1, b => "x"},
        {a => 2},
    ]);
    is_deeply($out, [{a => 1, b => "x"}, {a => 2}], 'multi-row missing path');
}

# All four scalar kinds in one column
{
    my $out = roundtrip([
        {x => 1},
        {x => "hello"},
        {x => 3.14},
        {x => JSON::PP::true},
    ]);
    is($out->[0]{x}, 1,       'int kind');
    is($out->[1]{x}, "hello", 'string kind');
    is($out->[2]{x}+0, 3.14,  'float kind');
    is($out->[3]{x}, 1,       'bool true');
}

# Nested objects -> dotted on wire, nested on read
{
    my $out = roundtrip([
        {user => {name => "alice", age => 30}},
        {user => {name => "bob"}},
    ]);
    is_deeply($out, [
        {user => {name => "alice", age => 30}},
        {user => {name => "bob"}},
    ], 'nested object round-trip');
}

# Three levels deep
{
    my $out = roundtrip([
        {a => {b => {c => 1}}},
    ]);
    is_deeply($out, [{a => {b => {c => 1}}}], 'three-level nesting');
}

# Empty and undef rows
{
    my $out = roundtrip([
        {},
        undef,
        {a => 1},
        {},
    ]);
    is(scalar(@$out), 4, 'empty/undef rows preserved');
    is_deeply($out->[0], {}, 'empty stays empty');
    is_deeply($out->[1], {}, 'undef decodes as empty');
    is_deeply($out->[2], {a => 1}, 'normal row after empties');
    is_deeply($out->[3], {}, 'trailing empty');
}

# Bool false
{
    my $out = roundtrip([{flag => JSON::PP::false}]);
    is($out->[0]{flag}, 0, 'bool false');
}

# Many paths
{
    my %row;
    $row{"k$_"} = $_ for 1..20;
    my $out = roundtrip([\%row]);
    is_deeply($out->[0], \%row, '20 paths in one row');
}

# Path with deeply nested empty hash (no leaves) - should produce no entry
{
    my $out = roundtrip([{a => {}, b => 1}]);
    is_deeply($out, [{b => 1}], 'empty nested hash drops out');
}

# Big numbers
{
    my $out = roundtrip([{big => 1_000_000_000_000}]);
    is($out->[0]{big}, 1_000_000_000_000, 'big int64');
}

# Negative numbers
{
    my $out = roundtrip([{n => -42}, {n => -3.14}]);
    is($out->[0]{n}, -42,   'negative int');
    cmp_ok($out->[1]{n}, '<', 0, 'negative float');
}

# Empty block
{
    my $bytes = $enc->encode([]);
    my $block = ClickHouse::Encoder->decode_block($bytes);
    is($block->{nrows}, 0, 'empty block: 0 rows');
}

# Array(Int64) leaf
{
    my $out = roundtrip([{tags => [1, 2, 3]}, {tags => [42]}]);
    is_deeply($out->[0]{tags}, [1, 2, 3], 'Array(Int64) round-trip row 0');
    is_deeply($out->[1]{tags}, [42],      'Array(Int64) round-trip row 1');
}

# Array(String) leaf
{
    my $out = roundtrip([{names => ["alice", "bob"]}, {names => []}]);
    is_deeply($out->[0]{names}, ["alice", "bob"], 'Array(String) values');
    is_deeply($out->[1]{names}, [], 'empty array round-trip');
}

# Array(Float64) and Array(Bool). Bool values come back as
# JSON::PP::Boolean refs (so they round-trip through encode as Bool
# rather than widening to Int64); compare numerically.
{
    my $out = roundtrip([
        {scores => [1.5, 2.5, 3.5]},
        {flags  => [JSON::PP::true, JSON::PP::false, JSON::PP::true]},
    ]);
    is_deeply($out->[0]{scores}, [1.5, 2.5, 3.5], 'Array(Float64) values');
    is_deeply([map 0 + $_, @{ $out->[1]{flags} }],
              [1, 0, 1], 'Array(Bool) values (numeric)');
    isa_ok($out->[1]{flags}[0], 'JSON::PP::Boolean',
           'Array(Bool) elements are JSON::PP::Boolean refs');
}

# Heterogeneous array still rejected
{
    my $err = eval {
        $enc->encode([[{mixed => [1, "two", 3.14]}]]); 1
    } ? "" : $@;
    like($err, qr/heterogeneous or unsupported array/,
         'mixed-type array rejected');
}

# Blessed-non-bool hashref-as-leaf is rejected (would otherwise
# silently flatten as if it were a plain hash).
{
    my $obj = bless {}, "MyCustomClass";
    my $err = eval { $enc->encode([[{x => $obj}]]); 1 } ? "" : $@;
    like($err, qr/opaque blessed hashref|MyCustomClass/,
         'opaque blessed hashref rejected');
}

# Reject non-hashref row
{
    my $err = eval { $enc->encode([['not a hash']]); 1 } ? "" : $@;
    like($err, qr/must be hashref or undef/, 'string row rejected');
}

# Two JSON columns side-by-side
{
    my $enc2 = ClickHouse::Encoder->new(
        columns => [['a', 'JSON'], ['b', 'JSON']]);
    my $bytes = $enc2->encode([
        [{x => 1}, {y => "hi"}],
        [{x => 2}, {y => "bye"}],
    ]);
    my $block = ClickHouse::Encoder->decode_block($bytes);
    is($block->{ncols}, 2, 'two JSON columns: ncols');
    is_deeply($block->{columns}[0]{values},
              [{x => 1}, {x => 2}], 'first column');
    is_deeply($block->{columns}[1]{values},
              [{y => "hi"}, {y => "bye"}], 'second column');
}

# Mixed columns: JSON next to a regular type
{
    my $enc3 = ClickHouse::Encoder->new(
        columns => [['id', 'Int64'], ['data', 'JSON']]);
    my $bytes = $enc3->encode([
        [1, {name => "alice"}],
        [2, {name => "bob", age => 30}],
    ]);
    my $block = ClickHouse::Encoder->decode_block($bytes);
    is_deeply($block->{columns}[0]{values}, [1, 2], 'Int64 column');
    is_deeply($block->{columns}[1]{values},
              [{name => "alice"}, {name => "bob", age => 30}],
              'JSON column alongside scalar column');
}

# Decoder error: truncated buffer
{
    my $bytes = $enc->encode([[{a => 42}]]);
    my $err = eval { ClickHouse::Encoder->decode_block(substr($bytes, 0, 20)); 1 } ? "" : $@;
    like($err, qr/truncated/i, 'truncated buffer croaks');
}

# Path collision: row N has {a: 1}, row N+1 has {a: {b: 2}} — encoder
# sees them as two separate paths "a" and "a.b". On decode, row N+1's
# unflatten ends up with both "a" (scalar) and "a.b" (scalar) -- the
# unflatten code detects the conflict and keeps the dotted form for "a.b".
{
    my $out = roundtrip([
        {a => 1},
        {a => {b => 2}},
    ]);
    is_deeply($out->[0], {a => 1}, 'row 0: scalar a');
    # Row 1 has both paths; CH stored "a"=null and "a.b"=2 for it.
    # The decoder gets {a.b => 2} flat and nests safely.
    is_deeply($out->[1], {a => {b => 2}},
              'row 1: nested a (no collision because path "a" is null here)');
}

# Bool tag - blessed scalarref into specific package
{
    my $true  = bless \(my $a = 1), 'Cpanel::JSON::XS::Boolean';
    my $false = bless \(my $b = 0), 'JSON::XS::Boolean';
    my $out = roundtrip([{x => $true}, {x => $false}]);
    is($out->[0]{x}, 1, 'Cpanel::JSON::XS::Boolean true');
    is($out->[1]{x}, 0, 'JSON::XS::Boolean false');
}

# Path with embedded NUL byte (pathological but valid Perl HV key)
{
    my $path = "a\0b";
    my $out = roundtrip([{$path => 1}]);
    # Should round-trip the binary key
    is_deeply([sort keys %{ $out->[0] }], [$path],
              'embedded NUL in path survives sort');
    is($out->[0]{$path}, 1, 'embedded NUL path value preserved');
}

# Perl 5.36+ native booleans (SvIsBOOL): exercise the #ifdef branch
# in json_classify_leaf when present.
SKIP: {
    skip 'native bool requires Perl 5.36+', 2 unless $] >= 5.036;
    my $out = roundtrip([{flag => !!1}, {flag => !!0}]);
    is($out->[0]{flag}, 1, 'native bool true');
    is($out->[1]{flag}, 0, 'native bool false');
}

# decode_rows row-major path over a JSON column - exercises the
# decode_block_rows codepath against a complex variant-shaped column
# rather than just plain scalars (covered elsewhere).
{
    my $bytes = $enc->encode([
        [{a => 1, b => "x"}],
        [{a => 2}],
        [{a => 3, b => "y", n => {k => 9}}],
    ]);
    my $r = ClickHouse::Encoder->decode_rows($bytes);
    is($r->{nrows}, 3, 'decode_rows over JSON: row count');
    is_deeply($r->{names}, ['j'], 'decode_rows over JSON: names');
    is_deeply($r->{rows}[0], [{a => 1, b => "x"}],         'row 0');
    is_deeply($r->{rows}[1], [{a => 2}],                   'row 1');
    is_deeply($r->{rows}[2], [{a => 3, b => "y", n => {k => 9}}], 'row 2');
}

# Float-integer collapse: 1.0 stored as Perl NV becomes Int64 on the
# wire (matches CH's JSONEachRow inference). Documented behavior.
{
    my $x = 1.0;  # in older Perls this may be SvNOK only
    $x += 0.0;    # force NV typing
    my $out = roundtrip([{v => $x}]);
    is($out->[0]{v}, 1, '1.0 NV collapses to Int64');
    # Genuine non-integer float stays float
    my $y = 3.14;
    my $out2 = roundtrip([{v => $y}]);
    cmp_ok($out2->[0]{v}, '>', 3.13, '3.14 stays float (lower bound)');
    cmp_ok($out2->[0]{v}, '<', 3.15, '3.14 stays float (upper bound)');
}

done_testing();
