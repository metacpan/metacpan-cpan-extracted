use Test::More;

BEGIN {
    use_ok('Akamai::Open::Request::EdgeGridV1');
    use_ok('Akamai::Open::Client');
}
require_ok('Akamai::Open::Request::EdgeGridV1');
require_ok('Akamai::Open::Client');

# object tests
my $client = new_ok('Akamai::Open::Client');
my $req    = new_ok('Akamai::Open::Request::EdgeGridV1');

# subobject tests
isa_ok($req->debug, 'Akamai::Open::Debug');

# functional tests
ok($req->client($client),    'setting client');

# functional tests

done_testing;
