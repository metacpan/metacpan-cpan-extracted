use v5.36;
use Test::More;
use Test::Fatal;
use lib 't/lib';
use StubStore;
use Digest::SHA qw/sha256/;
use MIME::Base64 qw/encode_base64url/;
use Crypt::JWT qw/decode_jwt/;

my $class = 'Catalyst::Plugin::OAuth2::AuthorizationServer::Server';
require_ok($class);

my $key = 'k' x 32;

# RFC 7636 4.1 code verifiers: 43-128 chars of [A-Za-z0-9._~-]
my $VERIFIER  = 'pkce-verifier-' . ( '0' x 29 );
my $VERIFIER2 = 'other-verifier-' . ( '1' x 28 );
my $CHALLENGE = encode_base64url( sha256($VERIFIER) );

sub fresh_engine { return $class->new(
    store => StubStore->new, signing_key => $key,
    issuer => 'https://as', resource => 'https://rs/mcp',
) }

# helper: drive authorize -> issue_code with a real PKCE pair
sub mint_code ( $eng, $verifier ) {
    my $challenge = encode_base64url( sha256($verifier) );
    $eng->store->create_client({
        client_id => 'c1', redirect_uris => ['https://app/cb'] });
    my $rid = $eng->validate_authorize({
        client_id => 'c1', redirect_uri => 'https://app/cb',
        response_type => 'code', code_challenge => $challenge,
        code_challenge_method => 'S256', scope => 'example:read',
        resource => 'https://rs/mcp',
    })->{request_id};
    return $eng->issue_code( 'user-9', $rid )->{code};
}

# happy path: code -> Bearer token (claims) + refresh token
{
    my $eng  = fresh_engine();
    my $code = mint_code( $eng, $VERIFIER );
    my $tok  = $eng->exchange_authorization_code({
        grant_type   => 'authorization_code',
        code         => $code,
        redirect_uri => 'https://app/cb',
        code_verifier => $VERIFIER,
    });
    is( $tok->{token_type}, 'Bearer', 'Bearer token_type' );
    is( $tok->{expires_in}, 900,      'expires_in = access_ttl' );
    is( $tok->{scope},      'example:read', 'scope echoed' );
    ok( length $tok->{refresh_token}, 'refresh token issued' );

    my $claims = decode_jwt( token => $tok->{access_token}, key => $key );
    is( $claims->{sub},   'user-9',          'sub claim' );
    is( $claims->{aud},   'https://rs/mcp',  'aud = resource' );
    is( $claims->{scope}, 'example:read',      'scope claim' );
}

# PKCE mismatch -> invalid_grant
{
    my $eng  = fresh_engine();
    my $code = mint_code( $eng, $VERIFIER );
    my $e = exception { $eng->exchange_authorization_code({
        code => $code, redirect_uri => 'https://app/cb',
        code_verifier => $VERIFIER2,
    }) };
    is( $e->error, 'invalid_grant', 'PKCE mismatch rejected' );
}

# replayed code -> invalid_grant (single-use)
{
    my $eng  = fresh_engine();
    my $code = mint_code( $eng, $VERIFIER );
    $eng->exchange_authorization_code({
        code => $code, redirect_uri => 'https://app/cb', code_verifier => $VERIFIER });
    my $e = exception { $eng->exchange_authorization_code({
        code => $code, redirect_uri => 'https://app/cb', code_verifier => $VERIFIER }) };
    is( $e->error, 'invalid_grant', 'code replay rejected' );
}

# redirect_uri mismatch -> invalid_grant
{
    my $eng  = fresh_engine();
    my $code = mint_code( $eng, $VERIFIER );
    my $e = exception { $eng->exchange_authorization_code({
        code => $code, redirect_uri => 'https://evil/cb', code_verifier => $VERIFIER }) };
    is( $e->error, 'invalid_grant', 'redirect mismatch rejected' );
}

# refresh rotation: new pair issued, old refresh token revoked
{
    my $eng  = fresh_engine();
    my $code = mint_code( $eng, $VERIFIER );
    my $first = $eng->exchange_authorization_code({
        code => $code, redirect_uri => 'https://app/cb', code_verifier => $VERIFIER });
    my $rt = $first->{refresh_token};

    my $second = $eng->refresh({
        grant_type => 'refresh_token', refresh_token => $rt });
    ok( length $second->{access_token}, 'refresh yields a new access token' );
    isnt( $second->{refresh_token}, $rt, 'refresh token rotated' );

    my $e = exception { $eng->refresh({ refresh_token => $rt }) };
    is( $e->error, 'invalid_grant', 'reused refresh token rejected' );
}

# access-token aud is restricted to the AUTHORIZED resource, not all configured
{
    my $eng = $class->new(
        store => StubStore->new, signing_key => $key,
        issuer => 'https://as', resource => [ 'https://rs/mcp', 'https://rs/other' ],
    );
    $eng->store->create_client({ client_id => 'c1', redirect_uris => ['https://app/cb'] });
    my $challenge = encode_base64url( sha256($VERIFIER) );
    my $rid = $eng->validate_authorize({
        client_id => 'c1', redirect_uri => 'https://app/cb', response_type => 'code',
        code_challenge => $challenge, code_challenge_method => 'S256',
        scope => 'example:read', resource => 'https://rs/mcp',
    })->{request_id};
    my $code = $eng->issue_code( 'user-9', $rid )->{code};
    my $tok = $eng->exchange_authorization_code({
        code => $code, redirect_uri => 'https://app/cb', code_verifier => $VERIFIER });
    my $claims = decode_jwt( token => $tok->{access_token}, key => $key );
    is( $claims->{aud}, 'https://rs/mcp',
        'aud restricted to the authorized resource, not all configured' );
}

