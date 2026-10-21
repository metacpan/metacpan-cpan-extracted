use strict;
use warnings;
use Test::More;
use lib 'blib/lib', 'blib/arch';
use ClickHouse::Encoder;

# Out-of-range values for narrow integer columns and integer-form
# IPv4 croak instead of silently truncating/wrapping into
# valid-looking wire bytes (Int8(300) used to encode 44).

sub encodes_ok {
    my ($type, $in) = @_;
    my $enc = ClickHouse::Encoder->new(columns => [['v', $type]]);
    my $bin = eval { $enc->encode([[$in]]) };
    return ($bin, $@);
}

# [type, min, max]
my @types = (
    ['Int8',   -128,        127],
    ['Int16',  -32768,      32767],
    ['Int32',  -2147483648, 2147483647],
    ['UInt8',  0,           255],
    ['UInt16', 0,           65535],
    ['UInt32', 0,           4294967295],
);

for my $t (@types) {
    my ($type, $min, $max) = @$t;
    my ($bin, $err) = encodes_ok($type, $min);
    ok(!$err && defined $bin, "$type min ($min) encodes");
    ($bin, $err) = encodes_ok($type, $max);
    ok(!$err && defined $bin, "$type max ($max) encodes");
    ($bin, $err) = encodes_ok($type, $min - 1);
    like($err, qr/\Q$type\E out of range/, "$type min-1 croaks");
    ($bin, $err) = encodes_ok($type, $max + 1);
    like($err, qr/\Q$type\E out of range/, "$type max+1 croaks");
}

# The original silent-wrap probes, incl. UV/NV/string scalar forms.
{
    my $uv300 = unpack 'L', pack 'L', 300;   # force SvIsUV
    ok($uv300 == 300, 'precondition: forced-UV scalar holds 300');
    my (undef, $err) = encodes_ok('UInt8', $uv300);
    like($err, qr/UInt8 out of range/, 'UInt8 UV 300 croaks');
    my $uv200 = unpack 'L', pack 'L', 200;
    my ($bin) = encodes_ok('UInt8', $uv200);
    ok(defined $bin, 'UInt8 UV 200 encodes');
    my $huge_uv = 0 + '18446744073709551615';    # UV_MAX
    (undef, $err) = encodes_ok('UInt32', $huge_uv);
    like($err, qr/UInt32 out of range/, 'UInt32 UV_MAX croaks');
}
{
    my (undef, $err) = encodes_ok('Int8', 300.9);
    like($err, qr/Int8 out of range/, 'Int8 NV 300.9 croaks');
    (undef, $err) = encodes_ok('UInt8', -1.5);
    like($err, qr/UInt8 out of range/, 'UInt8 NV -1.5 croaks');
    (undef, $err) = encodes_ok('UInt8', '-0.5');
    like($err, qr/UInt8 out of range/, 'UInt8 negative fraction string croaks');
    (undef, $err) = encodes_ok('Int8', '-128.5');
    like($err, qr/Int8 out of range/, 'Int8 fraction below minimum croaks');
    my ($bin) = encodes_ok('UInt8', 200.9);
    my $v = ClickHouse::Encoder->decode_block($bin)->{columns}[0]{values}[0];
    is($v, 200, 'UInt8 NV 200.9 still truncates the fraction');
}
{
    my (undef, $err) = encodes_ok('Int8', '300');
    like($err, qr/Int8 out of range/, "Int8 '300' croaks");
    (undef, $err) = encodes_ok('UInt8', '-1');
    like($err, qr/UInt8 out of range/, "UInt8 '-1' croaks");
    my ($bin) = encodes_ok('UInt32', '4294967295');
    ok(defined $bin, "UInt32 '4294967295' encodes");
}

# Integer-form IPv4 shares the UInt32 domain; dotted strings unaffected.
{
    my ($bin, $err) = encodes_ok('IPv4', -1);
    like($err, qr/IPv4 integer out of range/, 'IPv4(-1) croaks');
    (undef, $err) = encodes_ok('IPv4', 4294967296);
    like($err, qr/IPv4 integer out of range/, 'IPv4(2**32) croaks');
    (undef, $err) = encodes_ok('IPv4', '-1');
    like($err, qr/IPv4 integer out of range/, "IPv4('-1') croaks");
    ($bin, $err) = encodes_ok('IPv4', 0);
    ok(!$err, 'IPv4(0) encodes');
    ($bin, $err) = encodes_ok('IPv4', 4294967295);
    ok(!$err, 'IPv4(2**32-1) encodes');
    ($bin, $err) = encodes_ok('IPv4', '1.2.3.4');
    ok(!$err, 'IPv4 dotted string encodes');
    my $v = ClickHouse::Encoder->decode_block($bin)->{columns}[0]{values}[0];
    is($v, '1.2.3.4', 'IPv4 dotted string round-trips');
}

# Full-width boundaries retain their exact integer values.
{
    my ($bin, $err) = encodes_ok('Int64', '-9223372036854775808');
    ok(!$err, 'Int64 MIN encodes');
    ($bin, $err) = encodes_ok('UInt64', 0 + '18446744073709551615');
    ok(!$err, 'UInt64 MAX encodes');
    for my $case (
        ['Int64', '9223372036854775807'],
        ['Int64', '-9223372036854775808'],
        ['UInt64', '18446744073709551615'],
        ['Int64', '1e3'],
    ) {
        my ($type, $input) = @$case;
        ($bin, $err) = encodes_ok($type, $input);
        is($err, '', "$type $input encodes");
        my $got = ClickHouse::Encoder->decode_block($bin)->{columns}[0]{values}[0];
        is("$got", $input eq '1e3' ? '1000' : $input, 'exact boundary round trip');
    }
    for my $case (
        ['Int64', '9223372036854775808'],
        ['Int64', '-9223372036854775809'],
        ['Int64', '1e+30'],
        ['Int64', 2 ** 63],
        ['UInt64', '-1'],
        ['UInt64', -1],
        ['UInt64', '18446744073709551616'],
        ['UInt64', 2 ** 64],
    ) {
        my ($type, $input) = @$case;
        (undef, $err) = encodes_ok($type, $input);
        like($err, qr/\Q$type\E out of range/, "$type $input is rejected");
    }
}

done_testing();
