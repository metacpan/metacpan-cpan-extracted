#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
use FindBin;
use lib "$FindBin::Bin/../lib";

use Catalyst::Plugin::OpenIDConnect;
use Catalyst::Plugin::OpenIDConnect::Context;
use Catalyst::Plugin::OpenIDConnect::Utils::JWT;
use Catalyst::Plugin::OpenIDConnect::Utils::Store;
use Crypt::OpenSSL::RSA;
use File::Temp qw(tempfile);
use JSON::MaybeXS qw(encode_json);

# Generate test keys
my $rsa = Crypt::OpenSSL::RSA->generate_key(1024);

my $private_key = $rsa;
my $public_key = Crypt::OpenSSL::RSA->new_public_key(
    $rsa->get_public_key_string()
);

# Create JWT handler for testing context methods
my $jwt = Catalyst::Plugin::OpenIDConnect::Utils::JWT->new(
    private_key => $private_key,
    public_key  => $public_key,
    key_id      => 'test-key',
    issuer      => 'http://localhost:5000',
);

ok($jwt, 'JWT handler created');

# Create store for testing context methods
my $store = Catalyst::Plugin::OpenIDConnect::Utils::Store->new();
ok($store, 'Store created');

# Test _OpenIDConnectContext (the context object)
require_ok('Catalyst::Plugin::OpenIDConnect');

# Create a mock Catalyst object for testing the context
package MockCatalyst;
use Moose;

has config => (
    is      => 'ro',
    isa     => 'HashRef',
    default => sub { {} },
);

has _oidc_jwt => (
    is  => 'rw',
);

has _oidc_store => (
    is  => 'rw',
);

has log => (
    is      => 'ro',
    isa     => 'MockLogger',
    default => sub { MockLogger->new() },
);

sub uri_for {
    my ($self, $path) = @_;
    return bless { path => $path }, 'MockURI';
}

package MockLogger;
use Moose;

sub debug {
    my ($self, $msg) = @_;
    # Silently log or do nothing for testing
}

sub info {
    my ($self, $msg) = @_;
    # Silently log or do nothing for testing
}

sub warn {
    my ($self, $msg) = @_;
    # Silently log or do nothing for testing
}

sub error {
    my ($self, $msg) = @_;
    # Silently log or do nothing for testing
}

package MockURI;
sub as_string {
    my ($self) = @_;
    return 'http://localhost:5000' . $self->{path};
}

package main;

# Create mock Catalyst instance
my $mock_c = MockCatalyst->new(
    config => {
        'Plugin::OpenIDConnect' => {
            issuer => {
                url => 'http://localhost:5000',
            },
            clients => {
                'test-client' => {
                    client_id => 'test-client',
                    client_secret => 'test-secret',
                    redirect_uris => 'http://localhost:3000/callback',
                },
                'another-client' => {
                    client_id => 'another-client',
                    client_secret => 'another-secret',
                },
            },
            user_claims => {
                sub => 'id',
                name => 'full_name',
                email => 'email_address',
                picture => 'avatar.url',
            },
        },
    },
);

$mock_c->_oidc_jwt($jwt);
$mock_c->_oidc_store($store);

# Test _OpenIDConnectContext
# Access the Context class that's defined in a separate module
my $context = Catalyst::Plugin::OpenIDConnect::Context->new(
    catalyst => $mock_c,
);

ok($context, '_OpenIDConnectContext created');
isa_ok($context->catalyst, 'MockCatalyst', 'catalyst attribute');

# Test jwt() method
my $ctx_jwt = $context->jwt();
ok($ctx_jwt, 'jwt() returns JWT handler');
isa_ok($ctx_jwt, 'Catalyst::Plugin::OpenIDConnect::Utils::JWT');

# Test store() method
my $ctx_store = $context->store();
ok($ctx_store, 'store() returns store');
isa_ok($ctx_store, 'Catalyst::Plugin::OpenIDConnect::Utils::Store');

