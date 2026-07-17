use v5.36;
use Test::More;
use Test::Fatal;
use lib 't/lib';
use StubStore;

my $class = 'Catalyst::Plugin::OAuth2::AuthorizationServer::Server';
require_ok($class);

sub engine (%over) {
    return $class->new(
        store       => StubStore->new,
        signing_key => 'k' x 32,
        issuer      => 'https://as.example',
        resource    => 'https://rs.example/mcp',
        %over,
    );
}

# happy path: generates a client_id, echoes metadata, persists via the store
{
    my $eng = engine();
    my $client = $eng->register_client({
        redirect_uris => ['https://app.example/cb'],
        client_name   => 'Test',
    });
    like( $client->{client_id}, qr/\A[A-Za-z0-9_-]+\z/, 'generated client_id' );
    is_deeply( $client->{redirect_uris}, ['https://app.example/cb'], 'redirect kept' );
    is( $eng->store->find_client( $client->{client_id} )->{client_name},
        'Test', 'persisted via store' );
}

# missing redirect_uris -> invalid_client_metadata
{
    my $e = exception { engine()->register_client({ client_name => 'x' }) };
    isa_ok( $e, 'Catalyst::Plugin::OAuth2::AuthorizationServer::Error' );
    is( $e->error, 'invalid_client_metadata', 'no redirect_uris rejected' );
}

# too many redirect_uris
{
    my $e = exception {
        engine( redirect_uris_max => 2 )->register_client({
            redirect_uris => [ map { "https://a/$_" } 1 .. 3 ],
        });
    };
    is( $e->error, 'invalid_client_metadata', 'over redirect_uris_max rejected' );
}

# over-long redirect_uri
{
    my $long = 'https://a/' . ( 'x' x 3000 );
    my $e = exception {
        engine->register_client({ redirect_uris => [$long] });
    };
    is( $e->error, 'invalid_client_metadata', 'over-long redirect_uri rejected' );
}

# oversize metadata document
{
    my $e = exception {
        engine( metadata_max_bytes => 64 )->register_client({
            redirect_uris => ['https://app.example/cb'],
            blob          => 'y' x 200,
        });
    };
    is( $e->error, 'invalid_client_metadata', 'oversize metadata rejected' );
}

# javascript: / non-https redirect_uri rejected
{
    my $e = exception {
        engine->register_client({ redirect_uris => ['javascript:alert(1)'] });
    };
    is( $e->error, 'invalid_client_metadata', 'javascript: redirect rejected' );
}
# plain http (non-loopback) rejected; loopback http allowed
{
    my $e = exception {
        engine->register_client({ redirect_uris => ['http://evil.example/cb'] });
    };
    is( $e->error, 'invalid_client_metadata', 'non-loopback http rejected' );
    my $ok = engine->register_client({ redirect_uris => ['http://127.0.0.1/cb'] });
    like( $ok->{client_id}, qr/\A[A-Za-z0-9_-]+\z/, 'loopback http allowed' );
}
# fragment rejected
{
    my $e = exception {
        engine->register_client({ redirect_uris => ['https://app/cb#frag'] });
    };
    is( $e->error, 'invalid_client_metadata', 'redirect_uri with fragment rejected' );
}

# --- RFC 7591 3.2.1: metadata values this AS does not advertise are rejected ---

# token_endpoint_auth_method: metadata advertises 'none' only
{
    my $e = exception {
        engine->register_client({
            redirect_uris              => ['https://app.example/cb'],
            token_endpoint_auth_method => 'client_secret_basic',
        });
    };
    isa_ok( $e, 'Catalyst::Plugin::OAuth2::AuthorizationServer::Error',
        'client_secret_basic registration' );
    is( $e->error, 'invalid_client_metadata',
        'unadvertised token_endpoint_auth_method rejected' );

    my $ok = engine->register_client({
        redirect_uris              => ['https://app.example/cb'],
        token_endpoint_auth_method => 'none',
    });
    is( $ok->{token_endpoint_auth_method}, 'none',
        'the advertised token_endpoint_auth_method is accepted' );
}

