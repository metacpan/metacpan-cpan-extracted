use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;

# RowBinary encode/decode. The implementation reuses the XS Native
# codec (one-row block slice on encode, one-row block wrap on decode),
# so the strongest check is a round-trip: encode_row_binary then
# decode_row_binary must reproduce the input, and the per-value bytes
# must match the value region of the equivalent Native block.

# --- round-trip across the supported type surface ----------------------
# The invariant is not "decode == original input" (encode normalises
# some types, e.g. Decimal is scaled), but "RowBinary decode == Native
# decode of the same encoded values": both formats share the per-value
# wire bytes, so both decoders must yield identical Perl values.
{
    my $enc = ClickHouse::Encoder->new(columns => [
        ['i8',   'Int8'],
        ['u64',  'UInt64'],
        ['f64',  'Float64'],
        ['s',    'String'],
        ['fs',   'FixedString(4)'],
        ['d',    'Date'],
        ['dt',   'DateTime'],
        ['dt64', 'DateTime64(3)'],
        ['dec',  'Decimal64(2)'],
        ['uuid', 'UUID'],
        ['ip',   'IPv4'],
        ['b',    'Bool'],
        ['n',    'Nullable(Int32)'],
        ['arr',  'Array(String)'],
        ['lc',   'LowCardinality(String)'],
    ]);
    my @rows = (
        [-5, 18446744073709551615, 1.5, 'hello', 'abcd',
         19000, 1700000000, '1700000000.123',
         '123.45', '550e8400-e29b-41d4-a716-446655440000', '10.0.0.1',
         1, 42, ['a', 'bb', ''], 'red'],
        [127, 0, -0.25, '', "\x00\x01\x02\x03",
         0, 0, 0, '-1.00', '00000000-0000-0000-0000-000000000000',
         '0.0.0.0', 0, undef, [], ''],
    );
    my $rb   = $enc->encode_row_binary(\@rows);
    ok(length($rb) > 0, 'encode_row_binary produces bytes');
    my $back   = $enc->decode_row_binary($rb);
    my $native = $enc->decode_rows($enc->encode(\@rows))->{rows};
    is(scalar @$back, 2, 'decode_row_binary recovers row count');
    is_deeply($back, $native,
              'RowBinary decode matches Native decode (every type)');
}

# --- per-value bytes equal the Native one-row value region -------------
# A single Int32 column: Native one-row block is
#   varint(1) varint(1) lenstr("v") lenstr("Int32") <4 value bytes>
# and RowBinary for that row is exactly the 4 value bytes.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Int32']]);
    my $rb  = $enc->encode_row_binary([[ 0x01020304 ]]);
    is($rb, pack('l<', 0x01020304),
       'RowBinary Int32 == little-endian 4 bytes');
}

# --- Array uses a varint count (not the Native UInt64 offset) ----------
{
    my $enc = ClickHouse::Encoder->new(columns => [['a', 'Array(UInt8)']]);
    my $rb  = $enc->encode_row_binary([[ [1, 2, 3] ]]);
    is($rb, "\x03\x01\x02\x03",
       'RowBinary Array = varint(count) + elements');
}

# --- nested Array(Array(...)) ------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['m', 'Array(Array(Int16))']]);
    my @rows = ([ [[1,2],[3],[]] ], [ [] ]);
    my $back = $enc->decode_row_binary($enc->encode_row_binary(\@rows));
    is_deeply($back, \@rows, 'nested Array(Array(Int16)) round-trips');
}

# --- Nullable null vs zero are distinct --------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['n', 'Nullable(Int32)']]);
    my $back = $enc->decode_row_binary(
        $enc->encode_row_binary([[undef], [0], [-1]]));
    is_deeply($back, [[undef], [0], [-1]],
              'Nullable distinguishes undef from 0');
}

# --- unsupported types croak with a clear message ----------------------
for my $bad (
    ['Map(String, Int32)',    { k => 1 }],
    ['Tuple(Int32, String)',  [1, 'x']],
    ['JSON',                  { a => 1 }],
    ['Point',                 [1.0, 2.0]],
) {
    my ($type, $val) = @$bad;
    my $enc = ClickHouse::Encoder->new(columns => [['c', $type]]);
    local $@;
    eval { $enc->encode_row_binary([[ $val ]]) };
    like($@, qr/not supported/,
         "encode_row_binary croaks on $type");
}

# --- input-shape validation --------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['a','Int32'],['b','Int32']]);
    local $@;
    eval { $enc->encode_row_binary([[1]]) };
    like($@, qr/row 0 has 1 values, expected 2/,
         'encode_row_binary checks row arity');
    eval { $enc->encode_row_binary('not-an-arrayref') };
    like($@, qr/rows must be an arrayref/,
         'encode_row_binary checks top-level arrayref');
}

# --- empty input -------------------------------------------------------
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Int32']]);
    is($enc->encode_row_binary([]), '', 'zero rows -> empty string');
    is_deeply($enc->decode_row_binary(''), [], 'empty string -> zero rows');
}


# decode_row_binary needs an encoder instance for its column types;
# calling it as a class method has nothing to decode against.
{
    local $@;
    eval { ClickHouse::Encoder->decode_row_binary("\x01\x02") };
    like($@, qr/must be called on an encoder instance/,
         'decode_row_binary as class method croaks');
}

# A zero-column encoder would loop forever on any non-empty buffer
# (no per-column work to advance the cursor); guard explicitly.
{
    my $enc = ClickHouse::Encoder->new(columns => []);
    is_deeply($enc->decode_row_binary(''), [],
              'zero columns + empty buffer -> no rows');
    local $@;
    eval { $enc->decode_row_binary("\x01") };
    like($@, qr/no columns but/, 'zero columns + non-empty buffer croaks');
}

done_testing();
