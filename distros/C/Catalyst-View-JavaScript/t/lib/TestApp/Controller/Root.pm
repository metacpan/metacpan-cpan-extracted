package 
  TestApp::Controller::Root;
our $VERSION = '0.995';

use strict;
use warnings;
use base 'Catalyst::Controller';

__PACKAGE__->config->{namespace} = '';

sub auto :Private {
    my ( $self, $c ) = @_;
	$c->view('JavaScript')->copyright("");
	$c->view('JavaScript')->stash(1);
	$c->view('JavaScript')->key("js");
	$c->view('JavaScript')->compress(1);
	$c->view('JavaScript')->output(0);
	# defaults set	
	return 1;
}

sub decompress :Local {
	my ( $self, $c ) = @_;
	$c->view('JavaScript')->compress(0);
	$c->stash->{js} = "var foo = 2;";
}

sub compress :Local {
	my ( $self, $c ) = @_;
	$c->stash->{js} = "var foo = 2;";
}

sub copyright :Local {
	my ( $self, $c ) = @_;
	$c->view('JavaScript')->copyright("foobar");
	$c->stash->{js} = "var foo = 1;";
}

sub body :Local {
	my ( $self, $c ) = @_;
	$c->view('JavaScript')->output(1);
	$c->res->body("var foo = 2;");
}

sub key :Local {
	my ( $self, $c ) = @_;
	$c->view('JavaScript')->key("bar");
	$c->stash->{bar} = "var foo = 1;";
}

sub end : Private {
	my ( $self, $c ) = @_;
	$c->detach($c->view('JavaScript'));
}

1;
