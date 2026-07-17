package TestApp;
use v5.36;
use Catalyst qw/+Catalyst::Plugin::OAuth2::ResourceServer/;

our $VERSION = '0.001';

__PACKAGE__->config(
    'Catalyst::Plugin::OAuth2::ResourceServer' => {
        signing_key           => 'resource-server-secret-key-0123456789',
        resource              => 'https://rs/mcp',
        issuer                => 'https://as',
        authorization_servers => ['https://as'],
        scopes_supported      => [ 'example:read', 'example:themes:write' ],
        resource_metadata_url => 'https://rs/.well-known/oauth-protected-resource',
    },
);

# app subject resolver: load + re-validate the subject; undef => 401.
sub oauth_resolve_subject ( $c, $claims ) {
    die "resolver boom\n" if ( $claims->{sub} // '' ) eq 'boom';
    return undef if ( $claims->{sub} // '' ) eq 'inactive';
    return { id => $claims->{sub} };
}

__PACKAGE__->setup;

1;
