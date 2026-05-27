use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;
use TestCH qw(read_varint skip_header);

# Test all integer types
for my $type (qw(Int8 Int16 Int32 Int64 UInt8 UInt16 UInt32 UInt64)) {
    my $enc = ClickHouse::Encoder->new(columns => [['v', $type]]);
    my $bin = $enc->encode([[42]]);
    ok(defined $bin && length($bin) > 0, "$type encodes");

    my $off = skip_header($bin);
    my $size = $type =~ /8/ ? 1 : $type =~ /16/ ? 2 : $type =~ /32/ ? 4 : 8;
    is(length($bin) - $off, $size, "$type correct size");
}

# Test Float32 and Float64
{
    my $enc32 = ClickHouse::Encoder->new(columns => [['v', 'Float32']]);
    my $bin32 = $enc32->encode([[3.14]]);
    my $off32 = skip_header($bin32);
    is(length($bin32) - $off32, 4, 'Float32 is 4 bytes');

    my $enc64 = ClickHouse::Encoder->new(columns => [['v', 'Float64']]);
    my $bin64 = $enc64->encode([[3.14]]);
    my $off64 = skip_header($bin64);
    is(length($bin64) - $off64, 8, 'Float64 is 8 bytes');
}

# Test FixedString
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'FixedString(10)']]);
    my $bin = $enc->encode([['hello']]);
    my $off = skip_header($bin);
    is(length($bin) - $off, 10, 'FixedString(10) is 10 bytes');

    # Verify padding
    my $data = substr($bin, $off);
    is(substr($data, 0, 5), 'hello', 'FixedString content');
    is(substr($data, 5), "\0" x 5, 'FixedString padding');
}

# Test FixedString truncation
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'FixedString(3)']]);
    my $bin = $enc->encode([['hello']]);
    my $off = skip_header($bin);
    my $data = substr($bin, $off);
    is($data, 'hel', 'FixedString truncates');
}

# Test empty array (native format uses UInt64 cumulative offsets)
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Array(UInt32)']]);
    my $bin = $enc->encode([[[]]]);
    ok(defined $bin, 'empty array encodes');
    my $off = skip_header($bin);
    # Offset is UInt64 (8 bytes), value 0 for empty array
    my $offset = unpack('Q<', substr($bin, $off, 8));
    is($offset, 0, 'empty array has offset 0');
}

# Test nested array
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Array(Array(UInt8))']]);
    my $bin = $enc->encode([[[[1,2],[3]]]]);
    ok(defined $bin, 'nested array encodes');
}

# Test Nullable(String)
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Nullable(String)']]);
    my $bin = $enc->encode([['hello'], [undef], ['world']]);
    ok(defined $bin, 'Nullable(String) encodes');
}

# Test Nullable(Array(...))
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Nullable(Array(UInt8))']]);
    my $bin = $enc->encode([[undef], [[1,2,3]]]);
    ok(defined $bin, 'Nullable(Array) encodes');
}

# Test multiple rows verify columnar layout
{
    my $enc = ClickHouse::Encoder->new(columns => [
        ['a', 'UInt8'],
        ['b', 'UInt8'],
    ]);
    my $bin = $enc->encode([[1, 10], [2, 20], [3, 30]]);

    # Skip header for col a
    my ($ncols, $off) = read_varint($bin, 0);
    is($ncols, 2, '2 columns');
    my ($nrows, $off2) = read_varint($bin, $off);
    is($nrows, 3, '3 rows');

    # Skip name "a" and type "UInt8"
    my ($name_len, $off3) = read_varint($bin, $off2);
    $off3 += $name_len;
    my ($type_len, $off4) = read_varint($bin, $off3);
    $off4 += $type_len;

    # Column a data (3 UInt8 values)
    is(ord(substr($bin, $off4, 1)), 1, 'col a row 0');
    is(ord(substr($bin, $off4+1, 1)), 2, 'col a row 1');
    is(ord(substr($bin, $off4+2, 1)), 3, 'col a row 2');
}

# Test error: unknown type
{
    eval { ClickHouse::Encoder->new(columns => [['v', 'UnknownType']]) };
    like($@, qr/Unknown type/, 'unknown type croaks');
}

