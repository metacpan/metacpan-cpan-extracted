use v5.36;
use Test::More;
use lib 't/lib';
use HTTP::Request::Common qw/GET POST/;
use JSON::MaybeXS qw/encode_json decode_json/;
use Digest::SHA qw/sha256/;
use MIME::Base64 qw/encode_base64url/;
use Crypt::JWT qw/decode_jwt/;

use Catalyst::Test 'TestApp';

my $KEY = 'integration-signing-key-0123456789';

# --- AS metadata ---
{
    my $res = request( GET '/.well-known/oauth-authorization-server' );
    ok( $res->is_success, 'metadata 200' );
    my $m = decode_json( $res->content );
    is_deeply( $m->{code_challenge_methods_supported}, ['S256'], 'S256 advertised' );
    is( $m->{registration_endpoint}, 'http://localhost/oauth/register',
        'registration endpoint' );
}

# --- DCR ---
my $client_id;
{
    my $res = request( POST '/oauth/register',
        'Content-Type' => 'application/json',
        Content => encode_json({ redirect_uris => ['https://app/cb'] }) );
    is( $res->code, 201, 'register 201' );
    $client_id = decode_json( $res->content )->{client_id};
    ok( $client_id, 'got client_id' );
}

# --- DCR rate-limit gate denies when the app says so ---
{
    my $res = request( POST '/oauth/register',
        'Content-Type' => 'application/json',
        'X-Deny-DCR'   => 1,
        Content => encode_json({ redirect_uris => ['https://app/cb'] }) );
    is( $res->code, 429, 'rate-limit gate -> 429' );
    is( decode_json( $res->content )->{error}, 'too_many_requests', 'error body' );
}

