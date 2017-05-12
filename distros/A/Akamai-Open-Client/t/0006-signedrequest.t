use Test::More;

BEGIN {
    use_ok('Akamai::Open::Request::EdgeGridV1');
    use_ok('Akamai::Open::Client');
    use_ok('URI');
}
require_ok('Akamai::Open::Request::EdgeGridV1');
require_ok('Akamai::Open::Client');
require_ok('URI');

# object tests
my $client = new_ok('Akamai::Open::Client');
my $req    = new_ok('Akamai::Open::Request::EdgeGridV1');
my $uri    = new_ok('URI' => ['http://www.cpan.org/']);

# subobject tests
isa_ok($req->debug, 'Akamai::Open::Debug');

# functional tests
ok($client->access_token('foobar'),             'setting access_token');
ok($client->client_token('barfoo'),             'setting client_token');
ok($client->client_secret('Zm9vYmFyYmFyZm9v'),  'setting client_secret');
ok($req->client($client),    'setting client');


# create a signed header
# for the test we've some static vars
ok($req->timestamp('20140504T13:37:00+0100'),   'setting timestamp');
ok($req->nonce('D3D34986-9A36-11E3-B85F-907ACF486320'), 'setting nonce');

# do the stuff manually, which the API module would do
$req->request->method('GET');
$req->request->uri($uri);
$req->sign_request;
is($req->signature, 's97XM2gfL8pReHvb2FrTrvFq2JiQOHfQ0jb7FsK6m5M=', 'approving the signature');
is($req->signing_key, 'DD3PRDdMOylhKlO+wtPvsqAZ8JUWFZfRppmdB/eVjHw=', 'approving the signing key');
is($req->request->headers->header('authorization'),
    'EG1-HMAC-SHA256 client_token=barfoo;access_token=foobar;timestamp=20140504T13:37:00+0100;nonce=D3D34986-9A36-11E3-B85F-907ACF486320;signature=s97XM2gfL8pReHvb2FrTrvFq2JiQOHfQ0jb7FsK6m5M=',
    'approving authorization header');

done_testing;
