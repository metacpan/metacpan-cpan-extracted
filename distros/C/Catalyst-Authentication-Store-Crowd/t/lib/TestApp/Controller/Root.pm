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
        my $user = $c->user;
        $c->res->body( $c->user->info->{'first-name'} );
    } else {
        $c->res->body( 'fail' );
    }
}

1;
