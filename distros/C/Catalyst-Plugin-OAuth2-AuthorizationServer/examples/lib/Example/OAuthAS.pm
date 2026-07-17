package Example::OAuthAS;
use v5.36;
use URI;
use Catalyst qw/+Catalyst::Plugin::OAuth2::AuthorizationServer/;

our $VERSION = '0.001';

__PACKAGE__->config(
    'Catalyst::Plugin::OAuth2::AuthorizationServer' => {
        store                 => 'Store',   # resolved via $c->model('Store')
        signing_key           => 'example-authorization-server-signing-key-0123456789',
        issuer                => 'http://localhost:5000',
        resource              => 'urn:example:resource',
        scopes_supported      => [ 'example:read', 'example:write' ],
        authorize_endpoint    => 'http://localhost:5000/oauth/authorize',
        token_endpoint        => 'http://localhost:5000/oauth/token',
        registration_endpoint => 'http://localhost:5000/oauth/register',
    },
);

# The plugin calls this after a valid /authorize request. A real app would render
# a login + consent page; this example auto-consents as a fixed demo user, mints
# the code, and redirects back to the client with it.
sub oauth_authenticate ( $c, $request_id ) {
    my $out = $c->oauth_issue_code( 'demo-user', $request_id );
    return unless $out;
    my $uri = URI->new( $out->{redirect_uri} );
    $uri->query_form(
        code => $out->{code},
        ( defined $out->{state} ? ( state => $out->{state} ) : () ),
    );
    $c->response->redirect( $uri, 302 );
    return;
}

__PACKAGE__->setup;

1;
