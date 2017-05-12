package TestApp::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

sub default : Path {
    my ( $self, $c ) = @_;
    $c->response->status( 404 );
    $c->detach;
}

sub end : Private { }

1;
