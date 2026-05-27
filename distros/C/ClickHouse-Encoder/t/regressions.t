use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# Each test pins down a bug fixed during the review.

# Bug: Nullable(Tuple(<complex>)) crashed on null rows because the placeholder
# was [undef, ...] which is not an arrayref for nested Tuple/Array elements.
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Nullable(Tuple(Array(Int32), String))']],
    );
    my $bin = eval { $enc->encode([[[[1,2,3], 'hi']], [undef], [[[4], 'bye']]]) };
    ok(defined $bin, 'Nullable(Tuple(Array)) handles null rows');
}
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Nullable(Tuple(Tuple(UInt8, UInt8)))']],
    );
    my $bin = eval { $enc->encode([[[[1, 2]]], [undef], [[[3, 4]]]]) };
    ok(defined $bin, 'Nullable(Tuple(Tuple)) handles null rows');
}

# Bug: numeric strings ("1700000000") were parsed as date strings (silent garbage)
# because SvIOK is false for fresh PVs.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'DateTime']]);
    my $bin = $enc->encode([['1700000000']]);
    my $val = unpack('V', substr($bin, length($bin)-4, 4));
    is($val, 1700000000, 'DateTime numeric string treated as epoch');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Date']]);
    my $bin = $enc->encode([['10957']]);
    my $val = unpack('v', substr($bin, length($bin)-2, 2));
    is($val, 10957, 'Date numeric string treated as days');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'DateTime64(3)']]);
    my $bin = $enc->encode([['1500']]);
    my $val = unpack('q<', substr($bin, length($bin)-8, 8));
    is($val, 1500, 'DateTime64 integer string treated as scaled units');
}

# Bug: bad date strings silently produced 0.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Date']]);
    eval { $enc->encode([['bogus']]) };
    like($@, qr/Invalid date string/, 'bad date string croaks');

    eval { $enc->encode([['2024-13-99']]) };
    like($@, qr/out of range/, 'malformed YYYY-MM-DD croaks (no silent 0)');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'DateTime']]);
    eval { $enc->encode([['2024/06/15 12:30:45']]) };
    like($@, qr/Invalid date string/, 'bad datetime separator croaks');
}

# Bug: Decimal precision lost via SvNV double round-trip.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal64(0)']]);
    my $bin = $enc->encode([['9007199254740993']]);  # 2^53+1
    my $val = unpack('q<', substr($bin, length($bin)-8, 8));
    is($val, 9007199254740993, 'Decimal64 string preserves digits past double precision');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal64(4)']]);
    my $bin = $enc->encode([['12345.6789']]);
    my $val = unpack('q<', substr($bin, length($bin)-8, 8));
    is($val, 123456789, 'Decimal64(4) string scales correctly');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal128(2)']]);
    my $bin = $enc->encode([['-99999999999999999999.99']]);
    my $lo = unpack('Q<', substr($bin, length($bin)-16, 8));
    my $hi = unpack('q<', substr($bin, length($bin)-8, 8));
    ok($hi < 0, 'Decimal128 huge negative has negative high part');
    isnt($lo, 0, 'Decimal128 huge negative has non-zero low part');
}

