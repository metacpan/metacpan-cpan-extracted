package TestApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';


sub default : Private {
    my ( $self, $c ) = @_;
    $c->response->body( 'top' );
}


1;
