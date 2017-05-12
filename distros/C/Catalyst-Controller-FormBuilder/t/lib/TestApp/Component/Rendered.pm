package TestApp::Component::Rendered;

use strict;
use base 'Catalyst::View';

sub process {
    my ( $self, $c ) = @_;

    $c->response->body( $c->stash->{FormBuilder}->render() );
}

1;