# Test lazy store initialization when no store is preconfigured
my $mock_no_store = MockCatalyst->new(
    config => {
        'Plugin::OpenIDConnect' => {
            issuer => { url => 'http://localhost:5000' },
        },
    },
);

my $ctx_lazy = Catalyst::Plugin::OpenIDConnect::Context->new(
    catalyst => $mock_no_store,
);

my $lazy_store = $ctx_lazy->store();
ok($lazy_store, 'store() lazy-initializes a store when missing');
isa_ok($lazy_store, 'Catalyst::Plugin::OpenIDConnect::Utils::Store');

# Test config() method
my $config = $context->config();
ok($config, 'config() returns configuration');
is($config->{issuer}{url}, 'http://localhost:5000', 'issuer URL in config');

# Test get_client() method
my $client = $context->get_client('test-client');
ok($client, 'get_client() returns client');
is($client->{client_secret}, 'test-secret', 'client secret matches');

my $client2 = $context->get_client('another-client');
ok($client2, 'get_client() returns second client');

my $missing_client = $context->get_client('nonexistent');
is($missing_client, undef, 'get_client() returns undef for missing client');

# Test get_user_claims() with hash-based user object
my $hash_user = {
    id            => 'user-123',
    full_name     => 'John Doe',
    email_address => 'john@example.com',
    avatar        => {
        url => 'http://example.com/avatar.jpg',
    },
};

my $hash_claims = $context->get_user_claims($hash_user);
ok($hash_claims, 'get_user_claims() works with hash user');
is($hash_claims->{sub}, 'user-123', 'sub claim correct');
is($hash_claims->{name}, 'John Doe', 'name claim correct');
is($hash_claims->{email}, 'john@example.com', 'email claim correct');
is($hash_claims->{picture}, 'http://example.com/avatar.jpg', 'picture claim with nested access');

# Test get_user_claims() with object-based user
package TestUser;
use Moose;

has id => (is => 'ro', default => 'user-456');
has full_name => (is => 'ro', default => 'Jane Doe');
has email_address => (is => 'ro', default => 'jane@example.com');

package main;

my $obj_user = TestUser->new();
my $obj_claims = $context->get_user_claims($obj_user);
ok($obj_claims, 'get_user_claims() works with object user');
is($obj_claims->{sub}, 'user-456', 'sub claim from object');
is($obj_claims->{name}, 'Jane Doe', 'name claim from object');
is($obj_claims->{email}, 'jane@example.com', 'email claim from object');

# Test get_user_claims() with default claims config
my $context_default = Catalyst::Plugin::OpenIDConnect::Context->new(
    catalyst => MockCatalyst->new(
        config => {
            'Plugin::OpenIDConnect' => {},
        },
    ),
);

my $default_user = {
    id    => '789',
    name  => 'Bob Smith',
    email => 'bob@example.com',
};

my $default_claims = $context_default->get_user_claims($default_user);
ok($default_claims, 'get_user_claims() with default config');
is($default_claims->{sub}, '789', 'default sub claim');
is($default_claims->{name}, 'Bob Smith', 'default name claim');
is($default_claims->{email}, 'bob@example.com', 'default email claim');

# Test get_discovery() method
my $discovery = $context->get_discovery();
ok($discovery, 'get_discovery() returns structure');
is($discovery->{issuer}, 'http://localhost:5000', 'issuer in discovery');
like($discovery->{authorization_endpoint}, qr/authorize/, 'authorization_endpoint');
like($discovery->{token_endpoint}, qr/token/, 'token_endpoint');
like($discovery->{userinfo_endpoint}, qr/userinfo/, 'userinfo_endpoint');
like($discovery->{jwks_uri}, qr/jwks/, 'jwks_uri');

# Check scopes
my @scopes = @{ $discovery->{scopes_supported} };
ok(grep { $_ eq 'openid' } @scopes, 'openid scope supported');
ok(grep { $_ eq 'profile' } @scopes, 'profile scope supported');
ok(grep { $_ eq 'email' } @scopes, 'email scope supported');

# Check algorithms
is_deeply(
    $discovery->{id_token_signing_alg_values_supported},
    ['RS256'],
    'RS256 algorithm supported for ID tokens'
);

