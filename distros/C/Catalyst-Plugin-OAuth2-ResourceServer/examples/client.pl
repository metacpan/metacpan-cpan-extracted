use v5.36;
use HTTP::Tiny;
use Crypt::JWT qw/encode_jwt/;

# These MUST match the app config (examples/lib/Example/OAuthRS.pm).
my $KEY      = 'example-resource-server-signing-key-0123456789';
my $ISSUER   = 'http://localhost:5000';
my $RESOURCE = 'http://localhost:5000/api';

# A key the app does NOT know about: a token signed with this fails signature
# verification, so the RS rejects it with an invalid_token error.
my $WRONG_KEY = 'a-different-wrong-signing-key-0123456789';

my $base = shift // 'http://127.0.0.1:5000';
my $http = HTTP::Tiny->new;

my %payload = (
    sub   => 'demo-user',
    aud   => $RESOURCE,
    iss   => $ISSUER,
    scope => 'example:read',
    exp   => time + 300,
);

# Mint a bearer token the way an authorization server would (HS256, same key).
my $token = encode_jwt( payload => {%payload}, alg => 'HS256', key => $KEY );

# Same claims, but signed with the wrong key: a valid-looking JWT whose HS256
# signature will not verify against the app's signing_key.
my $wrong_token =
    encode_jwt( payload => {%payload}, alg => 'HS256', key => $WRONG_KEY );

sub call ( $label, $tok ) {
    my %headers = ( defined $tok ? ( Authorization => "Bearer $tok" ) : () );
    my $res = $http->get( "$base/api/whoami", { headers => \%headers } );
    say sprintf '%-14s -> HTTP %s %s',
        $label,
        $res->{status},
        ( length $res->{content} ? $res->{content} : '' );
    return $res;
}

# 1) A valid token is accepted (200 + the resolved subject/scopes).
my $r_valid = call( 'valid token', $token );
# 2) A wrong-key token fails signature verification (401 invalid_token).
my $r_wrong = call( 'wrong token', $wrong_token );
# 3) No token at all is a bare 401 (no error body).
my $r_none = call( 'no token', undef );

my $ok_valid = $r_valid->{status} == 200;
my $ok_wrong = $r_wrong->{status} == 401
    && $r_wrong->{content} =~ /"error"\s*:\s*"invalid_token"/;
my $ok_none = $r_none->{status} == 401;

exit( $ok_valid && $ok_wrong && $ok_none ? 0 : 1 );
