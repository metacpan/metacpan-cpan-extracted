use strict;
use warnings;
use Test::More tests => 36;

# --- Module loading ---

use_ok('Apertur::SDK');
use_ok('Apertur::SDK::HTTPClient');
use_ok('Apertur::SDK::Error');
use_ok('Apertur::SDK::Error::Authentication');
use_ok('Apertur::SDK::Error::NotFound');
use_ok('Apertur::SDK::Error::RateLimit');
use_ok('Apertur::SDK::Error::Validation');
use_ok('Apertur::SDK::Signature');
use_ok('Apertur::SDK::Crypto');
use_ok('Apertur::SDK::Resource::Sessions');
use_ok('Apertur::SDK::Resource::Upload');
use_ok('Apertur::SDK::Resource::Uploads');
use_ok('Apertur::SDK::Resource::Polling');
use_ok('Apertur::SDK::Resource::Destinations');
use_ok('Apertur::SDK::Resource::Keys');
use_ok('Apertur::SDK::Resource::Webhooks');
use_ok('Apertur::SDK::Resource::Encryption');
use_ok('Apertur::SDK::Resource::Stats');

# --- Constructor ---

my $client = Apertur::SDK->new(api_key => 'aptr_live_test123');
isa_ok($client, 'Apertur::SDK');
is($client->env, 'live', 'live key detected as live env');

my $test_client = Apertur::SDK->new(api_key => 'aptr_test_abc');
is($test_client->env, 'test', 'test key detected as test env');

# Require at least one auth method
eval { Apertur::SDK->new() };
like($@, qr/api_key or oauth_token/, 'dies without credentials');

# OAuth token constructor
my $oauth_client = Apertur::SDK->new(oauth_token => 'some_oauth_token');
isa_ok($oauth_client, 'Apertur::SDK');
is($oauth_client->env, 'live', 'non-prefixed oauth token defaults to live');

# --- Resource accessors ---

isa_ok($client->sessions,     'Apertur::SDK::Resource::Sessions');
isa_ok($client->upload,       'Apertur::SDK::Resource::Upload');
isa_ok($client->uploads,      'Apertur::SDK::Resource::Uploads');
isa_ok($client->polling,      'Apertur::SDK::Resource::Polling');
isa_ok($client->destinations, 'Apertur::SDK::Resource::Destinations');
isa_ok($client->keys,         'Apertur::SDK::Resource::Keys');
isa_ok($client->webhooks,     'Apertur::SDK::Resource::Webhooks');
isa_ok($client->encryption,   'Apertur::SDK::Resource::Encryption');
isa_ok($client->stats,        'Apertur::SDK::Resource::Stats');

# --- Error classes ---

subtest 'Error hierarchy' => sub {
    plan tests => 17;

    my $base = Apertur::SDK::Error->new(
        status_code => 500,
        code        => 'INTERNAL',
        message     => 'Server error',
    );
    isa_ok($base, 'Apertur::SDK::Error');
    is($base->status_code, 500,            'base status_code');
    is($base->code,        'INTERNAL',     'base code');
    is($base->message,     'Server error', 'base message');

    my $auth = Apertur::SDK::Error::Authentication->new(message => 'Bad key');
    isa_ok($auth, 'Apertur::SDK::Error::Authentication');
    isa_ok($auth, 'Apertur::SDK::Error');
    is($auth->status_code, 401, 'auth status_code');

    my $nf = Apertur::SDK::Error::NotFound->new();
    isa_ok($nf, 'Apertur::SDK::Error');
    is($nf->status_code, 404,         'not found status_code');
    is($nf->message,     'Not found', 'not found default message');

    my $rl = Apertur::SDK::Error::RateLimit->new(
        message     => 'Slow down',
        retry_after => 30,
    );
    isa_ok($rl, 'Apertur::SDK::Error');
    is($rl->status_code,  429,         'rate limit status_code');
    is($rl->retry_after,  30,          'rate limit retry_after');

    my $val = Apertur::SDK::Error::Validation->new(message => 'Bad input');
    isa_ok($val, 'Apertur::SDK::Error');
    is($val->status_code, 400, 'validation status_code');

    # Test throw mechanism
    eval { Apertur::SDK::Error::NotFound->throw(message => 'Gone') };
    my $caught = $@;
    isa_ok($caught, 'Apertur::SDK::Error::NotFound');
    is($caught->message, 'Gone', 'thrown error message');
};

# --- Signature verification ---

subtest 'Signature verification' => sub {
    plan tests => 6;

    use Apertur::SDK::Signature qw(
        verify_webhook_signature
        verify_event_signature
        verify_svix_signature
    );

    # Webhook signature
    my $secret = 'my_secret';
    my $body   = '{"event":"test"}';

    use Digest::SHA qw(hmac_sha256_hex);
    my $sig_hex = hmac_sha256_hex($body, $secret);
    ok(
        verify_webhook_signature($body, "sha256=$sig_hex", $secret),
        'valid webhook signature accepted',
    );
    ok(
        !verify_webhook_signature($body, 'sha256=bad', $secret),
        'invalid webhook signature rejected',
    );

    # Event signature
    my $timestamp = '1700000000';
    my $event_sig = hmac_sha256_hex("${timestamp}.${body}", $secret);
    ok(
        verify_event_signature($body, $timestamp, "sha256=$event_sig", $secret),
        'valid event signature accepted',
    );
    ok(
        !verify_event_signature($body, $timestamp, 'sha256=bad', $secret),
        'invalid event signature rejected',
    );

    # Svix signature
    my $svix_id     = 'msg_abc123';
    my $svix_secret = 'deadbeef';
    my $svix_base   = "${svix_id}.${timestamp}.${body}";

    use MIME::Base64 qw(encode_base64);
    my $svix_expected = encode_base64(
        Digest::SHA::hmac_sha256($svix_base, pack('H*', $svix_secret)),
        '',
    );
    ok(
        verify_svix_signature($body, $svix_id, $timestamp, "v1,$svix_expected", $svix_secret),
        'valid svix signature accepted',
    );
    ok(
        !verify_svix_signature($body, $svix_id, $timestamp, 'v1,badsig==', $svix_secret),
        'invalid svix signature rejected',
    );
};

# --- Error stringification ---

subtest 'Error stringification' => sub {
    plan tests => 1;

    my $err = Apertur::SDK::Error->new(
        status_code => 500,
        code        => 'INTERNAL',
        message     => 'boom',
    );
    like("$err", qr/500.*INTERNAL.*boom/, 'error stringifies correctly');
};

done_testing();
