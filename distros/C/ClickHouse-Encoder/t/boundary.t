use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch', 't/lib';
use ClickHouse::Encoder;
use TestCH qw(skip_header read_varint);

# Pin behaviour at the extreme values for each type. These mostly assert
# exact byte-level results so that future changes can't silently shift them.

# ---- integer boundaries -----------------------------------------------------

{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Int64']]);
    my $bin = $enc->encode([[-9223372036854775808], [9223372036854775807]]);
    my $off = skip_header($bin);
    is(unpack('q<', substr($bin, $off,    8)), -9223372036854775808, 'INT64_MIN');
    is(unpack('q<', substr($bin, $off+8,  8)),  9223372036854775807, 'INT64_MAX');
}

{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'UInt64']]);
    my $max_u64 = 0+'18446744073709551615';  # let Perl coerce to UV
    my $bin = $enc->encode([[0], [$max_u64]]);
    my $off = skip_header($bin);
    is(unpack('Q<', substr($bin, $off,   8)),                   0, 'UINT64_MIN');
    is(unpack('Q<', substr($bin, $off+8, 8)), 18446744073709551615, 'UINT64_MAX');
}

{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Int32']]);
    my $bin = $enc->encode([[-2147483648], [2147483647]]);
    my $off = skip_header($bin);
    is(unpack('l<', substr($bin, $off,   4)), -2147483648, 'INT32_MIN');
    is(unpack('l<', substr($bin, $off+4, 4)),  2147483647, 'INT32_MAX');
}

# ---- Date / Date32 boundaries ----------------------------------------------

{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Date']]);
    my $bin = $enc->encode([['1970-01-01'], ['2149-06-06']]);  # near UInt16 max
    my $off = skip_header($bin);
    is(unpack('v', substr($bin, $off,   2)),    0, 'Date 1970-01-01 = 0');
    cmp_ok(unpack('v', substr($bin, $off+2, 2)), '>', 65000, 'Date near max');
}

{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Date32']]);
    my $bin = $enc->encode([['1900-01-01'], ['2299-12-31']]);
    my $off = skip_header($bin);
    cmp_ok(unpack('l<', substr($bin, $off,   4)), '<',     0, 'Date32 1900 negative');
    cmp_ok(unpack('l<', substr($bin, $off+4, 4)), '>', 50000, 'Date32 2299 large');
}

# ---- varint width transitions -----------------------------------------------
# String length encoded as varint: 1 byte for [0..127], 2 for [128..16383], etc.
# Verify the encoder picks the right number of length bytes at each boundary.

for my $boundary (127, 128, 16383, 16384, 2097151, 2097152) {
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'String']]);
    my $s = 'x' x $boundary;
    my $bin = $enc->encode([[$s]]);

    # Walk the header by hand so we know exactly where the string starts.
    my (undef, $off)        = read_varint($bin, 0);  # ncols
    (undef, $off)           = read_varint($bin, $off);  # nrows
    my ($nlen, $off2)       = read_varint($bin, $off);   # col name len
    $off2 += $nlen;
    my ($tlen, $off3)       = read_varint($bin, $off2);  # col type len
    $off3 += $tlen;
    my ($slen, $off4)       = read_varint($bin, $off3);  # value len
    is($slen, $boundary, "String len varint roundtrips at $boundary");
    is(length($bin) - $off4, $boundary, "Body bytes match at $boundary");
}

# ---- Decimal128 near maximum -----------------------------------------------

{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal128(0)']]);
    # 2^127 - 1 = 170141183460469231731687303715884105727 (39 digits)
    my $bin = $enc->encode([['170141183460469231731687303715884105727']]);
    my $off = skip_header($bin);
    my $lo  = unpack('Q<', substr($bin, $off,   8));
    my $hi  = unpack('q<', substr($bin, $off+8, 8));
    is($lo, 0xFFFFFFFFFFFFFFFF,  'Decimal128 max lo = all ones');
    is($hi, 0x7FFFFFFFFFFFFFFF, 'Decimal128 max hi = INT64_MAX');
}
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal128(0)']]);
    # -(2^127) = -170141183460469231731687303715884105728
    my $bin = $enc->encode([['-170141183460469231731687303715884105728']]);
    my $off = skip_header($bin);
    my $lo = unpack('Q<', substr($bin, $off,   8));
    my $hi = unpack('q<', substr($bin, $off+8, 8));
    is($lo, 0,                              'Decimal128 min lo = 0');
    is($hi, unpack('q<', "\0\0\0\0\0\0\0\x80"), 'Decimal128 min hi = INT64_MIN bits');
}

# ---- Float32 subnormal ------------------------------------------------------

{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Float32']]);
    my $tiny = 1.4e-45;  # smallest positive subnormal in Float32
    my $bin = $enc->encode([[$tiny], [0], [-0.0]]);
    my $off = skip_header($bin);
    my $tiny_bytes = unpack('H8', substr($bin, $off, 4));
    is($tiny_bytes, '01000000', 'Float32 smallest subnormal -> 0x00000001 LE');
    is(unpack('H8', substr($bin, $off+4, 4)), '00000000', 'Float32 +0.0 -> 0x00000000');
    is(unpack('H8', substr($bin, $off+8, 4)), '00000080', 'Float32 -0.0 -> 0x80000000');
}

# ---- empty edge cases -------------------------------------------------------

{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Array(Array(Int32))']]);
    my $bin = $enc->encode([[[]], [[[]]], [[]]]);
    ok(defined $bin && length($bin) > 0, 'mixed empty / nested-empty arrays');
}

{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'String']]);
    my $bin = $enc->encode([['']]);  # length 0
    my $off = skip_header($bin);
    is(ord(substr($bin, $off, 1)), 0, 'Empty string -> single 0 byte');
    is(length($bin) - $off, 1,        'No body for empty string');
}

# ---- FixedString with embedded nulls (binary blob) --------------------------

{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'FixedString(8)']]);
    my $bytes = "\x00\x01\x02\x03\xFF\xFE\xFD\xFC";
    my $bin = $enc->encode([[$bytes]]);
    my $off = skip_header($bin);
    is(substr($bin, $off, 8), $bytes, 'FixedString preserves embedded NULs');
}

done_testing();
