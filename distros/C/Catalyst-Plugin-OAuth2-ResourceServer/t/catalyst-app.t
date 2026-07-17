use v5.36;
use Test::More;
use lib 't/lib';
use HTTP::Request::Common qw/GET/;
use JSON::MaybeXS qw/decode_json/;
use Crypt::JWT qw/encode_jwt/;

use Catalyst::Test 'TestApp';

my $KEY = 'resource-server-secret-key-0123456789';

sub token (%claims) {
    return encode_jwt(
        payload => {
            sub => 'user-1', aud => 'https://rs/mcp', iss => 'https://as',
            scope => 'example:read', exp => time + 60, %claims,
        },
        alg => 'HS256', key => $KEY,
    );
}
sub authget ( $path, $tok ) {
    my @h = defined $tok ? ( Authorization => "Bearer $tok" ) : ();
    return request( GET $path, @h );
}

# --- protected route: valid token passes, identity + scope available ---
{
    my $res = authget( '/secure', token() );
    is( $res->code, 200, 'valid bearer -> 200' );
    is( $res->content, 'ok:user-1:example:read', 'identity + scope visible to action' );
}

# --- the Bearer scheme name is case-insensitive (RFC 7235) ---
{
    my $res = request( GET '/secure', Authorization => 'bearer ' . token() );
    is( $res->code, 200, 'lowercase "bearer" accepted' );
}

# --- missing token -> 401 plain challenge (no error=) + resource_metadata ---
{
    my $res = authget( '/secure', undef );
    is( $res->code, 401, 'missing token -> 401' );
    my $wa = $res->header('WWW-Authenticate');
    like( $wa, qr/^Bearer/, 'Bearer challenge' );
    like( $wa, qr/resource_metadata="[^"]+"/, 'carries resource_metadata' );
    # TestApp configures resource_metadata_url explicitly; the override is used
    # verbatim rather than derived from the resource (which would have given
    # https://rs/.well-known/oauth-protected-resource/mcp).
    like( $wa, qr{resource_metadata="\Qhttps://rs/.well-known/oauth-protected-resource\E"},
        'configured resource_metadata_url wins over derivation' );
    unlike( $wa, qr/error=/, 'no error= for a missing token' );
    is( $res->header('Cache-Control'), 'no-store', 'no-store' );
}

# --- bad token -> 401 with error="invalid_token" ---
{
    my $res = authget( '/secure', 'garbage' );
    is( $res->code, 401, 'bad token -> 401' );
    like( $res->header('WWW-Authenticate'), qr/error="invalid_token"/, 'invalid_token' );
}

# --- resolver rejects (subject not active) -> 401 ---
{
    my $res = authget( '/secure', token( sub => 'inactive' ) );
    is( $res->code, 401, 'resolver-rejected subject -> 401' );
    unlike( $res->header('WWW-Authenticate'), qr/error_description=/,
        'no account-state leak in the resolver-reject challenge' );
}

# --- insufficient scope -> 403 ---
{
    my $res = authget( '/secure-write', token() );   # only has example:read
    is( $res->code, 403, 'missing required scope -> 403' );
    like( $res->header('WWW-Authenticate'),
        qr/error="insufficient_scope"/, 'insufficient_scope' );
    like( $res->header('WWW-Authenticate'),
        qr/scope="example:themes:write"/, 'names the required scope' );
}

# --- RFC 9728 protected-resource metadata ---
{
    my $res = request( GET '/.well-known/oauth-protected-resource' );
    is( $res->code, 200, 'metadata 200' );
    my $m = decode_json( $res->content );
    is( $m->{resource}, 'https://rs/mcp', 'resource' );
    is_deeply( $m->{authorization_servers}, ['https://as'], 'authorization_servers' );
    is_deeply( $m->{bearer_methods_supported}, ['header'], 'bearer methods' );
    is_deeply( $m->{scopes_supported}, [ 'example:read', 'example:themes:write' ],
        'scopes_supported advertised' );
    is( $res->header('Cache-Control'), 'no-store', 'metadata no-store' );
}

# malformed Bearer attempt -> invalid_request 400 (not a bare 401)
{
    my $res = request( GET '/secure', Authorization => 'Bearer' );  # scheme, no token
    is( $res->code, 400, 'malformed Bearer -> 400' );
    like( $res->header('WWW-Authenticate'), qr/error="invalid_request"/,
        'invalid_request' );
}
# a non-Bearer scheme -> bare 401 (no error code, RFC 6750 section 3)
{
    my $res = request( GET '/secure', Authorization => 'Basic Zm9vOmJhcg==' );
    is( $res->code, 401, 'non-Bearer scheme -> 401' );
    unlike( $res->header('WWW-Authenticate'), qr/error=/, 'no error= for wrong scheme' );
}
# array-valued scope claim is honoured
{
    my $res = authget( '/secure', token( scope => ['example:read'] ) );
    is( $res->code, 200, 'array scope claim accepted' );
}
# a die in oauth_resolve_subject -> clean 500 server_error (not an unhandled 500)
{
    my $res = authget( '/secure', token( sub => 'boom' ) );
    is( $res->code, 500, 'resolver die -> 500' );
    is( eval { decode_json( $res->content )->{error} } // '', 'server_error',
        'generic server_error body, no leak' );
}
# The resolver hook is handed the verified claims, so its exception text must
# not reach the log. TestApp's resolver dies with "resolver boom".
{
    my $log = '';
    open my $fh, '>', \$log or die "in-memory filehandle: $!";
    my $old = select $fh;    ## no critic (ProhibitOneArgSelect)
    {
        local *STDERR = $fh;
        authget( '/secure', token( sub => 'boom' ) );
    }
    select $old;             ## no critic (ProhibitOneArgSelect)
    close $fh;

    unlike( $log, qr/resolver boom/,
        'resolver exception text never reaches the log' );
    like( $log, qr/oauth_resolve_subject died/,
        'the fixed diagnostic string is still logged' );
}

done_testing;
