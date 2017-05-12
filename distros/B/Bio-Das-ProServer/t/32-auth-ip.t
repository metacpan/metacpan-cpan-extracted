use strict;
use warnings;
use Test::More;
use Socket;
use HTTP::Request;

eval {
  require Net::IP;
};
if ($@) {
  plan skip_all => 'IP authentication requires Net::IP';
} else {
  plan tests => 15;
}

# Initial basic tests
use_ok('Bio::Das::ProServer::Authenticator::ip');
my $auth = Bio::Das::ProServer::Authenticator::ip->new();
isa_ok($auth, 'Bio::Das::ProServer::Authenticator::ip');
can_ok($auth, qw(ip authenticate));

# Authenticator initialisation (whitelist) tests
eval {
  $auth = Bio::Das::ProServer::Authenticator::ip->new({
    'config' => {
                 'authallow' => inet_ntoa(INADDR_LOOPBACK).';111.111.111.111squiggle , 222.222.222./24',
                },
  });
};
ok($@, 'reject whitelist with nonsensical IP');
eval {
  $auth = Bio::Das::ProServer::Authenticator::ip->new({
    'config' => {
                 'authallow' => inet_ntoa(INADDR_LOOPBACK).';333.333.333.333 , 222.222.222/24',
                },
  });
};
ok($@, 'reject whitelist with bad IP');

# Allow/deny tests
$auth = Bio::Das::ProServer::Authenticator::ip->new({
  'config' => {
               'authallow' => inet_ntoa(INADDR_LOOPBACK).';111.111.111.111-111.111.111.112 , 222.222/16 ;2.2.2.0 + 255',
              },
});

my $resp = $auth->authenticate({ 'peer_addr' => inet_aton('1.1.1.1') });
isa_ok($resp, 'HTTP::Response', 'socket IP authentication (deny)');

$resp = $auth->authenticate({ 'peer_addr' => INADDR_LOOPBACK });
ok(!$resp, 'socket IP authentication (allow)');

my $req = HTTP::Request->new();
$req->header('X-Forwarded-For' => '1.1.1.1');
$resp = $auth->authenticate({ 'request' => $req });
isa_ok($resp, 'HTTP::Response', 'header IP authentication (deny)');

$req->header('X-Forwarded-For' => inet_ntoa(INADDR_LOOPBACK));
$resp = $auth->authenticate({ 'request' => $req });
ok(!$resp, 'header IP authentication(allow)');

$req->header('X-Forwarded-For' => '111.111.111.100');
$resp = $auth->authenticate({ 'request' => $req });
isa_ok($resp, 'HTTP::Response', 'range IP authentication (deny)');

$req->header('X-Forwarded-For' => '111.111.111.112');
$resp = $auth->authenticate({ 'request' => $req });
ok(!$resp, 'range IP authentication (allow)');

$req->header('X-Forwarded-For' => '111.222.1.111');
$resp = $auth->authenticate({ 'request' => $req });
isa_ok($resp, 'HTTP::Response', 'CIDR IP authentication (deny)');

$req->header('X-Forwarded-For' => '222.222.1.111');
$resp = $auth->authenticate({ 'request' => $req });
ok(!$resp, 'CIDR IP authentication (allow)');

$req->header('X-Forwarded-For' => '2.2.1.2');
$resp = $auth->authenticate({ 'request' => $req });
isa_ok($resp, 'HTTP::Response', 'additive IP authentication (deny)');

$req->header('X-Forwarded-For' => '2.2.2.2');
$resp = $auth->authenticate({ 'request' => $req });
ok(!$resp, 'additive IP authentication (allow)');