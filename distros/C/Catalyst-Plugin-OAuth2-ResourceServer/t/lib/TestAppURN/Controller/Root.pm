package TestAppURN::Controller::Root;
use v5.36;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub secure :Path('/secure') :Args(0) {
    my ( $self, $c ) = @_;
    return unless $c->oauth_protect;
    $c->response->body('ok');
}

1;
