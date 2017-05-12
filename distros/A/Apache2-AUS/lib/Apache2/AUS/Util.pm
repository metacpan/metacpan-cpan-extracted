#!perl

package Apache2::AUS::Util;

use strict;
use warnings;
use Exporter;
use base q(Exporter);
use Apache2::RequestRec ();
use Apache2::RequestUtil ();
use Apache2::Connection ();
use Apache2::SubRequest ();
use Apache2::Log ();
use Apache2::Const qw(FORBIDDEN OK);
use CGI;
use CGI::Cookie;
use CGI::Session::AUS;
use Apache2::AUS::RequestRec;

our @EXPORT_OK = qw(
    create_session bake_session_cookie set_remote_user
    check_requirement auth_failure go
);

our %_requirements = (
    'valid-user'        =>      sub {
        $_[0] && $_[0]->{id}
    },
    'user-id'           =>      sub {
        my $u = shift;
        $u && grep { $u->{id} == $_ } @_;
    },
    'user-name'         =>      sub {
        my $u = shift;
        $u && grep { lc $u->{name} eq lc $_ } @_;
    },
    'flag'              =>      sub {
        my $u = shift;
        $u && grep { $u->permission($_) } @_;
    },
);

return 1;

sub session_cookie_key  { 'AUS_SESSION' }

sub create_session {
    my $r = shift;
    my $init = get_session_id($r);
    $init = CGI->new($r) unless $init;
    local $ENV{REMOTE_ADDR} = $r->connection->remote_ip();
    my $session = CGI::Session::AUS->new(undef, $init, undef);
    $session->param('_use_count', 0) unless $session->param('_use_count');
    return $session;
}

sub get_session_id {
    my $r = shift;
    my $key = session_cookie_key($r);
    
    if(my $cookie_jar = CGI::Cookie->fetch($r)) {
        if($cookie_jar->{$key}) {
            return $cookie_jar->{$key}->value;
        }
    }
    
    return;
}

sub bake_session_cookie {
    my($r, $session) = @_;
    my $key = session_cookie_key($r);
    return CGI::Cookie->new(-name => $key, -value => $session->id);
}

sub set_remote_user {
    my($r, $id) = @_;
    $r->main->user($id) if($r->main);
    $r->user($id);
    return $id;
}

# for an AND relationship, specify multiple "require" lines;
# for an OR relationship, specify space-separated arguements on one "require"
# line

sub check_requirement {
    my($r, $requirement) = @_;
    
    my $session = $r->aus_session or return;

    my($req, @args) = (@$requirement);
    $req = lc($req);
    
    if(my $test = $_requirements{$req}) {
        return $test->($session->user, @args) && 1;
    } else {
        $r->warn(qq{Unknown requirement "$req"; ignored.});
        return 1;
    }
}

sub auth_failure {
    my($r, $reason) = @_;
    $r->subprocess_env(AUS_AUTH_FAILURE => $reason);
    $r->log_reason($reason);
    $r->headers_out->set('WWW-Authenticate', "Cookie; uri=/");
    return FORBIDDEN;
}

sub go {
    my($r, $uri) = @_;
    $r->internal_redirect($uri);
    return OK;
}
