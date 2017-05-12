package TestApp;

use strict;
use Catalyst;
use Data::Dumper;

TestApp->config( $ENV{TESTAPP_CONFIG} );

TestApp->setup( @{$ENV{TESTAPP_PLUGINS}} );

sub user_login : Global {
    my ( $self, $c ) = @_;

    $c->login;

    if ( $c->user_exists ) {
        if ( $c->req->params->{detach} ) {
            $c->detach( $c->req->params->{detach} );
        }
        $c->res->body( 'logged in' );
    }
    else {
        $c->res->body( 'not logged in' );
    }
}

sub user_logout : Global {
    my ( $self, $c ) = @_;

    $c->logout;

    if ( ! $c->user ) {
        $c->res->body( 'logged out' );
    }
    else {
        $c->res->body( 'not logged ok' );
    }
}

sub user_login_session : Global {
    my ( $self, $c ) = @_;

    if ( $c->req->params->{username} && $c->req->params->{password} ) {
        $c->login(
            $c->req->params->{username},
            $c->req->params->{password}
        );

        if ( $c->user_exists ) {
            $c->res->body( $c->session->{__user} );
        }
        else {
            $c->res->body( 'not logged in' );
        }
    }
}

sub get_session_user : Global {
    my ( $self, $c ) = @_;

    if ( $c->session->{__user} ) {
        $c->res->body( $c->session->{__user} );
    }
}

sub is_admin : Global {
    my ( $self, $c ) = @_;

    if ( $c->check_user_roles( 'admin' ) ) {
        $c->res->body( 'ok' );
    }
}

sub is_admin_user : Global {
    my ( $self, $c ) = @_;

    if ( $c->check_user_roles( qw/admin user/ ) ) {
        $c->res->body( 'ok' );
    }
}

sub set_usersession : Global {
    my ( $self, $c, $value ) = @_;
    $c->user_session->{foo} = $value;
    $c->res->body( 'ok' );
}

sub get_usersession : Global {
    my ( $self, $c ) = @_;
    $c->res->body( $c->user_session->{foo} || '' );
}

1;
