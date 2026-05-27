#!/usr/bin/env perl
# Drive every user-visible croak path. Doubles as living documentation
# of the contract: each test names the bad input and the expected
# substring of the error message. If a future refactor changes the
# wording in a way that breaks a downstream consumer's regex, this file
# tells you which messages they may have been matching.
use strict;
use warnings;
use lib 'blib/lib', 'blib/arch';
use Test::More;
use ClickHouse::Encoder;

sub croak_like {
    my ($code, $rx, $name) = @_;
    eval { $code->(); 1 };
    like($@, $rx, $name);
}

# new() / type-parser errors --------------------------------------------------

croak_like(sub { ClickHouse::Encoder->new() },
           qr/columns required.*arrayref/, 'no columns arg');

croak_like(sub { ClickHouse::Encoder->new(columns => "no") },
           qr/columns required.*arrayref/, 'columns not an arrayref');

croak_like(sub { ClickHouse::Encoder->new(columns => [['just-a-name']]) },
           qr/Column must be \[name, type\]/, 'column without type');

croak_like(sub { ClickHouse::Encoder->new(columns => [['v', 'NoSuchType']]) },
           qr/[Uu]nknown type/, 'unknown type');

croak_like(sub { ClickHouse::Encoder->new(columns => [['v', 'FixedString(0)']]) },
           qr/FixedString.*positive/, 'FixedString(0)');

croak_like(sub { ClickHouse::Encoder->new(columns => [['v', 'Nullable(Nullable(Int32))']]) },
           qr/Nullable\(Nullable/, 'Nullable(Nullable())');

croak_like(sub { ClickHouse::Encoder->new(columns => [['v', 'DateTime64(10)']]) },
           qr/DateTime64 precision must be 0\.\.9/, 'DateTime64 over precision');

croak_like(sub { ClickHouse::Encoder->new(columns => [['v', 'Decimal32(10)']]) },
           qr/Decimal32 scale must be 0\.\.9/, 'Decimal32 scale > 9');

croak_like(sub { ClickHouse::Encoder->new(columns => [['v', 'Decimal(0, 0)']]) },
           qr/precision must be 1\.\.38/, 'Decimal(P,S) P=0');

croak_like(sub { ClickHouse::Encoder->new(columns => [['v', 'Variant()']]) },
           qr/Variant requires at least one type/, 'Variant() empty');

croak_like(sub { ClickHouse::Encoder->new(columns => [['v', 'Nested(a Int32)']]) },
           qr/Nested.*flat/, 'Nested explicit rejection');

# encode() errors -------------------------------------------------------------

{
    my $enc = ClickHouse::Encoder->new(columns => [['a', 'Int32'], ['b', 'String']]);

    croak_like(sub { $enc->encode("not a ref") },
               qr/arrayref|rows.*arrayref/i, 'rows not a ref');

    croak_like(sub { $enc->encode([['x']]) },
               qr/columns?|values?|2/i, 'wrong row arity');

    croak_like(sub { $enc->encode([[1, 'ok'], 'not-a-row']) },
               qr/arrayref/, 'a row that is not an arrayref');
}

# Variant index out of range
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Variant(String, UInt32)']]);
    croak_like(sub { $enc->encode([[[5, 'x']]]) },
               qr/Variant.*out of range/i, 'Variant idx out of range');
    croak_like(sub { $enc->encode([['plain-string']]) },
               qr/Variant.*\[/, 'Variant value not [idx, value] tuple');
}

# Decimal overflow on string path
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal32(0)']]);
    croak_like(sub { $enc->encode([['9999999999']]) },
               qr/Decimal32 overflow/, 'Decimal32 string overflow');
}

# Enum unknown name
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', q{Enum8('a' = 1, 'b' = 2)}]]);
    croak_like(sub { $enc->encode([['c']]) },
               qr/Enum.*unknown name|Enum.*not found|Unknown enum/, 'Enum unknown name');
}

# Enum8 integer value out of range (-128..127)
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', q{Enum8('a' = 1)}]]);
    croak_like(sub { $enc->encode([[200]]) },
               qr/Enum8 value 200 out of range/, 'Enum8 +200 out of range');
    croak_like(sub { $enc->encode([[-200]]) },
               qr/Enum8 value -200 out of range/, 'Enum8 -200 out of range');
}

# Enum16 integer value out of range (-32768..32767)
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', q{Enum16('a' = 1)}]]);
    croak_like(sub { $enc->encode([[40000]]) },
               qr/Enum16 value 40000 out of range/, 'Enum16 40000 out of range');
}

# DateTime out of UInt32 range (pre-1970 or post-2106)
{
    my $enc = ClickHouse::Encoder->new(columns => [['t', 'DateTime']]);
    croak_like(sub { $enc->encode([['1969-12-31 23:59:59']]) },
               qr/DateTime out of UInt32 range/, 'pre-1970 DateTime rejected');
    croak_like(sub { $enc->encode([['2200-01-01 00:00:00']]) },
               qr/DateTime out of UInt32 range/, 'post-2106 DateTime rejected');
}

