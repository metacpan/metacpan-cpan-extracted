package AuthTestApp3::Controller::Root;

use strict;
use warnings;

use Test::More;
use Test::Exception;

use parent 'Catalyst::Controller';

__PACKAGE__->config(namespace => '');

sub authed_ko : Local {
	my ( $self, $c ) = @_;

	ok(!$c->user, "no user");
        my $authd = $c->authenticate( { "username" => $c->request->param('username'),
	                               "password" => $c->request->param('password') });
	ok(not($authd), "not logged in");
	ok(!$c->user, "user object not present");

	if ($authd){
	    $c->response->body( "authed" );
	} else {
            $c->response->body( "not authed" );
	}

        $c->logout;
	ok(!$c->user, "no user");
}

sub authed_ok : Local {
	my ( $self, $c ) = @_;

	ok(!$c->user, "no user");
        my $authd = $c->authenticate( { "username" => $c->request->param('username'),
	                               "password" => $c->request->param('password') });
	ok($authd, "logged in");
	ok(defined($c->user->get('name')), "user object is ok");

	if ($authd){
	    $c->response->body( "authed " . $c->user->get('name') );
	} else {
            $c->response->body( "not authed" );
	}

        $c->logout;
	ok(!$c->user, "no user");
}

1;
