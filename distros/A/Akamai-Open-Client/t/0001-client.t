use Test::More;

BEGIN {
    use_ok('Akamai::Open::Client');
}
require_ok('Akamai::Open::Client');

# object tests
my $client = new_ok('Akamai::Open::Client');

# subobject tests
isa_ok($client->debug, 'Akamai::Open::Debug');

# functional tests
ok($client->access_token('foobar'),             'setting access_token');
ok($client->client_token('barfoo'),             'setting client_token');
ok($client->client_secret('Zm9vYmFyYmFyZm9v'),  'setting client_secret');

is($client->access_token, 'foobar',             'getting access_token');
is($client->client_token, 'barfoo',             'getting client_token');
is($client->client_secret, 'Zm9vYmFyYmFyZm9v',  'getting client_secret');
isa_ok($client->debug, 'Akamai::Open::Debug');

done_testing;
