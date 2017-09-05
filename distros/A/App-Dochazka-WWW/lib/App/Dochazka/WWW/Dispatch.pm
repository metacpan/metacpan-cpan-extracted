# *************************************************************************
# Copyright (c) 2014-2017, SUSE LLC
#
# All rights reserved.
#
# Redistribution and use in source and binary forms, with or without
# modification, are permitted provided that the following conditions are met:
#
# 1. Redistributions of source code must retain the above copyright notice,
# this list of conditions and the following disclaimer.
#
# 2. Redistributions in binary form must reproduce the above copyright
# notice, this list of conditions and the following disclaimer in the
# documentation and/or other materials provided with the distribution.
#
# 3. Neither the name of SUSE LLC nor the names of its contributors may be
# used to endorse or promote products derived from this software without
# specific prior written permission.
#
# THIS SOFTWARE IS PROVIDED BY THE COPYRIGHT HOLDERS AND CONTRIBUTORS "AS IS"
# AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE
# IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE
# ARE DISCLAIMED. IN NO EVENT SHALL THE COPYRIGHT HOLDER OR CONTRIBUTORS BE
# LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR
# CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF
# SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS
# INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN
# CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE)
# ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE
# POSSIBILITY OF SUCH DAMAGE.
# *************************************************************************

# ------------------------
# This package defines how our web server handles the request-response 
# cycle. All the "heavy lifting" is done by Web::Machine and Plack.
# ------------------------

package App::Dochazka::WWW::Dispatch;

use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use App::MFILE::HTTP qw( rest_req );
use Data::Dumper;
use File::Temp qw( tempfile );
use JSON;
use LWP::UserAgent;
use Params::Validate qw(:all);
use Try::Tiny;

# methods/attributes not defined in this module will be inherited from:
use parent 'App::MFILE::WWW::Resource';

our $ualt = {};  # user agent lookup table



=head1 NAME

App::MFILE::WWW::Dispatch - app dispatch stub




=head1 SYNOPSIS

TBD



=head1 DESCRIPTION

This is where we override the default version of the is_authorized method
defined by L<Web::Machine::Resource>.

This module is only used in standalone mode. In derived distribution mode, the
application's dispatch module will be used, instead.

=cut




=head1 METHODS


=head2 is_authorized

Since all requests go through this function at a fairly early stage, we 
leverage it to validate the session. 

=cut

sub is_authorized {
    my ( $self ) = @_;

    $log->debug( "Entering " . __PACKAGE__ . "::is_authorized()" );

    my $r = $self->request;
    my $session = $self->session;
    my $remote_addr = $r->{'env'}->{'REMOTE_ADDR'};
    my $ce;

    #$log->debug( "Environment is " . Dumper( $r->{'env'} ) );
    $log->debug( "Session is " . Dumper( $session ) );

    # authorized session
    if ( $ce = $session->{'currentUser'} and
         $session->{'ip_addr'} and
         $session->{'ip_addr'} eq $remote_addr and
         _is_fresh( $session ) )
    {
        $log->debug( "is_authorized: Authorized session, employee " . $ce->{'nick'} );
        $session->{'last_seen'} = time;
        return 1;
    }

    # login attempt
    if ( $r->method eq 'POST' and 
         $self->context->{'request_body'} and 
         $self->context->{'request_body'}->{'method'} and
         $self->context->{'request_body'}->{'method'} =~ m/^LOGIN/i ) {
        $log->debug( "is_authorized: Login attempt - pass it on" );
        return 1;
    }

    # login bypass
    $meta->set('META_LOGIN_BYPASS_STATE', 0) if not defined $meta->META_LOGIN_BYPASS_STATE;
    if ( $site->MFILE_WWW_BYPASS_LOGIN_DIALOG and not $meta->META_LOGIN_BYPASS_STATE ) {
        $log->notice("Bypassing login dialog! Using default credentials");
        $session->{'ip_addr'} = $remote_addr;
        $session->{'last_seen'} = time;
        my $bypass_result = $self->_login_dialog( {
            'nam' => $site->MFILE_WWW_DEFAULT_LOGIN_CREDENTIALS->{'nam'},
            'pwd' => $site->MFILE_WWW_DEFAULT_LOGIN_CREDENTIALS->{'pwd'},
        } );
        $meta->set('META_LOGIN_BYPASS_STATE', 1);
        return $bypass_result;
    }

    # unauthorized session
    $log->debug( "is_authorized fall-through: " . $r->method . " " . $self->request->path_info );
    return 1;
}


