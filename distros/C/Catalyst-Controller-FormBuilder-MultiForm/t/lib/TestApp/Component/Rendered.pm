# This TestApp is used with permission from Juan Camacho, and is from the 0.03 
# release of his Catalyst::Controller::FormBuilder module

package TestApp::Component::Rendered;

use strict;
use base 'Catalyst::View';

sub process {
    my ( $self, $c ) = @_;

    $c->response->body( $c->stash->{FormBuilder}->render() );
}

1;
