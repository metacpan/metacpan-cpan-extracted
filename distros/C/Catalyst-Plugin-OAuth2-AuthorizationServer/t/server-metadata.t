use v5.36;
use Test::More;
use lib 't/lib';
use StubStore;

my $class = 'Catalyst::Plugin::OAuth2::AuthorizationServer::Server';
require_ok($class);

# defaults derive endpoints from issuer
{
    my $eng = $class->new(
        store => StubStore->new, signing_key => 'k' x 32,
        issuer => 'https://as.example', resource => 'https://rs/mcp',
    );
    my $m = $eng->metadata_document;
    is( $m->{issuer}, 'https://as.example', 'issuer' );
    is( $m->{authorization_endpoint}, 'https://as.example/authorize', 'authorize ep' );
    is( $m->{token_endpoint},         'https://as.example/token',     'token ep' );
    is( $m->{registration_endpoint},  'https://as.example/register',  'register ep' );
    is_deeply( $m->{response_types_supported}, ['code'], 'response_types' );
    is_deeply( $m->{grant_types_supported},
        [ 'authorization_code', 'refresh_token' ], 'grant_types' );
    is_deeply( $m->{code_challenge_methods_supported}, ['S256'], 'S256 only' );
    is_deeply( $m->{token_endpoint_auth_methods_supported}, ['none'],
        'public client' );
    ok( !exists $m->{scopes_supported}, 'no scopes key when unconfigured' );
}

# explicit endpoints + scopes
{
    my $eng = $class->new(
        store => StubStore->new, signing_key => 'k' x 32,
        issuer => 'https://as', resource => 'https://rs/mcp',
        authorize_endpoint    => 'https://as/oauth/authorize',
        token_endpoint        => 'https://as/oauth/token',
        registration_endpoint => 'https://as/oauth/register',
        scopes_supported      => [ 'example:read', 'example:themes:write' ],
    );
    my $m = $eng->metadata_document;
    is( $m->{authorization_endpoint}, 'https://as/oauth/authorize', 'explicit authorize ep' );
    is_deeply( $m->{scopes_supported},
        [ 'example:read', 'example:themes:write' ], 'scopes advertised' );
}

done_testing;