=head2 ua

Returns the LWP::UserAgent object obtained from the lookup table.
Creates it first if necessary.

=cut

sub ua {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::ua()" );
    my $id = $self->session_id;
    $log->debug( "ua: session_id is $id" );

    # already in lookup table
    if ( exists $ualt->{$id} ) {
         $log->debug( "Session $id already has a LWP::UserAgent object" );
         return $ualt->{$id};
    }

    # not in lookup table yet
    my $tf = "";
    ( undef, $tf ) = tempfile();
    $ualt->{$id} = LWP::UserAgent->new;
    $ualt->{$id}->cookie_jar({ file => $tf });
    $log->info("New user agent created with cookies in $tf");
    return $ualt->{$id};
}


=head2 process_post

POST requests are assumed to be AJAX calls. Their entity bodies must be valid
JSON with the following simple structure:

    { method: HTTP_METHOD, path: RESOURCE, body: BODY_JSON }

where HTTP_METHOD is any HTTP method accepted by the REST server, RESOURCE is a
valid path to a REST server resource, and BODY_JSON is the content body to be
sent in the HTTP request to the REST server. Provided the request is properly
authorized and the body is well-formed, the request is forwarded to the REST
server via the L<App::MFILE> package's C<rest_req> routine and the REST
server's response is sent back to the user's browser, where it is processed by
the JavaScript code.

In derived-distro mode, this structure is expected to be translated into a
"real" HTTP request, to be forwarded via the LWP::UserAgent object stored in
the session data. The status object received in the response is then passed
back to the JavaScript side.

