use strict;
use warnings;
use Test::More;
use JSON::PP qw(encode_json);
use Cloudflare::API;

my @request;
my $reply_hr={ success => JSON::PP::true, result => { id => 'one' }, result_info => { page => 2 } };
my $api_or=Cloudflare::API->new(
    token      => 'test-token',
    account_id => 'account one',
    transport  => sub {
        push(@request, [@_]);
        return { status => 200, headers => { 'content-type' => 'application/json' },
            content => encode_json($reply_hr) };
    }
);

is_deeply($api_or->request('GET', '/example'), { id => 'one' }, 'result is unwrapped');
is_deeply($api_or->request('GET', '/example', full_response => 1), $reply_hr,
    'full parsed response is available');
is_deeply($api_or->request_full('GET', '/example'), $reply_hr,
    'request_full returns the envelope');
is($request[0][1], 'https://api.cloudflare.com/client/v4/example', 'base URL joined');
is($request[0][2]{'headers'}{'Authorization'}, 'Bearer test-token', 'token header sent');
is($api_or->account_path('r2', 'buckets', 'a/b c'),
    '/accounts/account%20one/r2/buckets/a%2Fb%20c', 'path components encoded');

eval { $api_or->raw_request('GET', 'https://other.example/') };
like($@, qr/path must begin/, 'absolute URLs cannot receive the bearer token');

$reply_hr={ success => JSON::PP::false, errors => [{ code => 123, message => 'bad request' }] };
my $ok=eval { $api_or->request('GET', '/failure'); 1 };
ok(!$ok, 'Cloudflare envelope failure throws');
isa_ok($@, 'Cloudflare::API::Error');
is($@->errors()->[0]{'code'}, 123, 'Cloudflare error details retained');

my $empty_or=Cloudflare::API->new(token => 'test-token', transport => sub {
    return { status => 204, headers => {}, content => '' };
});
is($empty_or->request('DELETE', '/example'), undef, 'empty success has undefined result');

done_testing();