# Check claims
my @claims = @{ $discovery->{claims_supported} };
ok(grep { $_ eq 'sub' } @claims, 'sub claim supported');
ok(grep { $_ eq 'email' } @claims, 'email claim supported');
ok(grep { $_ eq 'picture' } @claims, 'picture claim supported');

# Verify discovery contains required fields
ok($discovery->{response_types_supported}, 'response_types_supported present');
ok($discovery->{grant_types_supported}, 'grant_types_supported present');
ok($discovery->{subject_types_supported}, 'subject_types_supported present');

# Test get_discovery() with custom issuer URL
my $custom_issuer_context = Catalyst::Plugin::OpenIDConnect::Context->new(
    catalyst => MockCatalyst->new(
        config => {
            'Plugin::OpenIDConnect' => {
                issuer => {
                    url => 'https://auth.example.com',
                },
            },
        },
    ),
);

my $custom_discovery = $custom_issuer_context->get_discovery();
is($custom_discovery->{issuer}, 'https://auth.example.com', 'custom issuer URL in discovery');

# Test empty config handling
my $empty_context = Catalyst::Plugin::OpenIDConnect::Context->new(
    catalyst => MockCatalyst->new(
        config => {},
    ),
);

ok($empty_context->config, 'config() handles empty configuration');
is_deeply($empty_context->config, {}, 'empty config returns empty hashref');

# Test get_client with empty clients config
my $empty_client = $empty_context->get_client('any-client');
is($empty_client, undef, 'get_client() handles empty clients config');

# ---------------------------------------------------------------------------
# MED-3: JWT and Store instances are isolated per consuming application class
# ---------------------------------------------------------------------------

{
    my $app_a = bless {}, 'FakeAppAlpha';
    my $app_b = bless {}, 'FakeAppBeta';

    # Create a second distinct JWT instance for app_b
    my $rsa_b = Crypt::OpenSSL::RSA->generate_key(1024);
    my $jwt_b = Catalyst::Plugin::OpenIDConnect::Utils::JWT->new(
        private_key => $rsa_b,
        public_key  => Crypt::OpenSSL::RSA->new_public_key( $rsa_b->get_public_key_string() ),
        key_id      => 'key-b',
        issuer      => 'http://b.example.com',
    );

    Catalyst::Plugin::OpenIDConnect::_oidc_jwt( $app_a, $jwt );
    Catalyst::Plugin::OpenIDConnect::_oidc_jwt( $app_b, $jwt_b );

    is(
        Catalyst::Plugin::OpenIDConnect::_oidc_jwt($app_a), $jwt,
        'MED-3: FakeAppAlpha holds its own JWT instance',
    );
    is(
        Catalyst::Plugin::OpenIDConnect::_oidc_jwt($app_b), $jwt_b,
        'MED-3: FakeAppBeta holds its own JWT instance',
    );
    isnt(
        Catalyst::Plugin::OpenIDConnect::_oidc_jwt($app_a),
        Catalyst::Plugin::OpenIDConnect::_oidc_jwt($app_b),
        'MED-3: JWT instances are isolated between application classes',
    );
}

# ---------------------------------------------------------------------------
# MED-4: Implicit grant/response types removed from discovery document
# ---------------------------------------------------------------------------

{
    my $grant_types    = $discovery->{grant_types_supported};
    my $response_types = $discovery->{response_types_supported};

    ok(
        !grep { $_ eq 'implicit' } @$grant_types,
        'MED-4: implicit not in grant_types_supported',
    );
    ok(
        scalar( grep { $_ eq 'authorization_code' } @$grant_types ),
        'authorization_code still in grant_types_supported',
    );

    ok(
        !grep { $_ eq 'id_token' || $_ eq 'token' } @$response_types,
        'MED-4: implicit response types (id_token, token) not in response_types_supported',
    );
    ok(
        scalar( grep { $_ eq 'code' } @$response_types ),
        'code still in response_types_supported',
    );
}

done_testing();
