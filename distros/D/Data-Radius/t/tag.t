use strict;
use warnings;
use File::Spec ();
use Data::HexDump;
use Test::More tests => 13 + 1;
use Test::NoWarnings;

BEGIN {
    use_ok('Data::Radius::Dictionary');
    use_ok('Data::Radius::Constants', qw(:all));
    use_ok('Data::Radius::Packet');
};

my $dict = Data::Radius::Dictionary->load_file('./radius/dictionary');
ok($dict, 'dictionary loaded');

my $p = Data::Radius::Packet->new(secret => 'secret', dict => $dict);
ok($p, 'object');

# cannot use random-generated during tests
my $authenticator = pack('L<4', 561138743, 3194401087, 2213483623, 4032919672);

my($auth_req, $req_id, $auth) = $p->build(
    type => ACCESS_REQUEST,
    av_list => [
        { Name => 'User-Name', Value => 'JonSnow'},
        { Name => 'User-Password', Value => 'Castle Black' },
        { Name => 'Tunnel-Type', Value => 'PPTP', Tag => 5 },
        { Name => 'Tunnel-Private-Group-Id:3', Value => 'qqq'},
        # Vendor Alcatel-IPD / 6527
        { Name => 'Alc-Tunnel-Max-Sessions:10', Value => 42 },
    ],
    authenticator => $authenticator,
    request_id => 15,
    with_msg_auth => 0,
);

#print HexDump($auth_req);

is(HexDump($auth_req), <<DUMP, 'binary dump');
          00 01 02 03 04 05 06 07 - 08 09 0A 0B 0C 0D 0E 0F  0123456789ABCDEF

00000000  01 0F 00 47 37 4C 72 21 - 3F B1 66 BE 67 14 EF 83  ...G7Lr!?.f.g...
00000010  78 78 61 F0 01 09 4A 6F - 6E 53 6E 6F 77 02 12 A1  xxa...JonSnow...
00000020  23 A0 08 D7 51 D2 73 18 - 16 2A A3 61 08 AA 0F 40  #...Q.s..*.a...@
00000030  06 05 00 00 01 51 06 03 - 71 71 71 1A 0C 00 00 19  .....Q..qqq.....
00000040  7F 30 06 0A 00 00 2A                               .0....*
DUMP
# 01 Access-Requests id=0F (15) len=0036 (54)
#  authenticator: 37 4C 72 21 3F B1 66 BE 67 14 EF 83 78 78 61 F0
#  Attributes:
#  01 - User-Name len=09 value: 4A 6F 6E 53 6E 6F 77 (JonSnow)
#  02 - User-Password len=12 (18) value: A1 23 A0 08 D7 51 D2 73 18 16 2A A3 61 08 AA 0F
#  40 (64) Tunnel-Type len=07 tag=5 value: 00 00 00 01 (1 = PPTP)
#  51 (81) Tunnel-Private-Group-Id len=06 tag=03 value: 71 71 71 (qqq)
#  1A (26) Vendor-Specific len=0C (12) Vendor: 00 00 19 7F (6527)
#      30 (48) Alc-Tunnel-Max-Sessions len=06 Tag=0A (10) value: 00 00 2A (42)

ok($auth_req, 'packet built');
is($req_id, 15, 'request id');
is($auth, $authenticator, 'authenticator used');

my ($t, $id, $auth_p, $av) = $p->parse($auth_req, $authenticator);
is($t, ACCESS_REQUEST, 'packet type');
is($id, $req_id, 'request id');
is($auth_p, $auth, 'authenticator used');
is_deeply($av, [
    { Name => 'User-Name', Value => 'JonSnow', Type => 'string', Vendor => undef, Tag => undef },
    { Name => 'User-Password', Value => 'Castle Black', Type => 'string', Vendor => undef, Tag => undef },
    { Name => 'Tunnel-Type', Value => 'PPTP', Type => 'integer', Vendor => undef, Tag => 5},
    { Name => 'Tunnel-Private-Group-Id', Value => 'qqq', Type => 'string', Vendor => undef, Tag => 3 },
    { Name => 'Alc-Tunnel-Max-Sessions', Value => 42, Type => 'integer', Vendor => 'Alcatel-IPD', Tag => 10 },
], 'parsed packet');

