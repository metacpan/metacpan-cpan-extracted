use strict;
use warnings;
use Data::HexDump;
use Test::More tests => 12;

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

#print HexDump($pod_req);

ok($pod_req, 'packet built');
is($req_id, 12, 'request id');

print HexDump($auth);
ok($auth, 'generated new authenticator');

my ($t, $id, $auth_p, $av) = $p->parse($pod_req);
is($t, DISCONNECT_REQUEST, 'packet type');
is($id, $req_id, 'request id');
is($auth_p, $auth, 'authenticator used');

is_deeply($av, [
     { Name => 'Acct-Session-Id', Value => 'AAAAAAAAAAAA', Type => 'string', Vendor => undef, Tag => undef },
     # added by with_msg_auth => 1 in encoded, but real value is replaced to zeroes during validation
     { Name => 'Message-Authenticator', Value => "\x0" x 16, Type => 'string', Vendor => undef, Tag => undef },
], 'parsed packet');
