package TestAppCDBI;

use strict;
use Catalyst;
use FindBin;

our $VERSION = '0.01';

__PACKAGE__->config(
    name    => __PACKAGE__,
    'Plugin::Session' => {
        expires => 3600,
        dbi_dbh => 'TestAppCDBI::Model::CDBI',
    }
);

__PACKAGE__->setup(qw/Session Session::Store::DBI Session::State::Cookie/);

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
