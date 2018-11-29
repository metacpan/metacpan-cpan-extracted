use strict;
use warnings;
use Test::More;
use Config;

BEGIN { use_ok('Authen::Radius') };

use constant NoVendor => 'not defined';
use constant VendorCisco => 9;

ok( Authen::Radius->load_dictionary('raddb/dictionary'), 'load dictionary');

is( Authen::Radius->_decode_value(NoVendor, 30, 'string', 'Called-Station-Id', '163512412'), '163512412', 'string - as-is');
is( Authen::Radius->_decode_value(NoVendor, 27, 'integer', 'Session-Timeout', "\x00\x00\x01\x2c"), 300, 'integer');
is( Authen::Radius->_decode_value(NoVendor, 4, 'ipaddr', 'NAS-IP-Address', "\x0a\x14\x1e\x28"), "10.20.30.40", 'IPv4');
is( Authen::Radius->_decode_value(NoVendor, 95, 'ipv6addr', 'NAS-IPv6-Address',
    "\xfe\x80\x00\x00\x00\x00\x00\x00\x5c\xee\xa6\xff\xfe\x1c\xf2\x04"), "fe80::5cee:a6ff:fe1c:f204", 'IPv6');

is( Authen::Radius->_decode_value(NoVendor, 97, 'ipv6prefix', 'Framed-IPv6-Prefix',
    "\x00\x30\x20\x01\x0d\xb8\x3c\x4d\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00"), "2001:db8:3c4d::/48", 'IPv6 prefix');

is( Authen::Radius->_decode_value(NoVendor, 96, 'ifid', 'Framed-Interface-Id', "\x11\x11\x22\x11\x33\x11\x44\x11"),
    "1111:2211:3311:4411", 'ifid');

is( Authen::Radius->_decode_value(VendorCisco, 1, 'avpair', 'session-protocol', "session-protocol=SIP"), 'SIP', 'avpair');

is_deeply( scalar Authen::Radius->_decode_value(NoVendor, 207, 'sublist', 'Digest-Attributes', "\x03\x0AREGISTER"), 'Method = "REGISTER"', 'sublist');

# not supported:

#is( Authen::Radius->_decode_value(NoVendor, 'NNN-Octets', 'octets', 'NNN-Octets', "0x3cc93c4aa70d4a"), '0x3cc93c4aa70d4a', 'octets');

# is( Authen::Radius->_decode_value(NoVendor, 'NNN-Byte', 'byte', 'NNN-Byte', "\x0a"), 10, 'byte');
# is( Authen::Radius->_decode_value(NoVendor, 'NNN-Short', 'short', 'NNN-Short', "\x00\x0a"), 10, 'short');
# is( Authen::Radius->_decode_value(NoVendor, 'NNN-Signed', 'signed', 'NNN-Signed', "\xff\xff\xff\xf6"), -10, 'signed');
# is( Authen::Radius->_decode_value(NoVendor, 'NNN-Signed', 'signed', 'NNN-Signed', "\x00\x00\x02\x17"), 535, 'signed');

# is( Authen::Radius->_decode_value(NoVendor, 'NNN-Combo', 'combo-ip', 'NNN-Combo', "\x0a\x14\x1e\x28"), '10.20.30.40', 'combo-ip v4');
# is( Authen::Radius->_decode_value(NoVendor, 'NNN-Combo', 'combo-ip', 'NNN-Combo', 'fe80::16da:e9ff:feef:ae06'), undef , 'combo-ip v6 not supported');

# is( Authen::Radius->_decode_value(NoVendor, 'WiMAX-Capability', 'tlv', 'WiMAX-Capability', [
#       {Name => 'WiMAX-Release', Value => '5.0'},
#       {Name => 'WiMAX-Hotlining-Capabilities', Value => 'IP-Redirection' },
#     ]), "\x01\x05\x35\x2E\x30\x03\x03\x08" , 'TLV');

is( Authen::Radius->_decode_value(NoVendor, -1, 'none', 'NNN-Byte', 10), undef, 'unknown type');

SKIP: {
    skip 'No 64bit int support', 1 if (! $Config{use64bitint});
    is( Authen::Radius->_decode_value(NoVendor, -1, 'integer64', 'NNN-Int64', "\x00\x00\x00\x00\x00\x00\x30\x39"), 12345, 'integer64');
};

is( Authen::Radius->_decode_value(NoVendor, -1, 'date', 'NNN-Date', "\x58\x36\xec\xcf"), 1479994575, 'date (the same as integer)');
is( Authen::Radius->_decode_value(NoVendor, -1, 'time', 'NNN-Time', "\x58\x36\xec\xd0"), 1479994576, 'time (the same as integer)');

done_testing();