# token request with a mismatched client_id -> invalid_grant
{
    my $eng  = fresh_engine();
    my $code = mint_code( $eng, $VERIFIER );
    my $e = exception { $eng->exchange_authorization_code({
        client_id => 'someone-else', code => $code,
        redirect_uri => 'https://app/cb', code_verifier => $VERIFIER }) };
    is( $e->error, 'invalid_grant', 'client_id mismatch rejected' );
}

# expired authorization code -> invalid_grant (engine honours the Store's expiry)
{
    my $eng = fresh_engine();
    $eng->store->create_auth_code( 'old-code',
        { client_id => 'c1', subject => 'u', redirect_uri => 'https://app/cb',
          code_challenge => $CHALLENGE, scope => 'example:read', resource => 'https://rs/mcp' },
        time - 1 );
    my $e = exception { $eng->exchange_authorization_code({
        code => 'old-code', redirect_uri => 'https://app/cb', code_verifier => $VERIFIER }) };
    is( $e->error, 'invalid_grant', 'expired code rejected' );
}

# expired refresh token -> invalid_grant
{
    my $eng = fresh_engine();
    $eng->store->create_refresh_token( $eng->_hash_token('raw-rt'),
        { client_id => 'c1', subject => 'u', scope => 'example:read',
          resource => 'https://rs/mcp' },
        time - 1 );
    my $e = exception { $eng->refresh({ refresh_token => 'raw-rt' }) };
    is( $e->error, 'invalid_grant', 'expired refresh token rejected' );
}

# missing code_verifier -> invalid_grant
{
    my $eng  = fresh_engine();
    my $code = mint_code( $eng, $VERIFIER );
    my $e = exception { $eng->exchange_authorization_code({
        code => $code, redirect_uri => 'https://app/cb' }) };
    is( $e->error, 'invalid_grant', 'absent code_verifier rejected' );
}

# refresh with a mismatched client_id -> invalid_grant
{
    my $eng  = fresh_engine();
    my $code = mint_code( $eng, $VERIFIER );
    my $first = $eng->exchange_authorization_code({
        code => $code, redirect_uri => 'https://app/cb', code_verifier => $VERIFIER });
    my $e = exception { $eng->refresh({
        refresh_token => $first->{refresh_token}, client_id => 'someone-else' }) };
    is( $e->error, 'invalid_grant', 'refresh client_id mismatch rejected' );
}

# no scope requested -> token response omits scope, JWT has no scope claim
{
    my $eng = fresh_engine();
    $eng->store->create_client({ client_id => 'c1', redirect_uris => ['https://app/cb'] });
    my $challenge = encode_base64url( sha256($VERIFIER) );
    my $rid = $eng->validate_authorize({
        client_id => 'c1', redirect_uri => 'https://app/cb', response_type => 'code',
        code_challenge => $challenge, code_challenge_method => 'S256',
        resource => 'https://rs/mcp',   # no scope
    })->{request_id};
    my $code = $eng->issue_code( 'u', $rid )->{code};
    my $tok  = $eng->exchange_authorization_code({
        code => $code, redirect_uri => 'https://app/cb', code_verifier => $VERIFIER });
    ok( !exists $tok->{scope}, 'token response omits scope when none requested' );
    my $claims = decode_jwt( token => $tok->{access_token}, key => $key );
    ok( !exists $claims->{scope}, 'JWT omits scope claim when none requested' );
}

# RFC 7636 4.1: the verifier must be 43-128 chars of the unreserved set.
# Each code below is minted FROM the bad verifier, so its S256 challenge would
# otherwise match: these pin the format check, not the hash comparison.
{
    my %bad = (
        too_short     => 'a' x 42,
        too_long      => 'a' x 129,
        plus_char     => ( 'a' x 42 ) . '+',
        slash_char    => ( 'a' x 42 ) . '/',
        space_char    => ( 'a' x 42 ) . ' ',
        equals_char   => ( 'a' x 42 ) . '=',
    );
    for my $name ( sort keys %bad ) {
        my $eng  = fresh_engine();
        my $code = mint_code( $eng, $bad{$name} );
        my $e = exception { $eng->exchange_authorization_code({
            code => $code, redirect_uri => 'https://app/cb',
            code_verifier => $bad{$name} }) };
        isa_ok( $e, 'Catalyst::Plugin::OAuth2::AuthorizationServer::Error',
            "malformed code_verifier ($name)" );
        is( $e->error, 'invalid_grant', "$name code_verifier rejected" );
    }
}

# the RFC 7636 boundary lengths still round-trip end to end
{
    for my $len ( 43, 128 ) {
        my $v    = 'a' x $len;
        my $eng  = fresh_engine();
        my $code = mint_code( $eng, $v );
        my $tok  = $eng->exchange_authorization_code({
            code => $code, redirect_uri => 'https://app/cb',
            code_verifier => $v });
        ok( length $tok->{access_token},
            "a $len-char code_verifier is accepted" );
    }
}

# every character of the unreserved set is accepted
{
    my $v    = ( 'A' x 39 ) . '._~-';
    my $eng  = fresh_engine();
    my $code = mint_code( $eng, $v );
    my $tok  = $eng->exchange_authorization_code({
        code => $code, redirect_uri => 'https://app/cb', code_verifier => $v });
    ok( length $tok->{access_token},
        'the unreserved characters . _ ~ - are accepted in a code_verifier' );
}

done_testing;
