package TestApp::Controller::Root;

use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

sub auth :Path('/auth') {
    my ( $self, $c ) = @_;
    if ( $c->authenticate( {
        username => $c->req->param('username'),
        password => $c->req->param('password'),
    } ) ){
        $c->res->body( 'pass' );
    } else {
        $c->res->body( 'fail - ' . $c->stash->{'auth_error_msg'} );
    }
}

1;
