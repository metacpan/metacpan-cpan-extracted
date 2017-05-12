package TestApp::Controller::Root;
use strict;
use warnings;
use base qw/Catalyst::Controller/;

__PACKAGE__->config( namespace => '' );

sub start_session : Local {
    my ( $self, $c ) = @_;
    $c->session->{counter} = 1;
    $c->res->body($c->stash->{_session}->{id});
}

sub page : Local {
    my ( $self, $c, $id ) = @_;
    $c->stash ( '_session' => {id => $id} );
    $c->res->body( "Hi! hit number " . ++$c->session->{counter} );
}

sub stream : Local {
    my ( $self, $c, $id ) = @_;
    $c->stash ( '_session' => {id => $id} );
    my $count = ++$c->session->{counter};
    $c->res->body("hit number $count");
}

sub deleteme : Local {
    my ( $self, $c, $id ) = @_;
    $c->stash ( '_session' => {id => $id} );
    my $id2 = $c->get_session_id;
    $c->delete_session;
    my $id3 = $c->get_session_id;

    # In the success case, print 'Pass'
    if (defined $id2 &&
        defined $id3 &&
        $id2 ne $id3
    ) {
        $c->res->body('PASS');
    } else {
        #In the failure case, provide debug info
        $id3 ||= '';
        $c->res->body("FAIL: Matching ids, $id3");
    }
}

1;
