package TestDirectoryDispatch::Controller::Root;

use strict;
use warnings;
use base qw/Catalyst::Controller/;

__PACKAGE__->config->{namespace} = '';

sub base : Chained('/') PathPart('base') CaptureArgs(0) {
	my ( $self, $c ) = @_;
}

sub default : Private {
	my ( $self, $c ) = @_;
	
	$c->response->body( $c->welcome_message );
}


1;