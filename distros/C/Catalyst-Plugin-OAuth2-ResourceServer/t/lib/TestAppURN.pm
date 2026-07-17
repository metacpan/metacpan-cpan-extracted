package TestAppURN;
use v5.36;
use Catalyst qw/+Catalyst::Plugin::OAuth2::ResourceServer/;

our $VERSION = '0.001';

# A resource identifier that is NOT an http(s) URI and no resource_metadata_url
# override: the RFC 9728 well-known path is not derivable, so the challenge must
# omit resource_metadata rather than emit a malformed one.
__PACKAGE__->config(
    'Catalyst::Plugin::OAuth2::ResourceServer' => {
        signing_key           => 'resource-server-secret-key-0123456789',
        resource              => 'urn:example:resource',
        issuer                => 'https://as',
        authorization_servers => ['https://as'],
    },
);

__PACKAGE__->setup;

1;