# Bug: Decimal32 didn't validate string overflow; would silently truncate.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal32(2)']]);
    eval { $enc->encode([['999999999.99']]) };
    like($@, qr/Decimal32 overflow|Decimal/, 'Decimal32 string overflow croaks');
}
{
    # Decimal64 float-path overflow: 1e20 * 1 (scale 0) is finite but outside int64.
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal64(0)']]);
    eval { $enc->encode([[1e20]]) };
    like($@, qr/Decimal64 overflow/, 'Decimal64 float overflow croaks');
    eval { $enc->encode([['Inf' + 0]]) };
    like($@, qr/Decimal64 overflow/, 'Decimal64 Inf croaks via the same range check');

    # Decimal64 boundary: 1e19 is finite and just past int64 (9.22e18). Must croak.
    eval { $enc->encode([[1e19]]) };
    like($@, qr/Decimal64 overflow/, 'Decimal64 boundary 1e19 croaks');
}
{
    # Decimal128 float-path overflow check
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal128(0)']]);
    eval { $enc->encode([[1e40]]) };
    like($@, qr/Decimal128 overflow|Decimal/, 'Decimal128 float overflow croaks');
}
{
    # Decimal256 float-path: anything over 2^256 must croak (was silently truncated).
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal256(0)']]);
    eval { $enc->encode([[1e80]]) };
    like($@, qr/Decimal256 overflow/, 'Decimal256 float overflow croaks');
}
{
    # String-path overflow regression: 2^127 / 2^128 / 2^256 etc. must croak,
    # not silently wrap. Boundary values (INT128_MAX / INT128_MIN / INT256_MAX
    # / INT256_MIN) must still work.
    my $d128 = ClickHouse::Encoder->new(columns => [['v', 'Decimal128(0)']]);
    eval { $d128->encode([['170141183460469231731687303715884105728']]) };  # 2^127
    like($@, qr/Invalid decimal string/, 'Decimal128 string 2^127 (just past max) croaks');
    eval { $d128->encode([['340282366920938463463374607431768211456']]) };  # 2^128
    like($@, qr/Invalid decimal string/, 'Decimal128 string 2^128 croaks (no silent wrap)');
    eval { $d128->encode([['340282366920938463463374607431768211455']]) };  # 2^128-1
    like($@, qr/Invalid decimal string/, 'Decimal128 string UINT128_MAX croaks');
    ok(defined eval { $d128->encode([['170141183460469231731687303715884105727']]) },
        'Decimal128 string INT128_MAX accepted');
    ok(defined eval { $d128->encode([['-170141183460469231731687303715884105728']]) },
        'Decimal128 string INT128_MIN accepted');

    my $d256 = ClickHouse::Encoder->new(columns => [['v', 'Decimal256(0)']]);
    eval { $d256->encode([['115792089237316195423570985008687907853269984665640564039457584007913129639936']]) };  # 2^256
    like($@, qr/Invalid decimal string/, 'Decimal256 string 2^256 croaks');
    ok(defined eval { $d256->encode([['57896044618658097711785492504343953926634992332820282019728792003956564819967']]) },
        'Decimal256 string INT256_MAX accepted');
    ok(defined eval { $d256->encode([['-57896044618658097711785492504343953926634992332820282019728792003956564819968']]) },
        'Decimal256 string INT256_MIN accepted');
}
{
    # parse_date_string out-of-bounds read for month >= 14 (looks_like_date
    # only validates digit shape, not range). Regression for OOB into
    # days_in_month[12+].
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Date']]);
    eval { $enc->encode([['2024-14-15']]) };
    like($@, qr/out of range/, 'Date month=14 croaks (no OOB read)');
    eval { $enc->encode([['2024-99-99']]) };
    like($@, qr/out of range/, 'Date month=99 day=99 croaks');
    eval { $enc->encode([['2024-00-15']]) };
    like($@, qr/out of range/, 'Date month=00 croaks');
    eval { $enc->encode([['2024-06-32']]) };
    like($@, qr/out of range/, 'Date day=32 croaks');

    # Per-month day validation
    eval { $enc->encode([['2024-04-31']]) };
    like($@, qr/exceeds month/, 'Date 2024-04-31 (April has 30 days) croaks');
    eval { $enc->encode([['2023-02-29']]) };
    like($@, qr/exceeds month/, 'Date 2023-02-29 (non-leap February) croaks');
    eval { $enc->encode([['2024-02-30']]) };
    like($@, qr/exceeds month/, 'Date 2024-02-30 croaks (Feb max is 29 in leap year)');
    ok(defined eval { $enc->encode([['2024-02-29']]) },
        'Date 2024-02-29 (leap year) accepted');
}

# Bug: row column count mismatch silently corrupted output.
{
    my $enc = ClickHouse::Encoder->new(columns => [['a', 'UInt32'], ['b', 'String']]);
    eval { $enc->encode([[1, 'ok'], [2]]) };
    like($@, qr/Row .* columns/, 'short row croaks');

    eval { $enc->encode([[1, 'ok', 'extra']]) };
    like($@, qr/Row .* columns/, 'long row croaks');
}

# Bug: Enum value out-of-range was silently truncated.
{
    eval { ClickHouse::Encoder->new(columns => [['v', "Enum8('big' = 300)"]]) };
    like($@, qr/out of range/, 'Enum8 value 300 rejected at parse time');

    eval { ClickHouse::Encoder->new(columns => [['v', "Enum16('huge' = 100000)"]]) };
    like($@, qr/out of range/, 'Enum16 value 100000 rejected at parse time');
}

# Enum value out-of-range at row-encode time (integer input).
{
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', "Enum8('a' = 1, 'b' = 2)"]],
    );
    eval { $enc->encode([[200]]) };
    like($@, qr/out of range/, 'Enum8 integer value 200 rejected at encode time');
}

