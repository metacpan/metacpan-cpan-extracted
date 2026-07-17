use v5.36;
use Test::More;
use Test::Fatal;
use lib 't/lib';
use StubStore;

my $class = 'Catalyst::Plugin::OAuth2::AuthorizationServer::Server';
require_ok($class);

my $store = StubStore->new;
$store->create_client({
    client_id => 'client-1', redirect_uris => ['https://app/cb'],
});
my $eng = $class->new(
    store => $store, signing_key => 'k' x 32,
    issuer => 'https://as', resource => 'https://rs/mcp',
);

# stash a request, then issue a code against it
my $rid = $eng->validate_authorize({
    client_id => 'client-1', redirect_uri => 'https://app/cb',
    response_type => 'code',
    code_challenge => 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
    code_challenge_method => 'S256',
    scope => 'example:read', resource => 'https://rs/mcp', state => 'st',
})->{request_id};

my $out = $eng->issue_code( 'user-7', $rid );
like( $out->{code}, qr/\A[A-Za-z0-9_-]+\z/, 'code minted' );
is( $out->{redirect_uri}, 'https://app/cb', 'redirect echoed' );
is( $out->{state},        'st',             'state echoed' );

# the binding is persisted and bound to the consenting subject
my $binding = $store->consume_auth_code( $out->{code} );
is( $binding->{subject},        'user-7',         'bound to subject' );
is( $binding->{client_id},      'client-1',       'bound client' );
is( $binding->{redirect_uri},   'https://app/cb', 'bound redirect' );
is( $binding->{code_challenge}, 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM', 'bound challenge' );
is( $binding->{scope},          'example:read',     'bound scope' );
is( $binding->{resource},       'https://rs/mcp', 'bound resource' );

# the request was single-use: a second issue against the same rid fails
my $e = exception { $eng->issue_code( 'user-7', $rid ) };
isa_ok( $e, 'Catalyst::Plugin::OAuth2::AuthorizationServer::Error' );
is( $e->error, 'invalid_request', 'consumed/unknown request_id rejected' );

done_testing;
