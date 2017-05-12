#
# This file is part of CatalystX-ExtJS
#
# This software is Copyright (c) 2011 by Moritz Onken.
#
# This is free software, licensed under:
#
#   The (three-clause) BSD License
#
	package MyApp::Controller::Calculator;

	use Moose;
	BEGIN { extends 'Catalyst::Controller' };
	with 'CatalystX::Controller::ExtJS::Direct';

	use JSON::XS;
	
	sub add : Chained('/') : Path : CaptureArgs(1) {
		my($self,$c, $arg) = @_;
		$c->stash->{add} = $arg;
	}

	sub add_to : Chained('add') : PathPart('to') : Args(1) : Direct('add') {
		my($self,$c,$arg) = @_;
		$c->res->body( $c->stash->{add} + $arg );
	}
	
	sub echo : Local : Direct : DirectArgs(1) {
		my ($self, $c) = @_;
		$c->res->content_type('application/json');
		$c->res->body(encode_json($c->req->data));
	}