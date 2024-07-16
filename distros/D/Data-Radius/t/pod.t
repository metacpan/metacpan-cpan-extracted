use strict;
use warnings;
use Data::HexDump;
use Test::More tests => 19 + 1;
use Test::NoWarnings;

BEGIN {
    use_ok('Data::Radius::Dictionary');
    use_ok('Data::Radius::Constants', qw(:all));
    use_ok('Data::Radius::Packet');
};

my $dict = Data::Radius::Dictionary->load_file('./radius/dictionary');
ok($dict, 'dictionary loaded');

my $p = Data::Radius::Packet->new(secret => 'top-secret', dict => $dict);
ok($p, 'object');

# Message-Authenticator have to use 00x16 string as authenticator for PoD/CoA
# but then it will be calculate as a checksum for the packet content

my($pod_req, $req_id, $auth) = $p->build(
    type => DISCONNECT_REQUEST,
    av_list => [
        { Name => 'Acct-Session-Id', Value => 'AAAAAAAAAAAA' },
    ],
    request_id => 12,
    with_msg_auth => 1,
);

# print STDERR HexDump($pod_req);

ok($pod_req, 'packet built');
is($req_id, 12, 'request id');

is(unpack('H*', $auth), '147da45625f266b33cf9a9971d9070b5', 'generated new authenticator');

my ($t, $id, $auth_p, $av) = $p->parse($pod_req);
is($t, DISCONNECT_REQUEST, 'packet type');
is($id, $req_id, 'request id');
is($auth_p, $auth, 'authenticator used');

is_deeply($av, [
     # added by with_msg_auth => 1 in encoded, but real value is replaced to zeroes during validation
     { Name => 'Message-Authenticator', Value => "\x0" x 16, Type => 'string', Vendor => undef, Tag => undef },
     { Name => 'Acct-Session-Id', Value => 'AAAAAAAAAAAA', Type => 'string', Vendor => undef, Tag => undef },
], 'parsed packet');


#-- Disable Message-Authenticator (not recommended)

($pod_req, $req_id, $auth) = $p->build(
    type => DISCONNECT_REQUEST,
    av_list => [
        { Name => 'Acct-Session-Id', Value => 'AAAAAAAAAAAA' },
    ],
    request_id => 42,
    with_msg_auth => 0,
);

ok($pod_req, 'packet built');
is($req_id, 42, 'request id');

is(unpack('H*', $auth), 'd2be1f59cfc180df0304f4801d00bb95', 'generated new authenticator');

($t, $id, $auth_p, $av) = $p->parse($pod_req);
is($t, DISCONNECT_REQUEST, 'packet type');
is($id, $req_id, 'request id');
is($auth_p, $auth, 'authenticator used');

is_deeply($av, [
     { Name => 'Acct-Session-Id', Value => 'AAAAAAAAAAAA', Type => 'string', Vendor => undef, Tag => undef },
], 'parsed packet, Message-Authenticator was disabled');


