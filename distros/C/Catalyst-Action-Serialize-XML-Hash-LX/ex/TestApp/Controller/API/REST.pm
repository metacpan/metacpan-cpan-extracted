package # hide
	TestApp::Controller::API::REST;

use utf8;
use strict;
use warnings;
use Moose;

BEGIN {
    extends 'Catalyst::Controller::REST';
}


__PACKAGE__->config(
	default => 'text/xml',
	
	map => {
		'text/xml' => [ 'XML::Hash::LX', { attr => '.' } ] ,
	},
);

sub chain : Chained PathPart('api/rest') CaptureArgs(0) {
	my ( $self, $c ) = @_;
	return 1;
	$c->response->status(403);
	$c->response->body('Access denied.');
	$c->detach;
	return 0;
}

sub test : Chained('chain') : PathPart('test') : Args(0) : ActionClass('REST') {}

sub test_POST {
	my ( $self, $c ) = @_;
	warn Dump + $c->request->data;
	$c->stash->{rest} = { my => [{ '.test' => 1},'value'] };
	
	return;
}

1;
