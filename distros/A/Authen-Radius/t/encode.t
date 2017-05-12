use strict;
use warnings;
use Test::More tests => 23;
use Test::NoWarnings;
use Config;

BEGIN { use_ok('Authen::Radius') };

use constant NoVendor => 'not defined';
use constant VendorCisco => 9;

ok( Authen::Radius->load_dictionary('raddb/dictionary'), 'load dictionary');

is( Authen::Radius->_encode_value(NoVendor, 30, 'string', 'Called-Station-Id', '163512412'), '163512412', 'string - as-is');
is( Authen::Radius->_encode_value(NoVendor, 27, 'integer', 'Session-Timeout', 300), "\x00\x00\x01\x2c", 'integer');
is( Authen::Radius->_encode_value(NoVendor, 4, 'ipaddr', 'NAS-IP-Address', "10.20.30.40"), "\x0a\x14\x1e\x28", 'IPv4');
is( Authen::Radius->_encode_value(NoVendor, 95, 'ipv6addr', 'NAS-IPv6-Address', "fe80::5cee:a6ff:fe1c:f204"),
    "\xfe\x80\x00\x00\x00\x00\x00\x00\x5c\xee\xa6\xff\xfe\x1c\xf2\x04", 'IPv6');

is( Authen::Radius->_encode_value(NoVendor, 97, 'ipv6prefix', 'Framed-IPv6-Prefix', "2001:db8:3c4d::/48"),
    "\x00\x30\x20\x01\x0d\xb8\x3c\x4d\x00\x00\x00\x00\x00\x00\x00\x00\x00\x00", 'IPv6 prefix');

is( Authen::Radius->_encode_value(NoVendor, 96, 'ifid', 'Framed-Interface-Id', "1111:2211:3311:4411"),
    "\x11\x11\x22\x11\x33\x11\x44\x11", 'ifid');

is( Authen::Radius->_encode_value(VendorCisco, 1, 'avpair', 'session-protocol', "SIP"), 'session-protocol=SIP', 'avpair');

is( Authen::Radius->_encode_value(NoVendor, 207, 'sublist', 'Digest-Attributes', {Method => 'REGISTER'}), "\x03\x0AREGISTER", 'sublist');

is( Authen::Radius->_encode_value(NoVendor, -1, 'octets', 'NNN-Octets', "0x3cc93c4aa70d4a"), '0x3cc93c4aa70d4a', 'octets');

is( Authen::Radius->_encode_value(NoVendor, -1, 'byte', 'NNN-Byte', 10), "\x0a", 'byte');
is( Authen::Radius->_encode_value(NoVendor, -1, 'short', 'NNN-Short', 10), "\x00\x0a", 'short');
is( Authen::Radius->_encode_value(NoVendor, -1, 'signed', 'NNN-Signed', -10), "\xff\xff\xff\xf6", 'signed');
is( Authen::Radius->_encode_value(NoVendor, -1, 'signed', 'NNN-Signed', 535), "\x00\x00\x02\x17", 'signed');

is( Authen::Radius->_encode_value(NoVendor, -1, 'combo-ip', 'NNN-Combo', '10.20.30.40'), "\x0a\x14\x1e\x28", 'combo-ip v4');
is( Authen::Radius->_encode_value(NoVendor, -1, 'combo-ip', 'NNN-Combo', 'fe80::16da:e9ff:feef:ae06'), undef , 'combo-ip v6 not supported');

is( Authen::Radius->_encode_value(NoVendor, 1, 'tlv', 'WiMAX-Capability', [
      {Name => 'WiMAX-Release', Value => '5.0', TLV_ID => 1},
      {Name => 'WiMAX-Hotlining-Capabilities', Value => 'IP-Redirection', TLV_ID => 3 },
    ]), "\x01\x05\x35\x2E\x30\x03\x03\x08" , 'TLV');

is( Authen::Radius->_encode_value(NoVendor, -1, 'none', 'NNN-Byte', 10), undef, 'unknown type');

SKIP: {
    skip 'No 64bit int support', 1 if (! $Config{use64bitint});
    is( Authen::Radius->_encode_value(NoVendor, -1, 'integer64', 'NNN-Int64', 12345), "\x00\x00\x00\x00\x00\x00\x30\x39", 'integer64');
};

is( Authen::Radius->_encode_value(NoVendor, -1, 'date', 'NNN-Date', 1479994575), "\x58\x36\xec\xcf", 'date (the same as integer)');
is( Authen::Radius->_encode_value(NoVendor, -1, 'time', 'NNN-Time', 1479994576), "\x58\x36\xec\xd0", 'time (the same as integer)');