# Test error: bad column spec
{
    eval { ClickHouse::Encoder->new(columns => [['only_name']]) };
    like($@, qr/Column must be/, 'bad column spec croaks');
}

# Test error: rows not arrayref
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'UInt8']]);
    eval { $enc->encode('not an array') };
    like($@, qr/must be arrayref/, 'non-arrayref rows croaks');
}

# Test error: row not arrayref
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'UInt8']]);
    eval { $enc->encode(['not an array']) };
    like($@, qr/Row \d+ must be arrayref/, 'non-arrayref row croaks');
}

# Test error: Array expects arrayref
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Array(UInt8)']]);
    eval { $enc->encode([['not an array']]) };
    like($@, qr/Expected arrayref for Array/, 'Array with scalar croaks');
}

# Test signed integers with negative values
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Int32']]);
    my $bin = $enc->encode([[-42]]);
    my $off = skip_header($bin);
    my $val = unpack('l<', substr($bin, $off, 4));
    is($val, -42, 'Int32 negative value');
}

# Test large UInt64
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'UInt64']]);
    my $big = 4611686018427387904;  # 2**62 as integer literal
    my $bin = $enc->encode([[$big]]);
    my $off = skip_header($bin);
    my $val = unpack('Q<', substr($bin, $off, 8));
    is($val, $big, 'UInt64 large value');
}

# Test Enum8
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['status', "Enum8('pending' = 0, 'active' = 1, 'closed' = 2)"]],
    );
    my $bin = $enc->encode([['pending'], ['active'], ['closed']]);
    my $off = skip_header($bin);
    is(ord(substr($bin, $off, 1)), 0, 'Enum8 pending = 0');
    is(ord(substr($bin, $off+1, 1)), 1, 'Enum8 active = 1');
    is(ord(substr($bin, $off+2, 1)), 2, 'Enum8 closed = 2');
}

# Test Enum16
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['code', "Enum16('alpha' = 1000, 'beta' = 2000)"]],
    );
    my $bin = $enc->encode([['alpha'], ['beta']]);
    my $off = skip_header($bin);
    is(unpack('v', substr($bin, $off, 2)), 1000, 'Enum16 alpha = 1000');
    is(unpack('v', substr($bin, $off+2, 2)), 2000, 'Enum16 beta = 2000');
}

# Test Enum8 with negative values
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', "Enum8('neg' = -1, 'zero' = 0, 'pos' = 1)"]],
    );
    my $bin = $enc->encode([['neg'], ['zero'], ['pos']]);
    my $off = skip_header($bin);
    is(unpack('c', substr($bin, $off, 1)), -1, 'Enum8 negative value');
    is(unpack('c', substr($bin, $off+1, 1)), 0, 'Enum8 zero value');
    is(unpack('c', substr($bin, $off+2, 1)), 1, 'Enum8 positive value');
}

# Test Nullable(Enum8)
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', "Nullable(Enum8('a' = 1, 'b' = 2))"]],
    );
    my $bin = $enc->encode([['a'], [undef], ['b']]);
    ok(defined $bin, 'Nullable(Enum8) encodes');
}

# Test Array(Enum8)
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', "Array(Enum8('x' = 10, 'y' = 20))"]],
    );
    my $bin = $enc->encode([[['x', 'y', 'x']]]);
    ok(defined $bin, 'Array(Enum8) encodes');
}

# Test unknown enum value error
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', "Enum8('a' = 1, 'b' = 2)"]],
    );
    eval { $enc->encode([['unknown']]) };
    like($@, qr/Unknown enum value/, 'unknown enum value croaks');
}

# Test Enum8 with integer values
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', "Enum8('pending' = 0, 'active' = 1, 'closed' = 2)"]],
    );
    my $bin = $enc->encode([[0], [1], [2]]);
    my $off = skip_header($bin);
    is(ord(substr($bin, $off, 1)), 0, 'Enum8 integer 0');
    is(ord(substr($bin, $off+1, 1)), 1, 'Enum8 integer 1');
    is(ord(substr($bin, $off+2, 1)), 2, 'Enum8 integer 2');
}