# --- authorize: our TestApp authn hook auto-consents as "user-1" and
#     redirects to redirect_uri?code=... ---
my $verifier  = 'the-code-verifier-value-0123456789012345678';
my $challenge = encode_base64url( sha256($verifier) );
my $code;
{
    my $res = request( GET '/oauth/authorize?'
        . "client_id=$client_id&redirect_uri=https://app/cb&response_type=code"
        . "&code_challenge=$challenge&code_challenge_method=S256"
        . '&scope=example:read&resource=https://rs/mcp&state=st1' );
    is( $res->code, 302, 'authorize redirects' );
    my $loc = $res->header('Location');
    like( $loc, qr{\Qhttps://app/cb\E\?code=}, 'redirect carries code' );
    like( $loc, qr/state=st1/, 'redirect carries state' );
    ($code) = $loc =~ /code=([^&]+)/;
    ok( $code, 'extracted code' );
}

# --- token: authorization_code grant ---
my $refresh;
{
    my $res = request( POST '/oauth/token', [
        grant_type   => 'authorization_code',
        code         => $code,
        redirect_uri => 'https://app/cb',
        code_verifier => $verifier,
    ] );
    is( $res->code, 200, 'token 200' );
    is( $res->header('Cache-Control'), 'no-store', 'no-store on token response' );
    my $tok = decode_json( $res->content );
    is( $tok->{token_type}, 'Bearer', 'Bearer' );
    my $claims = decode_jwt( token => $tok->{access_token}, key => $KEY );
    is( $claims->{sub}, 'user-1', 'access token sub' );
    is( $claims->{aud}, 'https://rs/mcp', 'aud' );
    $refresh = $tok->{refresh_token};
    ok( $refresh, 'refresh token present' );
}

# --- token: refresh grant rotates ---
{
    my $res = request( POST '/oauth/token', [
        grant_type => 'refresh_token', refresh_token => $refresh,
    ] );
    is( $res->code, 200, 'refresh 200' );
    isnt( decode_json( $res->content )->{refresh_token}, $refresh, 'rotated' );
}

# --- token: replaying an already-rotated refresh token is rejected
#     (RFC 9700 reuse detection). $refresh was consumed by the rotation
#     above, so presenting it again is a replay of a live-token family. ---
{
    my $res = request( POST '/oauth/token', [
        grant_type => 'refresh_token', refresh_token => $refresh,
    ] );
    is( $res->code, 400, 'replayed refresh token -> 400' );
    is( decode_json( $res->content )->{error}, 'invalid_grant',
        'replayed refresh token is invalid_grant' );
}

# --- token: bad grant -> OAuth error envelope ---
{
    my $res = request( POST '/oauth/token', [
        grant_type => 'authorization_code', code => 'nope',
        redirect_uri => 'https://app/cb', code_verifier => 'x',
    ] );
    is( $res->code, 400, 'bad code 400' );
    is( decode_json( $res->content )->{error}, 'invalid_grant', 'invalid_grant' );
}

# --- authorize error with a VALID client+redirect redirects with error params ---
{
    my $res = request( GET '/oauth/authorize?'
        . "client_id=$client_id&redirect_uri=https://app/cb&response_type=code"
        . "&code_challenge=$challenge&code_challenge_method=S256"
        . '&scope=bogus:scope&resource=https://rs/mcp&state=st2' );
    is( $res->code, 302, 'redirect-safe authorize error still 302s' );
    my $loc = $res->header('Location');
    like( $loc, qr{\Qhttps://app/cb\E\?}, 'redirects to the client redirect_uri' );
    like( $loc, qr/error=invalid_scope/, 'carries error=invalid_scope' );
    like( $loc, qr/state=st2/, 'carries state' );
}

# --- authorize error with an UNKNOWN client renders directly (no open redirect) ---
{
    my $res = request( GET '/oauth/authorize?'
        . 'client_id=ghost&redirect_uri=https://evil/cb&response_type=code'
        . "&code_challenge=$challenge&code_challenge_method=S256"
        . '&scope=example:read&resource=https://rs/mcp' );
    is( $res->code, 400, 'unknown client renders directly, never redirects' );
    is( decode_json( $res->content )->{error}, 'invalid_client',
        'invalid_client body' );
}

# oauth_issue_code with a bogus request_id renders a clean 400, not a 500
{
    my $res = request( GET '/test/issue-code?request_id=does-not-exist' );
    is( $res->code, 400, 'expired/unknown request_id -> 400 (not 500)' );
    is( decode_json( $res->content )->{error}, 'invalid_request',
        'invalid_request envelope, no backtrace leak' );
}

# missing grant_type -> invalid_request (not unsupported_grant_type)
{
    my $res = request( POST '/oauth/token', [ code => 'x' ] );
    is( $res->code, 400, 'missing grant_type -> 400' );
    is( decode_json( $res->content )->{error}, 'invalid_request',
        'missing grant_type is invalid_request' );
}

# --- duplicate parameters are rejected, not silently collapsed (RFC 6749 3.2.1) ---
{
    my $res = request( GET '/oauth/authorize?'
        . "client_id=$client_id&client_id=someone-else"
        . '&redirect_uri=https://app/cb&response_type=code'
        . "&code_challenge=$challenge&code_challenge_method=S256"
        . '&resource=https://rs/mcp&state=dup1' );
    is( $res->code, 400, 'duplicated client_id on authorize -> 400' );
    is( decode_json( $res->content )->{error}, 'invalid_request',
        'duplicated authorize param is invalid_request' );
}

# a duplicated redirect_uri must render directly: rejecting it happens before
# any validation, so it must never 302 to a client-supplied URI (open redirect)
{
    my $res = request( GET '/oauth/authorize?'
        . "client_id=$client_id&redirect_uri=https://app/cb"
        . '&redirect_uri=https://evil/cb&response_type=code'
        . "&code_challenge=$challenge&code_challenge_method=S256"
        . '&resource=https://rs/mcp&state=dup2' );
    is( $res->code, 400, 'duplicated redirect_uri -> 400, not a redirect' );
    is( $res->header('Location'), undef,
        'duplicated redirect_uri produces no Location header (no open redirect)' );
    is( decode_json( $res->content )->{error}, 'invalid_request',
        'duplicated redirect_uri is invalid_request' );
}

# same rule on the token endpoint (body parameters)
{
    my $res = request( POST '/oauth/token', [
        grant_type => 'authorization_code',
        grant_type => 'refresh_token',
        refresh_token => 'whatever',
    ] );
    is( $res->code, 400, 'duplicated grant_type on token -> 400' );
    is( decode_json( $res->content )->{error}, 'invalid_request',
        'duplicated token param is invalid_request' );
}

done_testing;
