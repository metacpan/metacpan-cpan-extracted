use v5.36;
use Test::More;
use Test::Fatal;
use Crypt::JWT qw/encode_jwt/;

my $class = 'Catalyst::Plugin::OAuth2::ResourceServer::Server';
require_ok($class);

my $KEY = 'resource-server-secret-key-0123456789';

sub engine (%over) {
    return $class->new(
        signing_key => $KEY,
        resource    => 'https://rs.example/mcp',
        issuer      => 'https://as.example',
        %over,
    );
}

# a helper to mint a token the way the AS would
sub token (%claims) {
    return encode_jwt(
        payload => {
            sub   => 'user-1',
            aud   => 'https://rs.example/mcp',
            iss   => 'https://as.example',
            scope => 'example:read',
            exp   => time + 60,
            %claims,
        },
        alg => 'HS256',
        key => $KEY,
    );
}

# BUILD validation
like( exception { engine( resource => [] ) }, qr/resource/, 'empty resource rejected' );
like( exception { engine( jwt_alg => 'RS256' ) }, qr/jwt_alg/, 'non-HS alg rejected' );
like(
    exception {
        $class->new( signing_key => 'short', resource => 'https://rs.example/mcp',
            issuer => 'https://as.example' );
    },
    qr/signing_key must be at least/,
    'short signing_key rejected'
);

# happy path -> claims
{
    my $claims = engine->verify_token( token() );
    is( $claims->{sub},   'user-1',     'sub claim' );
    is( $claims->{scope}, 'example:read', 'scope claim' );
}

# array aud containing our resource is accepted
{
    my $jwt = token( aud => [ 'https://other', 'https://rs.example/mcp' ] );
    ok( engine->verify_token($jwt), 'array aud incl. our resource accepted' );
}

my %fail = (
    expired      => token( exp => time - 10 ),
    wrong_aud    => token( aud => 'https://other/api' ),
    wrong_iss    => token( iss => 'https://evil' ),
    bad_sig      => encode_jwt(
        payload => {
            sub => 'user-1', aud => 'https://rs.example/mcp',
            iss => 'https://as.example', exp => time + 60,
        },
        alg => 'HS256', key => $KEY . '-tampered' ),
    malformed    => 'not-a-jwt',
    no_aud       => encode_jwt(
        payload => { sub => 'u', iss => 'https://as.example', exp => time + 60 },
        alg => 'HS256', key => $KEY ),
    no_exp       => encode_jwt(
        payload => { sub => 'u', aud => 'https://rs.example/mcp', iss => 'https://as.example' },
        alg => 'HS256', key => $KEY ),
);
for my $name ( sort keys %fail ) {
    my $e = exception { engine->verify_token( $fail{$name} ) };
    isa_ok( $e, 'Catalyst::Plugin::OAuth2::ResourceServer::Error', $name );
    is( $e->error, 'invalid_token', "$name -> invalid_token" );
    is( $e->http_status, 401, "$name -> 401" );
}

# alg=none rejected by the accepted-alg allowlist
{
    my $none = encode_jwt( payload => { sub => 'u', aud => 'https://rs.example/mcp',
        iss => 'https://as.example', exp => time + 60 },
        alg => 'none', key => undef, allow_none => 1 );
    my $e = exception { engine->verify_token($none) };
    is( $e->error, 'invalid_token', 'alg=none rejected' );
}

# leeway lets a just-expired token through
{
    my $jwt = token( exp => time - 3 );
    ok( engine( leeway => 30 )->verify_token($jwt), 'within leeway accepted' );
}

# an unknown constructor key croaks (StrictConstructor)
like( exception { engine( bogus_key => 1 ) }, qr/bogus_key|StrictConstructor|not.*(allowed|listed)/i,
    'unknown config key croaks' );

# --- nbf (RFC 7519 4.1.5): validate-if-present, honouring leeway ---
{
    my $e = exception { engine->verify_token( token( nbf => time + 300 ) ) };
    isa_ok( $e, 'Catalyst::Plugin::OAuth2::ResourceServer::Error', 'future nbf' );
    is( $e->error, 'invalid_token', 'future nbf -> invalid_token' );
    is( $e->http_status, 401, 'future nbf -> 401' );
}
ok( engine->verify_token( token( nbf => time - 300 ) ), 'past nbf accepted' );

# nbf is OPTIONAL: the companion AuthorizationServer never mints one, so a
# token without nbf must still verify.
ok( engine->verify_token( token() ), 'absent nbf accepted (claim is optional)' );

# leeway applies to nbf as well as exp: just-not-yet-valid is tolerated inside
# the window, and still rejected outside it.
ok( engine( leeway => 30 )->verify_token( token( nbf => time + 10 ) ),
    'nbf inside leeway accepted' );
isa_ok(
    exception { engine( leeway => 30 )->verify_token( token( nbf => time + 300 ) ) },
    'Catalyst::Plugin::OAuth2::ResourceServer::Error',
    'nbf beyond leeway'
);

# --- iat (RFC 7519 4.1.6): validate-if-present, honouring leeway ---
{
    my $e = exception { engine->verify_token( token( iat => time + 300 ) ) };
    isa_ok( $e, 'Catalyst::Plugin::OAuth2::ResourceServer::Error', 'future iat' );
    is( $e->error, 'invalid_token', 'future iat -> invalid_token' );
}
ok( engine->verify_token( token( iat => time - 5 ) ), 'past iat accepted' );

# iat is OPTIONAL per RFC 7519, so an absent iat must not be a rejection.
ok( engine->verify_token( token() ), 'absent iat accepted (claim is optional)' );
ok( engine( leeway => 30 )->verify_token( token( iat => time + 10 ) ),
    'iat inside leeway accepted' );

# The claim shape the companion AuthorizationServer actually mints (iss, aud,
# iat, exp; no nbf) must verify: this pins RS/AS interop.
{
    my $now = time;
    my $as_token = encode_jwt(
        payload => {
            sub   => 'user-1',
            iss   => 'https://as.example',
            aud   => 'https://rs.example/mcp',
            iat   => $now,
            exp   => $now + 3600,
            scope => 'example:read',
        },
        alg => 'HS256',
        key => $KEY,
    );
    ok( engine->verify_token($as_token), 'a token shaped as the companion AS mints it verifies' );
}

# --- issuer matching is EXACT, not substring (Crypt::JWT: scalar verify_iss
# means string equality; a regex match would need a qr// ref) ---
{
    for my $iss ( 'https://as.exampleEVIL', 'https://as.example.evil.test',
        'evil-https://as.example', 'https://as.exampl' )
    {
        my $e = exception { engine->verify_token( token( iss => $iss ) ) };
        isa_ok( $e, 'Catalyst::Plugin::OAuth2::ResourceServer::Error',
            "iss '$iss' rejected" );
        is( $e->error, 'invalid_token', "iss '$iss' -> invalid_token" );
    }
    # ... and the exactly-equal issuer still passes
    ok( engine->verify_token( token( iss => 'https://as.example' ) ),
        'exactly-equal iss accepted' );
}

done_testing;
