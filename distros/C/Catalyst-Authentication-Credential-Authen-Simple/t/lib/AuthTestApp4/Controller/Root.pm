package AuthTestApp4::Controller::Root;

use strict;
use warnings;

use parent 'Catalyst::Controller';

__PACKAGE__->config(namespace => '');

sub authed_ok : Local {
	my ( $self, $c ) = @_;

        my $authd = $c->authenticate( { "username" => $c->request->param('username'),
	                               "password" => $c->request->param('password') });

	if ($authd){
	    $c->response->body( "authed " . $c->user->get('name') );
	} else {
           $c->response->body( "not authed" );
	}

        $c->logout;
}

1;

