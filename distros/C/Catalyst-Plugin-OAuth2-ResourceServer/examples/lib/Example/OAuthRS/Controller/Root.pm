package Example::OAuthRS::Controller::Root;
use v5.36;
use Moose;
use namespace::autoclean;
use JSON::PP ();

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

# oauth_protect verifies the Bearer token and writes a 401/403 itself (returning
# false) if it is missing/invalid/insufficient, so guard with an early return.
sub whoami :Path('/api/whoami') :Args(0) {
    my ( $self, $c ) = @_;
    return unless $c->oauth_protect;
    return unless $c->oauth_assert_scope('example:read');
    $c->response->content_type('application/json');
    $c->response->body(
        JSON::PP->new->canonical->encode( {
            subject => $c->oauth_identity->{id},
            scopes  => [ $c->oauth_scopes ],
        } )
    );
}

__PACKAGE__->meta->make_immutable;

1;
