package Example::OAuthAS::Controller::Root;
use v5.36;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub metadata :Path('/.well-known/oauth-authorization-server') :Args(0) {
    my ( $self, $c ) = @_;
    $c->oauth_metadata;
}

sub register :Path('/oauth/register') :Args(0) {
    my ( $self, $c ) = @_;
    $c->oauth_register;
}

sub authorize :Path('/oauth/authorize') :Args(0) {
    my ( $self, $c ) = @_;
    $c->oauth_authorize;
}

sub token :Path('/oauth/token') :Args(0) {
    my ( $self, $c ) = @_;
    $c->oauth_token;
}

__PACKAGE__->meta->make_immutable;

1;
