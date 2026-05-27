#!/usr/bin/env perl
# Pin encode_column / make_null_placeholder behavior under deep type
# trees. Catches recursion bugs that don't show up with shallow types
# (e.g. stack depth, missed pTHX_ propagation, mortal accumulation).
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch', 't/lib';
use Test::More;
use ClickHouse::Encoder;
use TestCH qw(read_varint_ref);
*read_varint = \&read_varint_ref;

# Array(Array(Array(Tuple(Int32, Nullable(String))))) - 3 array levels
# wrapping a 2-element tuple where the second element is nullable.
{
    my $type = 'Array(Array(Array(Tuple(Int32, Nullable(String)))))';
    my $enc = ClickHouse::Encoder->new(columns => [['v', $type]]);
    my $rows = [
        [ [[[ [1, 'one'],   [2, undef] ],
            [ [3, 'three'] ]],
           [[ [4, 'four']  ]]] ],
        [ [] ],                                  # empty outer
        [ [ [] ] ],                              # one empty mid-level
        [ [ [ [] ] ] ],                          # one empty innermost
    ];
    my $bin = $enc->encode($rows);
    ok(defined $bin && length $bin > 0, '4-level nested type encodes without croak');

    # The outer Array's offsets array has nrows = 4 UInt64 cumulative
    # counts. After the block header, the wire layout is:
    #   ncols varint + nrows varint + name + type + 4*UInt64 offsets + ...
    my $off = 0;
    read_varint(\$bin, \$off);          # ncols
    read_varint(\$bin, \$off);          # nrows
    my $nl = read_varint(\$bin, \$off); $off += $nl;
    my $tl = read_varint(\$bin, \$off); $off += $tl;
    # First UInt64 offset = number of mid-arrays in row 0 = 2 (the two outer slots)
    is(unpack('Q<', substr($bin, $off, 8)), 2,
       '4-level Array: row 0 outer offset = 2 sub-arrays');
    # Row 1 is empty so cumulative stays at 2.
    is(unpack('Q<', substr($bin, $off + 8, 8)), 2,
       '4-level Array: row 1 cumulative stays at 2');
}

# Nullable(Array(Tuple(Int32, String))) -- a row of undef must encode
# as nulled-out but type-shaped placeholder.
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Nullable(Array(Tuple(Int32, String)))']]);
    my $bin = $enc->encode([[undef], [[ [1,'a'], [2,'b'] ]]]);
    ok(defined $bin && length $bin > 0,
       'Nullable(Array(Tuple)) handles undef row');
}

# Array(Nullable(Tuple(Int32, Nullable(String)))) -- the inner null
# placeholder for Tuple must be a zero-tuple, not undef.
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Array(Nullable(Tuple(Int32, Nullable(String))))']]);
    my $bin = $enc->encode([
        [[ [1, 'x'], undef, [2, undef] ]],
        [[]],
    ]);
    ok(defined $bin && length $bin > 0,
       'Array(Nullable(Tuple(...))) handles nullable tuple slot');
}

# Map(String, Array(Nullable(UInt32))) -- Map is Array(Tuple(K,V)) on
# the wire, so this drives the Map -> Tuple -> Array -> Nullable chain.
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Map(String, Array(Nullable(UInt32)))']]);
    my $bin = $enc->encode([
        [{ a => [1, undef, 3], b => [] }],
        [{}],
    ]);
    ok(defined $bin && length $bin > 0,
       'Map(String, Array(Nullable(UInt32))) encodes with mixed nulls');
}

# A 6-level Array stack of plain UInt8 - tests how the offsets layout
# expands when each level is uniformly populated.
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Array(Array(Array(Array(Array(Array(UInt8))))))']]);
    my $bin = $enc->encode([
        [ [[[[[[1,2],[3]]]]],     # one outer item containing 5 nested levels
           [[[[[4],[5,6]]]]]] ],
    ]);
    ok(defined $bin && length $bin > 0,
       '6-level Array(UInt8) encodes');
}

done_testing();
