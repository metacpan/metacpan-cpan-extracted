use Test::More;

BEGIN {
    use_ok('Akamai::Open::Request');
    use_ok('POSIX');
}
require_ok('Akamai::Open::Request');
require_ok('POSIX');

# object tests
my $req = new_ok('Akamai::Open::Request');

# subobjects tests
isa_ok($req->user_agent, 'LWP::UserAgent');
isa_ok($req->request, 'HTTP::Request');
isa_ok($req->debug, 'Akamai::Open::Debug');

# functional tests
like($req->nonce, qr/([0-9a-f]{8})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{4})-([0-9a-f]{12})/i,    'testing for a correct UUID');
is($req->gen_timestamp, strftime('%Y%m%dT%H:%M:%S%z', gmtime()),                               'testing for correct timestamp');

done_testing;
