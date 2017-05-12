package AuthTestApp::Controller::Root;
use strict;
use warnings;

use base qw/ Catalyst::Controller /;

__PACKAGE__->config( namespace => '' );

sub auto : Private {
    my ($self, $c) = @_;
    #$c->authenticate(); TODO: Put a valid signature here
}
sub moose : Local {
    my ( $self, $c ) = @_;
    $c->res->body( $c->user );
}

1;

