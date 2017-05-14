package SessionExpiry::Controller::Root;
use strict;
use warnings;

use base qw/Catalyst::Controller/;

__PACKAGE__->config( namespace => '' );

sub session_data_expires : Global {
    my ( $self, $c ) = @_;
    $c->session;
    if (my $sid = $c->sessionid) {
        $c->finalize_headers(); # force expiration to be updated
        $c->res->output($c->get_session_data("expires:$sid"));
    }
}

sub session_expires : Global {
    my ($self, $c) = @_;
    $c->session;
    $c->res->output($c->session_expires);
}

sub update_session : Global {
    my ($self, $c) = @_;
    $c->session->{foo} ++;
    $c->res->output($c->session->{foo});
}
