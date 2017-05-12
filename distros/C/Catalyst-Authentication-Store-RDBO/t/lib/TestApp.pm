package TestApp;

use strict;
use Catalyst;
use Data::Dumper;

TestApp->config( $ENV{TESTAPP_CONFIG} );

TestApp->setup( @{$ENV{TESTAPP_PLUGINS}} );

sub user_login : Global {
    my ( $self, $c ) = @_;

    ## this allows anyone to login regardless of status.
    eval {
        $c->authenticate({ username => $c->request->params->{'username'},
                           password => $c->request->params->{'password'}
                         });
        1;
    } or do {
        return $c->res->body($@);
    };

    if ( $c->user_exists ) {
        if ( $c->req->params->{detach} ) {
            $c->detach( $c->req->params->{detach} );
        }
        $c->res->body( $c->user->get('username') . ' logged in' );
    }
    else {
        $c->res->body( 'not logged in' );
    }
}


sub notdisabled_login : Global {
    my ( $self, $c ) = @_;

    $c->authenticate({ username => $c->request->params->{'username'},
                       password => $c->request->params->{'password'},
                       status => [ 'active', 'registered' ]
                     });

    if ( $c->user_exists ) {
        if ( $c->req->params->{detach} ) {
            $c->detach( $c->req->params->{detach} );
        }
        $c->res->body( $c->user->get('username') .  ' logged in' );
    }
    else {
        $c->res->body( 'not logged in' );
    }
}

sub searchargs_login : Global {
    my ( $self, $c ) = @_;

    my $username = $c->request->params->{'username'} || '';
    my $email = $c->request->params->{'email'} || '';
    
    $c->authenticate({ 
                        password => $c->request->params->{'password'},
                        rdbo => {
                            searchargs => [
                                    or => [
                                        username => $username,
                                        email    => $email,
                                ],
                            ]
                        }
                     });

    if ( $c->user_exists ) {
        if ( $c->req->params->{detach} ) {
            $c->detach( $c->req->params->{detach} );
        }
        $c->res->body( $c->user->get('username') .  ' logged in' );
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

sub get_session_user : Global {
    my ( $self, $c ) = @_;
 
    if ( $c->user_exists ) {
        $c->res->body($c->user->get('username')); # . " " . Dumper($c->user->get_columns()) );
    }
}

sub is_admin : Global {
    my ( $self, $c ) = @_;

    eval {
        if ( $c->assert_user_roles( qw/admin/ ) ) {
            $c->res->body( 'ok' );
        }
    };
    if ($@) {
        $c->res->body( 'failed' );
    }
}

sub is_admin_user : Global {
    my ( $self, $c ) = @_;

    eval {
        if ( $c->assert_user_roles( qw/admin user/ ) ) {
            $c->res->body( 'ok' );
        }
    };
    if ($@) {
        $c->res->body( 'failed' );
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
