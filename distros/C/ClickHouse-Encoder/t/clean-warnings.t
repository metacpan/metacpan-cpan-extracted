#!/usr/bin/env perl
# Encode every supported type with the typical inputs (and a few edge
# inputs) under FATAL warnings; if any path emits a Perl warning, the
# test dies with the offending message attached. Catches uninitialized,
# numeric, pack, portable, and all other warning categories that the
# encoder might trigger via SvIV/SvUV/SvNV/SvPV on tricky inputs.
use strict;
use warnings FATAL => 'all';
use lib 'blib/lib', 'blib/arch';
use Test::More;
use ClickHouse::Encoder;

# Each entry: [type, sample row, label]. Inputs include valid values,
# undef in Nullable wrappers, and strings where the encoder accepts them.
my @cases = (
    ['Int8',    [-1],            'Int8 negative'],
    ['Int16',   [12345],         'Int16'],
    ['Int32',   [-2_000_000_000],'Int32 negative'],
    ['Int64',   ['-9000000000'], 'Int64 string'],
    ['UInt8',   [255],           'UInt8 max'],
    ['UInt16',  [65535],         'UInt16 max'],
    ['UInt32',  [4_294_967_295], 'UInt32 max'],
    ['UInt64',  ['18446744073709551615'], 'UInt64 string max'],
    ['Float32', [3.14],          'Float32'],
    ['Float64', [3.14e100],      'Float64'],
    ['BFloat16',[1.0],           'BFloat16'],
    ['String',  [''],            'String empty'],
    ['String',  ["\xff\x00\xee"],'String binary'],
    ['FixedString(8)', ['abcd'], 'FixedString short input (zero pad)'],
    ['Date',    ['2024-06-15'],  'Date YMD'],
    ['Date32',  [-1000],         'Date32 negative'],
    ['DateTime',     ['2024-06-15 12:30:45'], 'DateTime YMD HMS'],
    ['DateTime64(3)',[42.5],     'DateTime64 float'],
    ['Decimal32(2)', ['1.5'],    'Decimal32 string'],
    ['Decimal64(4)', [12.3456],  'Decimal64 numeric'],
    ['Decimal128(5)',['12345.67890'], 'Decimal128 string'],
    ['Decimal256(2)',['99999999999999999999.99'], 'Decimal256 string'],
    ["Enum8('a' = 1, 'b' = 2)", ['a'],     'Enum8 by name'],
    ["Enum16('x' = 100, 'y' = 200)", [100], 'Enum16 by integer'],
    ['Bool',    [1],             'Bool truthy'],
    ['UUID',    ['11112222-3333-4444-5555-666677778888'], 'UUID string'],
    ['IPv4',    ['127.0.0.1'],   'IPv4 dotted'],
    ['IPv6',    ['::1'],         'IPv6 loopback'],
    ['Map(String, UInt32)', [{a=>1,b=>2}], 'Map'],
    ['Array(Int32)',         [[1,2,3]],   'Array(Int32)'],
    ['Array(Nullable(Int32))', [[1,undef,3]], 'Array(Nullable)'],
    ['Tuple(Int32, String)',   [[1,'x']], 'Tuple positional'],
    ['Tuple(a Int32, b String)',[{a=>1, b=>'x'}], 'Tuple hashref'],
    ['Nullable(Int32)',        [undef], 'Nullable undef'],
    ['LowCardinality(String)', ['repeated'], 'LowCardinality(String)'],
    ['LowCardinality(String)', [undef],      'LowCardinality(String) undef'],
    ['LowCardinality(Nullable(String))', [undef], 'LC(Nullable) null'],
    ['Variant(String, UInt32)',  [[0, 'hi']], 'Variant String arm'],
    ['Variant(String, UInt32)',  [undef],     'Variant null'],
    ['Point',   [[1.5, 2.5]],    'Geo Point'],
);

for my $c (@cases) {
    my ($type, $row, $label) = @$c;
    my @warned;
    local $SIG{__WARN__} = sub { push @warned, @_ };
    my $bin = eval {
        my $enc = ClickHouse::Encoder->new(columns => [['v', $type]]);
        $enc->encode([$row]);
    };
    if ($@) {
        fail("$label encode died: $@");
        next;
    }
    if (@warned) {
        fail("$label emitted warnings: @warned");
        next;
    }
    ok(defined $bin && length $bin > 0, "$label: clean encode");
}

done_testing();
