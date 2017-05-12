package TestApp::Controller::Root;

use strict;
use base 'Catalyst::Controller';

__PACKAGE__->config( namespace => '' );

sub end : Private {
    my ($self,$c) = @_;
}

1;
