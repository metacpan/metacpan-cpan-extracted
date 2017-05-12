package TestApp::Controller::Root;

use strict;
use warnings;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub loc : Local {
    my ( $self, $c ) = @_;
	$c->languages( ['es'] );
    $c->response->body( $c->loc('silly') );
}

sub end : ActionClass('RenderView') {}

1;
