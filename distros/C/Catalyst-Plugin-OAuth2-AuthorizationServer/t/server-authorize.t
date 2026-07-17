use v5.36;
use Test::More;
use Test::Fatal;
use lib 't/lib';
use StubStore;

my $class = 'Catalyst::Plugin::OAuth2::AuthorizationServer::Server';
require_ok($class);

sub fixture {
    my $store = StubStore->new;
    $store->create_client({
        client_id     => 'client-1',
        redirect_uris => ['https://app.example/cb'],
    });
    my $eng = $class->new(
        store            => $store,
        signing_key      => 'k' x 32,
        issuer           => 'https://as.example',
        resource         => 'https://rs.example/mcp',
        scopes_supported => [ 'example:read', 'example:themes:write' ],
    );
    return ( $eng, $store );
}

sub good_params (%over) {
    return {
        client_id             => 'client-1',
        redirect_uri          => 'https://app.example/cb',
        response_type         => 'code',
        code_challenge        => 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM',
        code_challenge_method => 'S256',
        scope                 => 'example:read',
        resource              => 'https://rs.example/mcp',
        state                 => 'xyz',
        %over,
    };
}

# happy path stashes and returns a request_id
{
    my ( $eng, $store ) = fixture();
    my $out = $eng->validate_authorize( good_params() );
    like( $out->{request_id}, qr/\A[A-Za-z0-9_-]+\z/, 'request_id minted' );
    my $saved = $store->take_authorization_request( $out->{request_id} );
    is( $saved->{client_id},    'client-1',                'saved client_id' );
    is( $saved->{redirect_uri}, 'https://app.example/cb',  'saved redirect_uri' );
    is( $saved->{code_challenge}, 'E9Melhoa2OwvFrEMTJguCHaoeK1t8URWbuGJSstw-cM', 'saved challenge' );
    is( $saved->{scope},        'example:read',              'saved scope' );
    is( $saved->{resource},     'https://rs.example/mcp',  'saved resource' );
    is( $saved->{state},        'xyz',                     'saved state' );
}

# third element: is this error redirect-safe? (client + redirect already valid)
my %cases = (
    unknown_client  => [ { client_id => 'nope' }, 'invalid_client', 0 ],
    bad_redirect    => [ { redirect_uri => 'https://evil/cb' }, 'invalid_client', 0 ],
    not_code        => [ { response_type => 'token' }, 'invalid_request', 1 ],
    no_challenge    => [ { code_challenge => undef }, 'invalid_request', 1 ],
    plain_method    => [ { code_challenge_method => 'plain' }, 'invalid_request', 1 ],
    short_challenge => [ { code_challenge => 'abc' }, 'invalid_request', 1 ],
    bad_scope       => [ { scope => 'example:read admin:all' }, 'invalid_scope', 1 ],
    bad_resource    => [ { resource => 'https://other/api' }, 'invalid_target', 1 ],
);
for my $name ( sort keys %cases ) {
    my ( $over, $want, $redirectable ) = @{ $cases{$name} };
    my ( $eng ) = fixture();
    my $e = exception { $eng->validate_authorize( good_params(%$over) ) };
    isa_ok( $e, 'Catalyst::Plugin::OAuth2::AuthorizationServer::Error', $name );
    is( $e->error, $want, "$name -> $want" );
    if ( $redirectable ) {
        is( $e->redirect_uri, 'https://app.example/cb',
            "$name is redirect-safe (carries redirect_uri)" );
    }
    else {
        is( $e->redirect_uri, undef,
            "$name is not redirect-safe (rendered directly)" );
    }
}

done_testing;
