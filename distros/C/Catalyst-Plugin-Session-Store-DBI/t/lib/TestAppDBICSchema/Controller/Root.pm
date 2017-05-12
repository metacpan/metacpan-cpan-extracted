use strict;
use warnings;

package TestAppDBICSchema::Controller::Root;

use base 'Catalyst::Controller';

__PACKAGE__->config(namespace => '');

sub login : Global {
    my ( $self, $c ) = @_;
    $c->session;
    $c->res->output('logged in');
}

sub logout : Global {
    my ( $self, $c ) = @_;
    $c->res->output(
        'logged out after ' . $c->session->{counter} . ' requests' );
    $c->delete_session('logout');
}

sub page : Global {
    my ( $self, $c ) = @_;
    if ( $c->sessionid ) {
        $c->res->output('you are logged in');
        $c->session->{counter}++;
    }
    else {
        $c->res->output('please login');
    }
}

1;
