package Example::OAuthRS;
use v5.36;
use Catalyst qw/+Catalyst::Plugin::OAuth2::ResourceServer/;

our $VERSION = '0.001';

# The resource identifier is an http(s) URI, so the RFC 9728 metadata URL in
# 401 challenges is derived automatically as
# http://localhost:5000/.well-known/oauth-protected-resource/api. A URN (or any
# other non-hierarchical scheme) is not derivable and would need an explicit
# resource_metadata_url instead.
__PACKAGE__->config(
    'Catalyst::Plugin::OAuth2::ResourceServer' => {
        signing_key           => 'example-resource-server-signing-key-0123456789',
        resource              => 'http://localhost:5000/api',
        issuer                => 'http://localhost:5000',
        authorization_servers => ['http://localhost:5000'],
        scopes_supported      => [ 'example:read', 'example:write' ],
    },
);

# Turn the verified token's subject claim into an app identity. Return a truthy
# value to allow the request, or undef to reject with a 401.
sub oauth_resolve_subject ( $c, $claims ) {
    return { id => $claims->{sub} };
}

__PACKAGE__->setup;

1;
