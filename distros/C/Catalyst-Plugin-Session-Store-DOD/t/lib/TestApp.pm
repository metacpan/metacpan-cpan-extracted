package TestApp;

use strict;
use Catalyst;
use FindBin;
use TestApp::M::Session;

our $VERSION = '0.01';

__PACKAGE__->config(
    name    => __PACKAGE__,
    session => {
        expires => 3600,
        model   => "TestApp::M::Session"
    }
);

__PACKAGE__->setup(qw/Session Session::Store::DOD Session::State::Cookie/);

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