# Bug: empty enum name silently accepted.
{
    eval { ClickHouse::Encoder->new(columns => [['v', "Enum8('' = 1)"]]) };
    like($@, qr/empty name/, 'empty enum name rejected');
}
{
    # Enum names with backslash-escaped quotes (as CH emits in describe table)
    # must be unescaped in storage so user lookup matches.
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', q{Enum8('it\'s' = 1, 'plain' = 2)}]],
    );
    my $bin = $enc->encode([["it's"], ['plain']]);
    is(ord(substr($bin, length($bin)-2, 1)), 1,
       q{Enum8 with \' in name: lookup matches the apostrophe form});
    is(ord(substr($bin, length($bin)-1, 1)), 2,
       'Enum8 plain entry alongside escaped one');
}

# Bug: Nullable(Nullable(T)) silently accepted (CH would reject).
{
    eval { ClickHouse::Encoder->new(columns => [['v', 'Nullable(Nullable(Int32))']]) };
    like($@, qr/Nullable\(Nullable/, 'Nullable(Nullable()) rejected');
}

# Bug: FixedString(0) silently accepted.
{
    eval { ClickHouse::Encoder->new(columns => [['v', 'FixedString(0)']]) };
    like($@, qr/FixedString needs positive length|positive/, 'FixedString(0) rejected');
}

# IEEE float special values must be preserved (LE byte order verification).
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Float32']]);
    my $bin = $enc->encode([['Inf'+0], [-'Inf'+0], ['NaN'+0]]);
    my $off = length($bin) - 12;
    my @bytes = map { unpack('H8', substr($bin, $off + $_*4, 4)) } 0..2;
    is($bytes[0], '0000807f', '+Inf as Float32 LE bytes');
    is($bytes[1], '000080ff', '-Inf as Float32 LE bytes');
    # IEEE 754 doesn't pin down NaN's sign bit; macOS / glibc / different
    # libc strtod implementations give either sign. Accept both.
    like($bytes[2], qr/^[0-9a-f]{4}c[0-9a-f][7f]f$/, 'NaN as Float32 LE bytes (quiet bit set, either sign)');
}

# UTF-8 byte boundary for FixedString — not codepoint truncation.
{
    use utf8;
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'FixedString(6)']]);
    my $bin = $enc->encode([['Привет']]);  # 12 UTF-8 bytes
    my $tail = substr($bin, length($bin) - 6);
    is(length($tail), 6, 'FixedString truncates by bytes, not codepoints');
    # The first 6 bytes of "Привет" are bytes for "Прив"-prefix (UTF-8)
    is($tail, "\xd0\x9f\xd1\x80\xd0\xb8", 'UTF-8 bytes preserved');
}

# Bug: Variant sub-columns and discriminators must be emitted in
# alphabetical order of variant type names, not declaration order.
# Real ClickHouse rejects declaration-ordered buffers when the
# declaration is not alphabetical (TOO_LARGE_ARRAY_SIZE / "is empty,
# but expected to be read N values" depending on the inner types).
{
    # Declaration is not alphabetical: UInt32 before String. Wire order
    # is alphabetical (String=0, UInt32=1). The user's declaration idx
    # 0 (UInt32) must be emitted as wire byte 1, and sub-columns must
    # come out String first then UInt32.
    my $enc = ClickHouse::Encoder->new(
        columns => [['v', 'Variant(UInt32, String)']],
    );
    my $bin = $enc->encode([[[0, 42]], [[1, 'hi']]]);
    my $col_off = 2 + 1 + 1 + 1 + length('Variant(UInt32, String)');
    my $disc_off = $col_off + 8;
    my @disc = (ord(substr($bin, $disc_off, 1)),
                ord(substr($bin, $disc_off + 1, 1)));
    is($disc[0], 1, 'wire discriminator for declared UInt32 is alphabetical 1');
    is($disc[1], 0, 'wire discriminator for declared String is alphabetical 0');
    my $sc_off = $disc_off + 2;
    is(ord(substr($bin, $sc_off, 1)), 2, 'String sub-col first (varint length 2)');
    is(substr($bin, $sc_off + 1, 2), 'hi', 'String sub-col content');
    is(unpack('V', substr($bin, $sc_off + 3, 4)), 42,
       'UInt32 sub-col second, value 42');
}

{
    # LC(String) (non-Nullable) with undef previously emitted
    # "Use of uninitialized value" via SvPV. The encoder now coerces
    # undef to "" silently, matching the plain-String path.
    use warnings FATAL => 'uninitialized';
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'LowCardinality(String)']]);
    my $bin = eval { $enc->encode([[undef], [""], ["a"]]) };
    is($@, '', 'LC(String) undef does not emit uninitialized warning');
    ok(defined $bin && length $bin > 0, 'LC(String) undef produces bytes');
}

done_testing();
