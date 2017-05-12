package TestApp::Controller::Root;

use strict;
use base qw/Catalyst::Controller/;

__PACKAGE__->config( namespace => '' );

sub upload : Local {
    my ( $self, $c ) = @_;

    $c->res->output( 'ok' );
}

1;