# grant_types: metadata advertises authorization_code + refresh_token
{
    my $e = exception {
        engine->register_client({
            redirect_uris => ['https://app.example/cb'],
            grant_types   => [ 'authorization_code', 'client_credentials' ],
        });
    };
    is( $e->error, 'invalid_client_metadata', 'unadvertised grant_type rejected' );

    my $ok = engine->register_client({
        redirect_uris => ['https://app.example/cb'],
        grant_types   => [ 'authorization_code', 'refresh_token' ],
    });
    is_deeply( $ok->{grant_types}, [ 'authorization_code', 'refresh_token' ],
        'advertised grant_types accepted' );
}

# response_types: metadata advertises 'code' only
{
    my $e = exception {
        engine->register_client({
            redirect_uris  => ['https://app.example/cb'],
            response_types => ['token'],
        });
    };
    is( $e->error, 'invalid_client_metadata', 'unadvertised response_type rejected' );

    my $ok = engine->register_client({
        redirect_uris  => ['https://app.example/cb'],
        response_types => ['code'],
    });
    is_deeply( $ok->{response_types}, ['code'], 'advertised response_type accepted' );
}

# the list-valued fields must actually be lists of strings
{
    for my $bad ( 'authorization_code', [], [ {} ] ) {
        my $e = exception {
            engine->register_client({
                redirect_uris => ['https://app.example/cb'],
                grant_types   => $bad,
            });
        };
        is( $e->error, 'invalid_client_metadata',
            'grant_types must be a non-empty array of strings' );
    }
}

# scope is only constrained when the AS advertises scopes_supported
{
    my $e = exception {
        engine( scopes_supported => ['example:read'] )->register_client({
            redirect_uris => ['https://app.example/cb'],
            scope         => 'example:read admin:all',
        });
    };
    is( $e->error, 'invalid_client_metadata', 'unadvertised scope rejected' );

    my $ok = engine( scopes_supported => ['example:read'] )->register_client({
        redirect_uris => ['https://app.example/cb'],
        scope         => 'example:read',
    });
    is( $ok->{scope}, 'example:read', 'advertised scope accepted' );

    my $free = engine->register_client({
        redirect_uris => ['https://app.example/cb'],
        scope         => 'anything the app likes',
    });
    is( $free->{scope}, 'anything the app likes',
        'scope is free-form when the AS advertises no scopes_supported' );
}

# free-form RFC 7591 fields are not rejected merely for being present
{
    my $ok = engine->register_client({
        redirect_uris => ['https://app.example/cb'],
        client_name   => 'My App',
        client_uri    => 'https://app.example',
        logo_uri      => 'https://app.example/logo.png',
        contacts      => ['dev@app.example'],
        software_id   => 'abc-123',
    });
    is( $ok->{client_name}, 'My App',                     'client_name kept' );
    is( $ok->{logo_uri},    'https://app.example/logo.png', 'logo_uri kept' );
    is_deeply( $ok->{contacts}, ['dev@app.example'],      'contacts kept' );
    is( $ok->{software_id}, 'abc-123', 'unknown extension field not rejected' );
}

# a fully-specified valid registration round-trips through the store
{
    my $eng = engine( scopes_supported => ['example:read'] );
    my $client = $eng->register_client({
        redirect_uris              => ['https://app.example/cb'],
        token_endpoint_auth_method => 'none',
        grant_types                => [ 'authorization_code', 'refresh_token' ],
        response_types             => ['code'],
        scope                      => 'example:read',
        client_name                => 'Round Trip',
    });
    like( $client->{client_id}, qr/\A[A-Za-z0-9_-]+\z/, 'client_id minted' );
    is_deeply( $eng->store->find_client( $client->{client_id} ), $client,
        'full valid registration round-trips through the store' );
}

done_testing;