# Test Enum16 with integer values
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', "Enum16('alpha' = 1000, 'beta' = 2000)"]],
    );
    my $bin = $enc->encode([[1000], [2000]]);
    my $off = skip_header($bin);
    is(unpack('v', substr($bin, $off, 2)), 1000, 'Enum16 integer 1000');
    is(unpack('v', substr($bin, $off+2, 2)), 2000, 'Enum16 integer 2000');
}

# Test Enum8 with mixed string and integer values
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', "Enum8('a' = 1, 'b' = 2, 'c' = 3)"]],
    );
    my $bin = $enc->encode([['a'], [2], ['c']]);
    my $off = skip_header($bin);
    is(ord(substr($bin, $off, 1)), 1, 'Enum8 mixed: string a = 1');
    is(ord(substr($bin, $off+1, 1)), 2, 'Enum8 mixed: integer 2');
    is(ord(substr($bin, $off+2, 1)), 3, 'Enum8 mixed: string c = 3');
}

# Test Enum8 integer with negative value
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', "Enum8('neg' = -1, 'zero' = 0)"]],
    );
    my $bin = $enc->encode([[-1], [0]]);
    my $off = skip_header($bin);
    is(unpack('c', substr($bin, $off, 1)), -1, 'Enum8 integer -1');
    is(unpack('c', substr($bin, $off+1, 1)), 0, 'Enum8 integer 0');
}

# Test Decimal32
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Decimal32(2)']],
    );
    my $bin = $enc->encode([[123.45], [-67.89], [0.01]]);
    my $off = skip_header($bin);
    is(unpack('l<', substr($bin, $off, 4)), 12345, 'Decimal32(2) 123.45 = 12345');
    is(unpack('l<', substr($bin, $off+4, 4)), -6789, 'Decimal32(2) -67.89 = -6789');
    is(unpack('l<', substr($bin, $off+8, 4)), 1, 'Decimal32(2) 0.01 = 1');
}

# Test Decimal64
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Decimal64(4)']],
    );
    my $bin = $enc->encode([[123.4567]]);
    my $off = skip_header($bin);
    is(unpack('q<', substr($bin, $off, 8)), 1234567, 'Decimal64(4) 123.4567 = 1234567');
}

# Test Decimal(P, S) syntax
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Decimal(9, 2)']],  # maps to Decimal32
    );
    my $bin = $enc->encode([[99.99]]);
    my $off = skip_header($bin);
    is(unpack('l<', substr($bin, $off, 4)), 9999, 'Decimal(9,2) 99.99 = 9999');
}

# Test Decimal128
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Decimal128(2)']],
    );
    my $bin = $enc->encode([[123.45]]);
    my $off = skip_header($bin);
    my $lo = unpack('q<', substr($bin, $off, 8));
    my $hi = unpack('q<', substr($bin, $off+8, 8));
    is($lo, 12345, 'Decimal128(2) low part');
    is($hi, 0, 'Decimal128(2) high part');
}

# Test Decimal128 negative
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Decimal128(2)']],
    );
    my $bin = $enc->encode([[-123.45]]);
    my $off = skip_header($bin);
    my $lo = unpack('q<', substr($bin, $off, 8));
    my $hi = unpack('q<', substr($bin, $off+8, 8));
    is($lo, -12345, 'Decimal128(2) negative low part');
    is($hi, -1, 'Decimal128(2) negative high part (sign extension)');
}

# Test Nullable(Decimal32)
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Nullable(Decimal32(2))']],
    );
    my $bin = $enc->encode([[123.45], [undef]]);
    ok(defined $bin, 'Nullable(Decimal32) encodes');
}

# Test Array(Decimal64)
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Array(Decimal64(2))']],
    );
    my $bin = $enc->encode([[[1.23, 4.56]]]);
    ok(defined $bin, 'Array(Decimal64) encodes');
}

# Test UTF-8 String
{
    use utf8;
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'String']]);
    my $utf8_str = "Привет мир 日本語 🎉";
    my $bin = $enc->encode([[$utf8_str]]);
    ok(defined $bin, 'UTF-8 string encodes');

    my $off = skip_header($bin);
    my ($len, $off2) = read_varint($bin, $off);
    my $decoded = substr($bin, $off2, $len);
    utf8::decode($decoded);
    is($decoded, $utf8_str, 'UTF-8 string content preserved');
}

