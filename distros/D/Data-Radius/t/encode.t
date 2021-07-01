use strict;
use warnings;
use Test::More tests => 42;

BEGIN { use_ok('Data::Radius::Encode', qw(encode)) };
BEGIN { use_ok('Data::Radius::Dictionary') };

my $dict = Data::Radius::Dictionary->load_file('./radius/dictionary');
ok($dict, 'dictionary loaded');

my $warns = 0;
$SIG{__WARN__} = sub { $warns++, note(@_) };

is(encode({type => 'integer'}, 535), "\x00\x00\x02\x17", 'int');
is(encode({type => 'integer', name => 'TestAttr'}, -1), undef, 'integer - out of range');
is(encode({type => 'integer', name => 'TestAttr'}, 4294967300), undef, 'integer - out of range');
is(encode({type => 'integer', name => 'TestAttr'}, "INT"), undef, 'not a number');
is(encode({type => 'integer', name => 'TestAttr'}, undef), undef, 'undefined value');
is(encode({type => 'string'}, 'test it'), 'test it', 'string');
is(encode({type => 'string', name => 'User-Name'}, 'x' x 300), undef, 'very long string is not encoded');
is(encode({type => 'string', name => 'User-Name'}, 'x' x 253), 'x' x 253, 'max string size');
is(encode({type => 'string', name => 'call-id', vendor => 'Cisco'}, 'x' x 253), undef, 'VSA max string size');
is(encode({type => 'string', name => 'call-id', vendor => 'Cisco'}, 'x' x 247), 'x' x 247, 'VSA max string size');
is(encode({type => 'byte'}, 10), "\x0a", 'byte');
is(encode({type => 'byte', name => 'TestAttr'}, -1), undef, 'byte - out of range');
is(encode({type => 'byte', name => 'TestAttr'}, 300), undef, 'byte - out of range');
is(encode({type => 'short'}, 10), "\x00\x0a", 'short');
is(encode({type => 'short', name => 'TestAttr'}, -1), undef, 'short - out of range');
is(encode({type => 'short', name => 'TestAttr'}, 65700), undef, 'short - out of range');
is(encode({type => 'signed'}, -10), "\xff\xff\xff\xf6", 'signed');
is(encode({type => 'signed'}, 535), "\x00\x00\x02\x17", 'signed');
is(encode({type => 'signed', name => 'TestAttr'}, -4294967297), undef, 'signed - out of range');
is(encode({type => 'signed', name => 'TestAttr'}, 4294967297), undef, 'signed - out of range');
is(encode({type => 'ipaddr'}, '10.20.30.40'), "\x0a\x14\x1e\x28", "IPv4");
is(encode({type => 'ipaddr'}, '300.20.30.40'), undef, "invalid IPv4");
is(encode({type => 'ipv6addr'}, 'fe80::5cee:a6ff:fe1c:f204'), "\xfe\x80\x00\x00\x00\x00\x00\x00\x5c\xee\xa6\xff\xfe\x1c\xf2\x04", 'IPv6');
is(encode({type => 'ipv6addr'}, 'zze80::5cee:a6ff:fe1c:f204'), undef, 'invalid IPv6');
is(encode({type => 'octets'}, "0x3cc93c4aa70d4a"), "\x3c\xc9\x3c\x4a\xa7\x0d\x4a", 'octects');
is(encode({type => 'octets', name => 'TestAttr'}, "0xCisco"), undef, 'invalid octets string');
is(encode({type => 'combo-ip'}, '10.20.30.40'), "\x0a\x14\x1e\x28", 'combo-ip IPv4');
is(encode({type => 'combo-ip'}, 'fe80::16da:e9ff:feef:ae06'), "\xfe\x80\x00\x00\x00\x00\x00\x00\x16\xda\xe9\xff\xfe\xef\xae\x06", 'combo-ip IPv6');
my $attr = $dict->attribute('session-protocol');
is($attr->{id}, 1, 'VSA Cisco-AVPair');
is($attr->{vendor}, 'Cisco', 'Vendor');
is(encode($attr, 'SIP', $dict), "session-protocol=SIP", "avpair with VSA 1");
is(encode($attr, 'x' x (247 - length('session-protocol=') + 1), $dict), undef, "too long value for avpair VSA");
$attr = $dict->attribute('h323-currency');
is($attr->{id}, 110, 'VSA h323-currency');
is($attr->{vendor}, 'Cisco', 'Vendor');
is(encode($attr, 'USD', $dict), "USD", "avpair with own VSA");
is(encode($attr, 'x' x 248, $dict), undef, "too long value for avpair VSA");

my $v = encode({type => 'tlv', name => 'WiMAX-Capability'}, [{Name => 'WiMAX-Release', Value => '5.0'}], $dict);
is($v, "\x01\x05\x35\x2E\x30", "TLV with 1 sub-attribute");

$v = encode({type => 'tlv', name => 'WiMAX-Capability'},
    [{Name => 'WiMAX-Release', Value => '5.0'},
     {Name => 'WiMAX-Hotlining-Capabilities', Value => 'IP-Redirection' },
    ], $dict);
is($v, "\x01\x05\x35\x2E\x30\x03\x03\x08", "TLV with 2 sub-attributes");

is($warns, 15, 'num of warnings');
