use strict;
use warnings;
use Test::More;
use JSON::PP qw(encode_json decode_json);
use Cloudflare::API;

my @request;
my $api_or=Cloudflare::API->new(
    token => 'test-token', account_id => 'acct',
    transport => sub {
        push(@request, [@_]);
        return { status => 200, headers => {}, content => encode_json({
            success => JSON::PP::true, result => { ok => 1 },
            result_info => { page => 1 }
        }) };
    }
);

is_deeply($api_or->r2()->create_bucket({ name => 'test-bucket' }), { ok => 1 },
    'R2 create returns result');
is($request[-1][0], 'POST', 'R2 create uses POST');
like($request[-1][1], qr{/accounts/acct/r2/buckets\z}, 'R2 path');
is(decode_json($request[-1][2]{'content'})->{'name'}, 'test-bucket', 'R2 JSON body');

$api_or->r2()->delete_bucket('a/b');
like($request[-1][1], qr{/r2/buckets/a%2Fb\z}, 'R2 name encoded');
$api_or->r2()->update_bucket('bucket', { storageClass => 'Standard' });
is($request[-1][0], 'PATCH', 'R2 update uses PATCH');

$api_or->kv()->create_namespace({ title => 'test-kv' });
like($request[-1][1], qr{/storage/kv/namespaces\z}, 'KV path');
$api_or->kv()->rename_namespace('ns', { title => 'new' });
is($request[-1][0], 'PUT', 'KV rename uses PUT');
$api_or->kv()->list_keys('ns', prefix => 'app/', limit => 5);
like($request[-1][1], qr{/namespaces/ns/keys\?limit=5&prefix=app%2F\z},
    'KV keys list and filters');
$api_or->kv()->put_value('ns', 'a/b', 'hello', expiration_ttl => 120);
like($request[-1][1], qr{/namespaces/ns/values/a%2Fb\?expiration_ttl=120\z},
    'KV value path and expiry');
is($request[-1][2]{'content'}, 'hello', 'KV writes raw value');
$api_or->kv()->delete_value('ns', 'a/b');
is($request[-1][0], 'DELETE', 'KV value deletion');
eval { $api_or->kv()->put_value('ns', 'key', 'value', expiration => 1,
    expiration_ttl => 120) };
like($@, qr/mutually exclusive/, 'KV rejects ambiguous expiry');
my $raw_or=Cloudflare::API->new(token => 'test-token', account_id => 'acct',
    transport => sub { return { status => 200, headers => {}, content => "a\0b" } });
is($raw_or->kv()->get_value('ns', 'key'), "a\0b", 'KV returns raw binary value');

$api_or->d1()->create_database({ name => 'test-db' });
like($request[-1][1], qr{/d1/database\z}, 'D1 path');
$api_or->d1()->query_database('db', { sql => 'SELECT 1' });
like($request[-1][1], qr{/d1/database/db/query\z}, 'D1 query path');
$api_or->d1()->query_sql('db', 'SELECT ? AS value', ['bound']);
is_deeply(decode_json($request[-1][2]{'content'}),
    { sql => 'SELECT ? AS value', params => ['bound'] }, 'D1 SQL parameters bound');
$api_or->d1()->query_sql('db', 'SELECT 1', full_response => 1);
is_deeply(decode_json($request[-1][2]{'content'}),
    { sql => 'SELECT 1' }, 'D1 SQL parameters optional');
$api_or->d1()->update_database('db', { read_replication => { mode => 'auto' } });
is($request[-1][0], 'PATCH', 'D1 update uses PATCH');

$api_or->queues()->create_queue({ queue_name => 'test-q' });
like($request[-1][1], qr{/queues\z}, 'Queues path');
$api_or->queues()->create_consumer('q', { type => 'worker', script_name => 'script' });
like($request[-1][1], qr{/queues/q/consumers\z}, 'queue consumer path');
$api_or->queues()->update_queue('q', { message_retention_period => 3600 });
is($request[-1][0], 'PATCH', 'queue update uses PATCH');
$api_or->queues()->list_consumers('q');
like($request[-1][1], qr{/queues/q/consumers\z}, 'list consumers path');
$api_or->queues()->delete_consumer('q', 'consumer');
like($request[-1][1], qr{/queues/q/consumers/consumer\z}, 'delete consumer path');

$api_or->hyperdrive()->list_configs();
like($request[-1][1], qr{/hyperdrive/configs\z}, 'Hyperdrive list path');
$api_or->hyperdrive()->create_config({ name => 'test', origin => { host => 'db.example.com' } });
is($request[-1][0], 'POST', 'Hyperdrive create uses POST');
$api_or->hyperdrive()->update_config('config', { caching => { disabled => JSON::PP::true } });
is($request[-1][0], 'PATCH', 'Hyperdrive update uses PATCH');
$api_or->hyperdrive()->delete_config('config');
like($request[-1][1], qr{/hyperdrive/configs/config\z}, 'Hyperdrive delete path');

$api_or->secrets_store()->create_store({ name => 'test' });
like($request[-1][1], qr{/secrets_store/stores\z}, 'Secrets Store create path');
$api_or->secrets_store()->create_secret('store', [
    { name => 'test', value => 'sensitive', scopes => ['workers'] }]);
is(ref(decode_json($request[-1][2]{'content'})), 'ARRAY',
    'Secrets Store create uses an array body');
$api_or->secrets_store()->update_secret('store', 'secret', { value => 'replacement' });
is($request[-1][0], 'PATCH', 'Secrets Store patch uses PATCH');
$api_or->secrets_store()->get_quota();
like($request[-1][1], qr{/secrets_store/quota\z}, 'Secrets Store quota path');

$api_or->accounts()->list();
like($request[-1][1], qr{/accounts\z}, 'account list path');
$api_or->zones()->list(name => 'example.com', full_response => 1);
like($request[-1][1], qr{/zones\?name=example\.com\z}, 'zone filter encoded');
is_deeply($api_or->zones()->list(full_response => 1)->{'result_info'},
    { page => 1 }, 'full response option preserves pagination');

done_testing();
