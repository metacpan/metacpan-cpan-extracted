use v5.42;
use Test2::V0;
use At;
use JSON::PP     qw[encode_json];
use MIME::Base64 qw[encode_base64];
use Crypt::PK::ECC;

# Build an expired-looking access JWT (payload is what resume() decodes; the
# signature is never verified here)
sub make_token {
    my (%claims) = @_;
    my $json     = encode_json( { sub => 'did:plc:test', iat => time - 3660, exp => time - 60, %claims } );
    my $b64      = encode_base64( $json, '' );
    $b64 =~ tr[+/][-_];
    $b64 =~ s/=+$//;
    "eyJhbGciOiJFUzI1NiJ9.$b64.fakesig";
}
my $key = Crypt::PK::ECC->new;
$key->generate_key('secp256r1');
my $jwk_private = $key->export_key_jwk('private');
subtest 'resume refreshes an expired DPoP access token even with an opaque refresh token' => sub {
    my $at   = At->new( host => 'bsky.social' );
    my $http = $at->http;
    my ( $set_access, $set_type, $set_key );
    my $http_mock = mock $http => (
        override => [
            post => sub {
                my ( $self, $url, $args ) = @_;
                is $url, 'https://as.example/token', 'token endpoint hit';
                return { access_token => 'new-access-token', refresh_token => 'new-refresh-token', sub => 'did:plc:test', scope => 'atproto' };
            },
            set_tokens => sub {
                my ( $self, $acc, $ref, $type, $key ) = @_;
                ( $set_access, $set_type, $set_key ) = ( $acc, $type, $key );
                return $self;
            }
        ]
    );
    my $at_mock = mock $at => (
        override => [
            oauth_discover => sub {
                return { pds => 'https://pds.example', metadata => { token_endpoint => 'https://as.example/token' } };
            },
        ]
    );
    my $access = make_token();
    my $ret
        = $at->resume( $access, 'opaque-refresh-token', 'DPoP', $jwk_private, 'http://localhost/client', 'atperl.bsky.social', 'https://pds.example',
        'atproto' );
    ok $ret, 'resume returns the refreshed user agent';
    is $set_access, 'new-access-token', 'set_tokens received the refreshed access token';
    is $set_type,   'DPoP',             'token type preserved';
    ok $set_key, 'dpop key re-bound';
    is $at->session->accessJwt,  'new-access-token',  'session holds the refreshed token';
    is $at->session->refreshJwt, 'new-refresh-token', 'session holds the refreshed refresh token';
};
subtest 'resume clears the session when refresh cannot proceed' => sub {
    my $at      = At->new( host => 'bsky.social' );
    my $at_mock = mock $at => (
        override => [
            oauth_discover => sub { return undef },

            # session() is lazy and falls back to a network fetch; keep it local
            get => sub { return undef }
        ]
    );
    my $ret
        = $at->resume( make_token(), 'opaque-refresh-token', 'DPoP', $jwk_private, 'cid', 'atperl.bsky.social', 'https://pds.example', 'atproto' );
    ok !$ret,                 'resume returns false when refresh cannot proceed';
    ok !defined $at->session, 'expired session not left in place';
};
subtest 'resume does not refresh a still-valid access token' => sub {
    my $at         = At->new( host => 'bsky.social' );
    my $http       = $at->http;
    my $refreshed  = 0;
    my $http_mock2 = mock $http => (
        override => [
            post => sub {
                $refreshed++;
                return { access_token => 'new-access-token', refresh_token => 'new-refresh-token', sub => 'did:plc:test', scope => 'atproto' };
            },
            set_tokens => sub ( $self, $acc, $ref, $type, $key ) {
                return $self;
            },
        ]
    );
    my $at_mock2 = mock $at => (
        override => [
            oauth_discover => sub {
                return { pds => 'https://pds.example', metadata => { token_endpoint => 'https://as.example/token' } };
            },
        ]
    );
    my $json = encode_json( { sub => 'did:plc:test', iat => time - 60, exp => time + 3600 } );
    my $b64  = encode_base64( $json, '' );
    $b64 =~ tr[+/][-_];
    $b64 =~ s/=+$//;
    my $fresh_access = "eyJhbGciOiJFUzI1NiJ9.$b64.fakesig";
    $at->resume( $fresh_access, 'opaque-refresh-token', 'DPoP', $jwk_private, undef, undef, undef, undef );
    is $refreshed,              0,             'no refresh attempted while access token is valid';
    is $at->session->accessJwt, $fresh_access, 'original access token kept';
};
#
done_testing;