# Test UTF-8 FixedString (truncation on byte boundary)
{
    use utf8;
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'FixedString(6)']]);
    # "Привет" is 12 bytes in UTF-8, should truncate to 6 bytes
    my $bin = $enc->encode([["Привет"]]);
    my $off = skip_header($bin);
    is(length(substr($bin, $off)), 6, 'UTF-8 FixedString truncates by bytes');
}

# Test empty rows
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'UInt32']]);
    my $bin = $enc->encode([]);
    ok(defined $bin, 'empty rows encodes');
    my ($ncols, $off) = read_varint($bin, 0);
    my ($nrows, $off2) = read_varint($bin, $off);
    is($nrows, 0, 'empty rows count is 0');
}

# Test Tuple error handling
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Tuple(UInt8, UInt8)']]);
    eval { $enc->encode([['not a tuple']]) };
    like($@, qr/Expected arrayref or hashref for Tuple/, 'Tuple with scalar croaks');
}

# Test Date with string
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Date']]);
    my $bin = $enc->encode([['1970-01-01'], ['2000-01-01'], ['2024-06-15']]);
    my $off = skip_header($bin);
    is(unpack('v', substr($bin, $off, 2)), 0, 'Date 1970-01-01 = 0');
    is(unpack('v', substr($bin, $off+2, 2)), 10957, 'Date 2000-01-01 = 10957');
    is(unpack('v', substr($bin, $off+4, 2)), 19889, 'Date 2024-06-15 = 19889');
}

# Test Date with integer (days since epoch)
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Date']]);
    my $bin = $enc->encode([[0], [10957]]);
    my $off = skip_header($bin);
    is(unpack('v', substr($bin, $off, 2)), 0, 'Date numeric 0');
    is(unpack('v', substr($bin, $off+2, 2)), 10957, 'Date numeric 10957');
}

# Test Date32 with string (supports wider range including negative)
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Date32']]);
    my $bin = $enc->encode([['1970-01-01'], ['1900-01-01']]);
    my $off = skip_header($bin);
    is(unpack('l<', substr($bin, $off, 4)), 0, 'Date32 1970-01-01 = 0');
    # 1900-01-01 is before epoch, should be negative
    my $days_1900 = unpack('l<', substr($bin, $off+4, 4));
    ok($days_1900 < 0, 'Date32 1900-01-01 is negative');
}

# Test DateTime with string
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'DateTime']]);
    my $bin = $enc->encode([['1970-01-01 00:00:00'], ['2000-01-01 12:30:45']]);
    my $off = skip_header($bin);
    is(unpack('V', substr($bin, $off, 4)), 0, 'DateTime epoch = 0');
    # 2000-01-01 12:30:45 = 10957 days * 86400 + 12*3600 + 30*60 + 45
    my $expected = 10957 * 86400 + 12 * 3600 + 30 * 60 + 45;
    is(unpack('V', substr($bin, $off+4, 4)), $expected, 'DateTime 2000-01-01 12:30:45');
}

# Test DateTime with Unix timestamp
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'DateTime']]);
    my $bin = $enc->encode([[1700000000]]);
    my $off = skip_header($bin);
    is(unpack('V', substr($bin, $off, 4)), 1700000000, 'DateTime Unix timestamp');
}

# Test DateTime with timezone (timezone ignored for encoding)
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', "DateTime('UTC')"]]);
    my $bin = $enc->encode([[1700000000]]);
    my $off = skip_header($bin);
    is(unpack('V', substr($bin, $off, 4)), 1700000000, 'DateTime with timezone');
}

# Test DateTime64 with string (milliseconds)
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'DateTime64(3)']]);
    my $bin = $enc->encode([['1970-01-01 00:00:00.000'], ['1970-01-01 00:00:01.500']]);
    my $off = skip_header($bin);
    is(unpack('q<', substr($bin, $off, 8)), 0, 'DateTime64(3) epoch = 0');
    is(unpack('q<', substr($bin, $off+8, 8)), 1500, 'DateTime64(3) 1.5 seconds = 1500');
}

