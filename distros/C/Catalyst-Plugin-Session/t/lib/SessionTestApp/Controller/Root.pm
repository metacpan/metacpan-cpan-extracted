package SessionTestApp::Controller::Root;
use strict;
use warnings;
use Data::Dumper;

use base qw/Catalyst::Controller/;

__PACKAGE__->config( namespace => '' );

sub login : Global {
    my ( $self, $c ) = @_;
    $c->session;
    $c->res->output("logged in");
}

sub login_without_address : Global {
    my ( $self, $c ) = @_;
    $c->session;
    $c->log->debug($c->request->address);
    delete $c->session->{__address};
    $c->res->output("logged in (without address)");
}

sub logout : Global {
    my ( $self, $c ) = @_;
    $c->res->output(
        "logged out after " . $c->session->{counter} . " requests" );
    $c->delete_session("logout");
}

sub logout_redirect : Global {
    my ( $self, $c ) = @_;

    $c->logout;
    $c->res->output("redirect from here");
    $c->res->redirect( $c->uri_for('from_logout_redirect') );
}

sub from_logout_redirect : Global {
    my ( $self, $c ) = @_;
    $c->res->output( "got here from logout_redirect" );
}

sub set_session_variable : Global {
    my ( $self, $c, $var, $val ) = @_;
    $c->session->{$var} = $val;
    $c->res->output("session variable set");
}

sub get_session_variable : Global {
    my ( $self, $c, $var ) = @_;
    my $val = $c->session->{$var} || 'n.a.';
    $c->res->output("VAR_$var=$val");
}

sub get_sessid : Global {
    my ( $self, $c ) = @_;
    my $sid = $c->sessionid || 'n.a.';
    $c->res->output("SID=$sid");
}

sub dump_session : Global {
    my ( $self, $c ) = @_;
    my $sid = $c->sessionid || 'n.a.';
    my $dump = Dumper($c->session || 'n.a.');
    $c->res->output("[SID=$sid]\n$dump");
}

sub change_sessid : Global {
    my ( $self, $c ) = @_;
    $c->change_session_id;
    $c->res->output("session id changed");
}

sub page : Global {
    my ( $self, $c ) = @_;
    if ( $c->session_is_valid ) {
        $c->res->output("you are logged in, session expires at " . $c->session_expires);
        $c->session->{counter}++;
    }
    else {
        $c->res->output("please login");
    }
}

sub user_agent : Global {
    my ( $self, $c ) = @_;
    $c->res->output('UA=' . $c->req->user_agent);
}

sub accessor_test : Global {
    my ( $self, $c ) = @_;

    $c->session(
        one => 1,
        two => 2,
    );

    $c->session( {
            three => 3,
            four => 4,
        },
    );

    $c->session->{five} = 5;

    for my $key (keys %{ $c->session }) {
        $c->res->write("$key: " . $c->session->{$key} . "\n");
    }
}

sub dump_these_loads_session : Global {
    my ($self, $c) = @_;

    $c->dump_these();
    if ($c->_session) {
        $c->res->write('LOADED')
    }
    else {
        $c->res->write('NOT');
    }
}

sub change_session_expires : Global {
    my ($self, $c) = @_;
    $c->change_session_expires(31536000);
    $c->res->output($c->session_expires);
}

sub reset_session_expires : Global {
    my ($self, $c) = @_;
    $c->reset_session_expires;
    $c->res->output($c->session_expires);
}

1;
