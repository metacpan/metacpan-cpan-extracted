use strict;
use warnings;
use Data::HexDump;
use Test::More tests => 19;

BEGIN {
    use_ok('Data::Radius::Dictionary');
    use_ok('Data::Radius::Constants', qw(:all));
    use_ok('Data::Radius::Packet');
};

my $dict = Data::Radius::Dictionary->load_file('./radius/dictionary');
ok($dict, 'dictionary loaded');

my $p = Data::Radius::Packet->new(secret => 'top-secret', dict => $dict);
ok($p, 'object');

# cannot use random-generated during tests
my $authenticator = pack('L<4', 561138743, 3194401087, 2213483623, 4032919672);

my($auth_req, $req_id, $auth) = $p->build(
    type => ACCESS_REQUEST,
    av_list => [
        { Name => 'User-Name', Value => 'JonSnow'},
        { Name => 'User-Password', Value => 'Castle Black' },
    ],
    authenticator => $authenticator,
    request_id => 12,
    with_msg_auth => 1,
);

#print HexDump($auth_req);
is(HexDump($auth_req), <<DUMP, 'binary dump');
          00 01 02 03 04 05 06 07 - 08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF

00000000  01 0C 00 41 37 4C 72 21 - 3F B1 66 BE 67 14 EF 83  ...A7Lr!?.f.g...
00000010  78 78 61 F0 01 09 4A 6F - 6E 53 6E 6F 77 02 12 86  xxa...JonSnow...
00000020  9D 1B 53 20 E1 CB BC 4F - AF 68 8D F2 A7 B2 11 50  ..S ...O.h.....P
00000030  12 22 01 2B 19 E9 A1 4A - 95 87 E5 D9 6A DE 38 FF  .".+...J....j.8.
00000040  5E                                                 ^
DUMP


ok($auth_req, 'packet built');
is($req_id, 12, 'request id');
is($auth, $authenticator, 'authenticator used');

my ($t, $id, $auth_p, $av) = $p->parse($auth_req, $authenticator);
is($t, ACCESS_REQUEST, 'packet type');
is($id, $req_id, 'request id');
is($auth_p, $auth, 'authenticator used');
is_deeply($av, [
    { Name => 'User-Name', Value => 'JonSnow', Type => 'string', Vendor => undef, Tag => undef },
    { Name => 'User-Password', Value => 'Castle Black', Type => 'string', Vendor => undef, Tag => undef },
    # added by with_msg_auth => 1 in encoded, but real value is replaced to zeroes during validation
    { Name => 'Message-Authenticator', Value => "\x0" x 16, Type => 'string', Vendor => undef, Tag => undef },
], 'parsed packet');

# request Message-Authenticator by passing empty value
my($auth_req2, $req_id2, $auth2) = $p->build(
    type => ACCESS_REQUEST,
    av_list => [
        { Name => 'Message-Authenticator', Value => undef },
        { Name => 'User-Name', Value => 'JonSnow'},
        { Name => 'User-Password', Value => 'Castle Black' },
    ],
    authenticator => $authenticator,
    request_id => 12,
);
ok($auth_req2, 'packet built');
is($auth_req2, $auth_req, 'equal packet value');

# not using dictionary
my $n = Data::Radius::Packet->new(secret => 'top-secret');
ok($n, 'object');
my $bin_av = $n->pack_attribute({Id => 1, Type => 'string', Value => 'NoName'});
is($bin_av, "\x01\x08NoName", 'encoded string AV');

# Huawei (2011) / Huawei-Lease-Time (74)
my $bin_av2 = $n->pack_attribute({Id => 74, Type => 'integer', VendorId => 2011, Value => 42});
# 1A = 26 Vendor-Specific
# 0C = 12 VSA length
# 00 00 07 DB = 2011 Vendor ID
# 4A = 74 Huawei-Lease-Time
# 06 = 6 VSA value length (+2 header bytes)
# 00 00 00 2A = 42 uint32
is($bin_av2, "\x1A\x0C\x00\00\x07\xDB\x4A\x06\x00\x00\x00\x2A", 'encoded int VSA');

# WiMAX continuation byte
my $bin_wimax = $p->pack_attribute({Name => 'WiMAX-Hotline-Indicator', Value => 'ZZ' });
# 1A - 26 Vendor-Specific
# 0B = 11 VSA length
# 00 00 60 B5 = 24757 WiMAX Vendor ID
# 18 = 24 WiMAX-Hotline-Indicator
# 05 = 5 VSA value length
# 00 = 0 continuation byte
# ZZ value
is($bin_wimax, "\x1A\x0B\x00\x00\x60\xB5\x18\x05\x00ZZ", 'wimax vsa');