There is one special case: the POST request from the login dialog looks like this:

    { method: "LOGIN", path: "login", body: { nam: 'nick', pwd: 'kcin" } }

Login requests receive special handling.

=cut

sub process_post {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::process_post()" );

    my $r = $self->request;
    my $session = $self->session;
    my $ajax = $self->context->{'request_body'};  # request body (Perl string)

    if ( ! $ajax ) {
        $log->crit( 'POST request received, but without a body' );
        return 0;
    }

    my $method = $ajax->{'method'};
    my $path = $ajax->{'path'};
    my $body = $ajax->{'body'} || {};

    $log->debug( "process_post: method $method, path $path, body " . Dumper $body );

    if ( ! $method or ! $path or ! $body ) {
        $log->crit( 'POST request received, but missing mandatory attribute(s) - ' .
                    'here is the entire request body: ' . Dumper( $ajax ) );
        return 0;
    }

    # two possibilities: login/logout attempt or normal AJAX call
    # - login/logout attempt
    if ( $method =~ m/^LOGIN/i ) {
        if ( $path =~ m/^login/i ) {
            return $self->_login_dialog( $body );
        } else {
            return $self->_logout( $body );
        }
    }

    # - normal AJAX call (shown for didactic purposes only; App::MFILE::WWW
    #   itself doesn't generate any AJAX calls)
    $log->debug( "Calling rest_req $method $path on session ID " . $self->session_id );
    $session->{'last_seen'} = time;
    my $rr = rest_req( $self->ua(), {
        server => $site->DOCHAZKA_WWW_BACKEND_URI,
        method => $method,
        path => $path,
        req_body => $body,
    } );
    $log->debug( "rest_req returned: " . Dumper( $rr ) );
    my $hr = $rr->{'hr'};
    return $self->_prep_ajax_response( $hr, $rr->{'body'} );
}


sub _login_dialog {
    my ( $self, $body ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_login_dialog()" );

    my $r = $self->request;
    my $session = $self->session;
    my $nick = $body->{'nam'};
    my $password = $body->{'pwd'};
    my $standalone = $meta->META_WWW_STANDALONE_MODE;

    $log->debug( "Employee $nick login attempt" );
    $log->debug( "DOCHAZKA_WWW_BACKEND_URI is " .  $site->DOCHAZKA_WWW_BACKEND_URI );

    my ( $code, $message, $body_json );
    my $rr = rest_req( $self->ua(), {
        server => $site->DOCHAZKA_WWW_BACKEND_URI,
        nick => $nick,
        password => $password,
        path => 'employee/self/full',
    } );
    $code = $rr->{'hr'}->code;
    $message = $rr->{'hr'}->message;
    $body_json = $rr->{'body'};

    my $status;
    if ( $code == 200 ) {
        $session->{'ip_addr'} = $r->{'env'}->{'REMOTE_ADDR'};
        $session->{'currentUser'} = $body_json->{'payload'}->{'emp'};
        $session->{'currentUserPriv'} = $body_json->{'payload'}->{'priv'};
        $session->{'last_seen'} = time;
        $log->debug( 
            "Login successful, currentUser is now " . 
            Dumper( $body_json->{'payload'}->{'emp'} ) .
            " and privilege level is " . $body_json->{'payload'}->{'priv'}
        );
        return 1 if $site->MFILE_WWW_BYPASS_LOGIN_DIALOG and ! $meta->META_LOGIN_BYPASS_STATE;
        $status = $CELL->status_ok( 'MFILE_WWW_LOGIN_OK', payload => $body_json->{'payload'} );
    } else {
        $session = {};
        $log->debug( "Login unsuccessful, reset session" );
        return 0 if $site->MFILE_WWW_BYPASS_LOGIN_DIALOG and ! $meta->META_LOGIN_BYPASS_STATE;
        $status = $CELL->status_not_ok( 
            'MFILE_WWW_LOGIN_FAIL: %s', 
            args => [ $code ],
            payload => { code => $code, message => $message },
        );
    }
    $self->response->header( 'Content-Type' => 'application/json' );
    $self->response->body( to_json( $status->expurgate ) );
    return 1;
}
         
sub _logout {
    my ( $self, $body ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_logout()" );
    my $rr = rest_req( $self->ua(), {
        server => $site->DOCHAZKA_WWW_BACKEND_URI,
        method => 'POST',
        path => 'session/terminate',
    } );
    if ( $rr->{'hr'}->code ne '200' ) {
        $log->error("session/terminate AJAX call FAILED: " . Dumper( $rr ) );
    };
    $self->request->{'env'}->{'psgix.session'} = {};
    $self->response->header( 'Content-Type' => 'application/json' );
    $self->response->body( to_json( $CELL->status_ok( 'MFILE_WWW_LOGOUT_OK' )->expurgate ) );
    return 1;
}

sub _prep_ajax_response {
    my ( $self, $hr, $body ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_prep_ajax_response()" );
    my $expurgated_status;
    if ( $hr->is_success ) {
        $expurgated_status = $body;
    } else {
        $log->debug( "AJAX response body: " . Dumper( $body ) );
        $expurgated_status = $CELL->status_err( 
            $body->{'code'},
            payload => { code => $hr->code, message => $body->{'text'} },
        )->expurgate;
    }
    $self->response->header('Content-Type' => 'application/json; charset=UTF-8' );
    $self->response->header('Content-Encoding' => 'UTF-8' );
    $self->response->body( JSON->new->encode( $expurgated_status ) );
    return 1;
}

=head3 _is_fresh

=cut

sub _is_fresh {
    my ( $session ) = validate_pos( @_, { type => HASHREF } );

    return 0 unless my $last_seen = $session->{'last_seen'};

    return ( time - $last_seen > $site->MFILE_WWW_SESSION_EXPIRATION_TIME )
        ? 0
        : 1;
}


1;
