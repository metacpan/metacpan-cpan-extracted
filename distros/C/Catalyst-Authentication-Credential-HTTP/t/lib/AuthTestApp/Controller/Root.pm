package AuthTestApp::Controller::Root;
use strict;
use warnings;

use base qw/ Catalyst::Controller /;

__PACKAGE__->config( namespace => '' );

sub auto : Private {
    my ($self, $c) = @_;
    $c->authenticate();
}
sub moose : Local {
    my ( $self, $c ) = @_;
    $c->res->body( $c->user->id );
}

1;

