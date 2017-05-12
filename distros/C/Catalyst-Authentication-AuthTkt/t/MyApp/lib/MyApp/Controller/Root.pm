package MyApp::Controller::Root;
use Moose;

BEGIN { extends 'Catalyst::Controller' }

__PACKAGE__->config( namespace => '' );

has auth_url => (
    is       => 'ro',
    required => 1,
);

no Moose;

use Data::Dump qw( dump );

sub debug_session_and_user {
    my ( $self, $c ) = @_;

    $c->log->debug( dump $c->session ) if $c->debug;  # trigger session id set

    $c->log->debug(
        "user = " . ( $c->user ? $c->user->id : '[ no user in $c ]' ) )
        if $c->debug;

}

sub auto : Private {
    my ( $self, $c ) = @_;

    # validate the ticket and update ticket and session if necessary
    if ( $c->authenticate ) {
        $c->log->debug("authn ok") if $c->debug;
        $self->debug_session_and_user($c);
        return 1;
    }
    else {
        $c->log->debug("authn failed") if $c->debug;
        $self->debug_session_and_user($c);
    }

    # no valid login found so redirect.
    $c->response->redirect( $self->auth_url );

    # tell Catalyst to abort processing.
    return 0;
}

sub default : Private {
    my ( $self, $c ) = @_;
    $c->response->body('default page');
}

sub end : Private {
    my ( $self, $c ) = @_;
    if ( $c->user_exists ) {
        $c->response->body( "Logged in as user "
                . $c->user->id
                . ' with roles '
                . dump $c->user->roles );
    }
}

1;
