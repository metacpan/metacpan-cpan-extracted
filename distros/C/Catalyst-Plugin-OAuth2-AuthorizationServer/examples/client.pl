use v5.36;
use HTTP::Tiny;
use JSON::PP;
use Digest::SHA qw/sha256/;
use MIME::Base64 qw/encode_base64url/;

my $base = shift // 'http://127.0.0.1:5000';
# HTTP::Tiny follows redirects by default (max_redirect => 5); disable that so
# we can read the code out of the 302 Location instead of it trying to fetch
# the (non-existent) https://app.example/cb redirect target itself.
my $http = HTTP::Tiny->new( max_redirect => 0 );
my $json = JSON::PP->new->canonical;

# 1) Dynamic client registration
my $reg = $http->post( "$base/oauth/register", {
    headers => { 'Content-Type' => 'application/json' },
    content => $json->encode( { redirect_uris => ['https://app.example/cb'] } ),
} );
die "register failed: $reg->{status} $reg->{content}\n" unless $reg->{success};
my $client_id = decode_json( $reg->{content} )->{client_id};
say "registered client_id=$client_id";

# 2) Authorize with PKCE (S256). Capture the code from the redirect Location.
# RFC 7636 4.1: 43-128 characters of [A-Za-z0-9._~-].
my $verifier  = 'example-code-verifier-0123456789-abcdefghijklm';
my $challenge = encode_base64url( sha256($verifier) );
my %q = (
    client_id             => $client_id,
    redirect_uri          => 'https://app.example/cb',
    response_type         => 'code',
    code_challenge        => $challenge,
    code_challenge_method => 'S256',
    scope                 => 'example:read',
    resource              => 'urn:example:resource',
    state                 => 'xyz',
);
my $qs = join '&', map { "$_=" . _uri_escape( $q{$_} ) } sort keys %q;
my $auth = $http->get( "$base/oauth/authorize?$qs" );
die "expected a redirect, got $auth->{status}\n" unless $auth->{status} == 302;
my ($code) = ( $auth->{headers}{location} =~ /[?&]code=([^&]+)/ );
say "got authorization code=$code";

# 3) Exchange the code for tokens (form-encoded)
my %form = (
    grant_type    => 'authorization_code',
    code          => $code,
    redirect_uri  => 'https://app.example/cb',
    code_verifier => $verifier,
);
my $body = join '&', map { "$_=" . _uri_escape( $form{$_} ) } sort keys %form;
my $tok = $http->post( "$base/oauth/token", {
    headers => { 'Content-Type' => 'application/x-www-form-urlencoded' },
    content => $body,
} );
die "token failed: $tok->{status} $tok->{content}\n" unless $tok->{success};
my $t = decode_json( $tok->{content} );
say "access_token (JWT): $t->{access_token}";
say "token_type=$t->{token_type} expires_in=$t->{expires_in} scope=$t->{scope}";

sub _uri_escape ($s) { $s =~ s/([^A-Za-z0-9_.~-])/sprintf '%%%02X', ord $1/ger }