# Test DateTime64 with float
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'DateTime64(3)']]);
    my $bin = $enc->encode([[1.5]]);  # 1.5 seconds since epoch
    my $off = skip_header($bin);
    is(unpack('q<', substr($bin, $off, 8)), 1500, 'DateTime64(3) float 1.5 = 1500');
}

# Test DateTime64 with microseconds
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'DateTime64(6)']]);
    my $bin = $enc->encode([['1970-01-01 00:00:00.123456']]);
    my $off = skip_header($bin);
    is(unpack('q<', substr($bin, $off, 8)), 123456, 'DateTime64(6) microseconds');
}

# Test Nullable(Date)
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Nullable(Date)']]);
    my $bin = $enc->encode([['2024-01-01'], [undef]]);
    ok(defined $bin, 'Nullable(Date) encodes');
}

# Test Array(DateTime)
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Array(DateTime)']]);
    my $bin = $enc->encode([[[1700000000, 1700000001]]]);
    ok(defined $bin, 'Array(DateTime) encodes');
}

# Test DateTime64 with nanoseconds
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'DateTime64(9)']]);
    my $bin = $enc->encode([['1970-01-01 00:00:00.123456789']]);
    my $off = skip_header($bin);
    is(unpack('q<', substr($bin, $off, 8)), 123456789, 'DateTime64(9) nanoseconds');
}

# Test DateTime64 before 1970 (negative timestamp)
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'DateTime64(3)']]);
    my $bin = $enc->encode([['1969-12-31 23:59:59.000']]);
    my $off = skip_header($bin);
    my $val = unpack('q<', substr($bin, $off, 8));
    is($val, -1000, 'DateTime64(3) before epoch = -1000ms');
}

# Test Nullable(Tuple)
{
    no warnings 'uninitialized';  # nulls in tuples create placeholder undefs
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Nullable(Tuple(UInt8, String))']]);
    my $bin = $enc->encode([[[1, 'hello']], [undef], [[2, 'world']]]);
    ok(defined $bin, 'Nullable(Tuple) encodes');
}

# Test long string (multi-byte varint length)
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'String']]);
    my $long_str = 'x' x 200;  # > 127 bytes requires 2-byte varint
    my $bin = $enc->encode([[$long_str]]);
    my $off = skip_header($bin);
    my ($len, $off2) = read_varint($bin, $off);
    is($len, 200, 'long string varint length');
    is(substr($bin, $off2, 200), $long_str, 'long string content');
}

# Test Decimal zero
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal32(2)']]);
    my $bin = $enc->encode([[0.0]]);
    my $off = skip_header($bin);
    is(unpack('l<', substr($bin, $off, 4)), 0, 'Decimal32 zero');
}

# Test Decimal rounding. Use 1.236 not 1.235: at the .005 half-boundary the
# double representation varies across libc/perl versions (some get 1.23499...
# and round down, some get 1.23500... and round up); 1.236 stores as
# ~1.2359999... on every platform, so ceil(*100) = 124 deterministically.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal32(2)']]);
    my $bin = $enc->encode([[1.236]]);
    my $off = skip_header($bin);
    is(unpack('l<', substr($bin, $off, 4)), 124, 'Decimal32 rounding (1.236 -> 124)');
}

# Test multiple columns with mixed types
{
    my $enc = ClickHouse::Encoder->new(columns => [
        ['id', 'UInt32'],
        ['name', 'String'],
        ['tags', 'Array(String)'],
        ['score', 'Nullable(Float64)'],
    ]);
    my $bin = $enc->encode([
        [1, 'Alice', ['perl', 'db'], 95.5],
        [2, 'Bob', [], undef],
    ]);
    ok(defined $bin, 'multiple columns with mixed types encodes');
    my ($ncols, $off) = read_varint($bin, 0);
    my ($nrows, $off2) = read_varint($bin, $off);
    is($ncols, 4, 'mixed types 4 columns');
    is($nrows, 2, 'mixed types 2 rows');
}

done_testing();
