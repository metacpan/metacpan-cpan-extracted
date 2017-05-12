package TestApp::Controller::Root;

use Moose;
use namespace::autoclean;
use utf8;
use Encode;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config(namespace => '');

sub default : Private {
	my ($self, $c) = @_;

	$c->stash->{message} = "Amy, do you like magic?";
	$c->stash->{template} = "default.html";
}

sub encoding : Local {
	my ($self, $c) = @_;

	$c->stash->{message} = "מי שלא שותה לא משתין";
	$c->stash->{template} = "encoding.html";
}

sub end : Private {
	my ($self, $c) = @_;

	$c->forward( $c->view('Tenjin') );

	$c->res->body(Encode::encode('UTF-8', $c->res->body));
}

__PACKAGE__->meta->make_immutable;
