package TestApp::Controller::Root;
use v5.36;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub metadata :Path('/.well-known/oauth-protected-resource') :Args(0) {
    my ( $self, $c ) = @_;
    $c->oauth_protected_resource_metadata;
}

sub secure :Path('/secure') :Args(0) {
    my ( $self, $c ) = @_;
    return unless $c->oauth_protect;
    return unless $c->oauth_assert_scope('example:read');
    my $id = $c->oauth_identity->{id};
    $c->response->body( "ok:$id:" . join( ' ', $c->oauth_scopes ) );
}

sub secure_write :Path('/secure-write') :Args(0) {
    my ( $self, $c ) = @_;
    return unless $c->oauth_protect;
    return unless $c->oauth_assert_scope('example:themes:write');
    $c->response->body('ok');
}

1;