# BulkInserter rejects invalid compress mode at construction time,
# not deferred to the first flush.
{
    require ClickHouse::Encoder;
    croak_like(sub {
        ClickHouse::Encoder->bulk_inserter(
            table => 't', columns => [['x','Int32']], compress => 'lz4');
    }, qr/unknown compress='lz4'/,
       'bulk_inserter rejects unknown compress at construction');
}

# encode_columns errors
{
    my $enc = ClickHouse::Encoder->new(columns => [['a', 'Int32'], ['b', 'String']]);

    croak_like(sub { $enc->encode_columns("nope") },
               qr/hashref/, 'encode_columns wants hashref');

    croak_like(sub { $enc->encode_columns({a => [1, 2]}) },
               qr/missing column 'b'/, 'encode_columns missing column');

    croak_like(sub { $enc->encode_columns({a => [1, 2], b => ['x']}) },
               qr/has 1 rows.*expected 2|has 2 rows.*expected 1/,
               'encode_columns ragged arrays');

    croak_like(sub { $enc->encode_columns({a => 'no', b => ['x']}) },
               qr/must be an arrayref/, "encode_columns col not arrayref");
}

# encode_into expects scalar ref
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Int32']]);
    my $not_a_ref = "x";
    croak_like(sub { $enc->encode_into($not_a_ref, [[1]]) },
               qr/scalar reference/, 'encode_into needs scalar ref');
}

# encode_to_handle on a read-only filehandle must report "not open for
# writing", not a downstream "short write: ..." error.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'UInt32']]);
    open my $rfh, '<', $0 or die "open self: $!";
    croak_like(sub { $enc->encode_to_handle($rfh, [[1]]) },
               qr/not open for writing/,
               'encode_to_handle: read-only filehandle');
    close $rfh;
}

# DateTime string with non-digit time fields must croak, not silently
# arithmetic-mangle the bytes.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'DateTime']]);
    croak_like(sub { $enc->encode([['2024-06-15 AB:CD:EF']]) },
               qr/Invalid datetime string/, 'DateTime: non-digit time fields');
    croak_like(sub { $enc->encode([['2024-06-15 12:34:5x']]) },
               qr/Invalid datetime string/, 'DateTime: non-digit second');

    my $enc64 = ClickHouse::Encoder->new(columns => [['v', 'DateTime64(3)']]);
    croak_like(sub { $enc64->encode([['2024-06-15 9X:34:56.000']]) },
               qr/Invalid datetime string/, 'DateTime64: non-digit hour');

    # Inf / NaN passed as numeric float must croak, not silently produce
    # a garbage int64 via implementation-defined llround() out-of-range
    # behavior.
    croak_like(sub { $enc64->encode([['Inf' + 0]]) },
               qr/DateTime64 overflow/, 'DateTime64: Inf croaks');
    croak_like(sub { $enc64->encode([['NaN' + 0]]) },
               qr/DateTime64 overflow/, 'DateTime64: NaN croaks');
}

# Decimal256 float-path overflow at the 2^255 boundary: values in
# [2^255, 2^256) used to silently produce a buffer with the sign bit
# set, which CH would interpret as a large negative Int256.
{
    my $enc = ClickHouse::Encoder->new(columns => [['v', 'Decimal256(0)']]);
    croak_like(sub { $enc->encode([[1e77]]) },
               qr/Decimal256 overflow/, 'Decimal256 (float path) > 2^255 croaks');
    croak_like(sub { $enc->encode([[1e80]]) },
               qr/Decimal256 overflow/, 'Decimal256 (float path) > 2^256 croaks');
}

# Short-buffer truncation contract for public XS buffer+offset methods.
# read_packet's retry loop depends on /truncated/ matching to know when
# to read more bytes; a regression that silently consumes a short buffer
# would break TCP frame reassembly. Lock the contract in tests.
{
    croak_like(sub { ClickHouse::Encoder->decode_block("\x80") },
               qr/truncated/,
               'decode_block: dangling varint byte croaks /truncated/');
    croak_like(sub { ClickHouse::Encoder->decode_rows("\x80") },
               qr/truncated/,
               'decode_rows: dangling varint byte croaks /truncated/');
    require ClickHouse::Encoder::TCP;
    croak_like(sub { ClickHouse::Encoder::TCP::unpack_varint("\x80", 0) },
               qr/truncated/,
               'unpack_varint: continuation byte without successor');
    croak_like(sub { ClickHouse::Encoder::TCP::unpack_string("\x05abc", 0) },
               qr/truncated/,
               'unpack_string: body shorter than declared length');
}

done_testing();
