package TestApp::Controller::Root;
use strict;
use warnings;

__PACKAGE__->config(namespace => q{});

use base 'Catalyst::Controller';

sub main :Path { }

sub nothtml :Local {
  my ($self, $c) = @_;
  $c->res->content_type('application/json');
}

sub render : ActionClass('RenderView') { }

sub end : ActionClass('Fixup::XHTML') {
	my ( $self, $c ) = @_;
	
	$c->forward('render');
}

1;
