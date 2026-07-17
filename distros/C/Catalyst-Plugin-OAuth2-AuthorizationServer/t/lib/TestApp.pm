package TestApp;
use v5.36;
use URI;
use Catalyst qw/+Catalyst::Plugin::OAuth2::AuthorizationServer/;

our $VERSION = '0.001';

__PACKAGE__->config(
    'Catalyst::Plugin::OAuth2::AuthorizationServer' => {
        store                 => 'OAuthStore',     # resolved via $c->model
        signing_key           => 'integration-signing-key-0123456789',
        issuer                => 'http://localhost',
        resource              => 'https://rs/mcp',
        scopes_supported      => [ 'example:read', 'example:themes:write' ],
        authorize_endpoint    => 'http://localhost/oauth/authorize',
        token_endpoint        => 'http://localhost/oauth/token',
        registration_endpoint => 'http://localhost/oauth/register',
    },
);

# --- app-provided hooks (called by the plugin) ---

# authn/consent hook: a real app 302s to its SPA; here we auto-consent as
# user-1 and immediately mint + redirect with the code.
sub oauth_authenticate ( $c, $request_id ) {
    my $out = $c->oauth_issue_code( 'user-1', $request_id );
    return unless $out;
    my $uri = URI->new( $out->{redirect_uri} );
    $uri->query_form( code => $out->{code},
        ( defined $out->{state} ? ( state => $out->{state} ) : () ) );
    $c->response->redirect( $uri, 302 );
    return;
}

# optional DCR rate-limit gate: deny when the test sends X-Deny-DCR.
sub oauth_dcr_allow_registration ( $c ) {
    return $c->request->header('X-Deny-DCR') ? 0 : 1;
}

__PACKAGE__->setup;

1;
