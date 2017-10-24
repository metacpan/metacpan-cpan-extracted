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
use Data::Dumper;
use JSON;
use Params::Validate qw(:all);
use Try::Tiny;

# methods/attributes not defined in this module will be inherited from:
use parent 'App::MFILE::WWW::Resource';



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

    { method: "LOGIN", path: "login", body: { nam: "foo", pwd: "bar" } }

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

    my ( $method, $path, $body );

    if ( exists $ajax->{'method'} ) {
        $method = $ajax->{'method'};
    } else {
        $log->crit( 'POST request received, but missing mandatory attribute "method" - ' .
                    'here is the entire request body: ' . Dumper( $ajax ) );
        return 0;
    }
    if ( exists $ajax->{'path'} and $ajax->{'path'} ) {
        $path = $ajax->{'path'};
    } else {
        $log->crit( 'POST request received, but missing mandatory attribute "path" - ' .
                    'here is the entire request body: ' . Dumper( $ajax ) );
        return 0;
    }
    $body = $ajax->{'body'} || {};

    $log->debug( "process_post: method $method, path $path, body " . Dumper $body );

    if ( ! $method or ! $path or ! $body ) {
        $log->crit( 'POST request received, but missing mandatory attribute(s) - ' .
                    'here is the entire request body: ' . Dumper( $ajax ) );
        return 0;
    }

    # two possibilities: login/logout attempt or normal AJAX call
    if ( $method =~ m/^LOGIN/i ) {
        $log->debug( "Incoming login/logout attempt" );
        if ( $path =~ m/^login/i ) {
            return $self->validate_user_credentials( $body );
        } else {
            return $self->_logout( $body );
        }
    }

    # - normal AJAX call
    $log->debug( "Calling rest_req $method $path on session ID " . $self->session_id );
    $session->{'last_seen'} = time;
    my $rr = $self->rest_req( {
        server => $site->DOCHAZKA_WWW_BACKEND_URI,
        method => $method,
        path => $path,
        req_body => $body,
    } );
    $log->debug( "rest_req returned: " . Dumper( $rr ) );
    my $hr = $rr->{'hr'};
    return $self->_prep_ajax_response( $hr, $rr->{'body'} );
}


=head2 validate_user_credentials

Called either from C<process_post> on login AJAX requests originating from the
JavaScript side (i.e. the login screen in login-dialog.js, via login.js), or
directly from C<is_authorized> if the MFILE_WWW_BYPASS_LOGIN_DIALOG mechanism
is activated.

Returns a status object - OK means the login was successful; all other statuses
mean unsuccessful.

=cut

sub validate_user_credentials {
    my ( $self, $body ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::validate_user_credentials()" );

    my $r = $self->request;
    my $session = $self->session;
    my $nick = $body->{'nam'};
    my $password = $body->{'pwd'};
    my $standalone = $meta->META_WWW_STANDALONE_MODE;

    $log->debug( "Employee $nick login attempt" );
    $log->debug( "DOCHAZKA_WWW_BACKEND_URI is " .  $site->DOCHAZKA_WWW_BACKEND_URI );

    my ( $code, $message, $body_json );
    my $rr = $self->rest_req( {
        server => $site->DOCHAZKA_WWW_BACKEND_URI,
        nick => $nick,
        password => $password,
        path => 'employee/self/full',
    } );
    $code = $rr->{'hr'}->code;
    $message = $rr->{'hr'}->message;
    $body_json = $rr->{'body'};

    my $status = $self->login_status( $code, $message, $body_json );
    $log->debug( "login_status() returned" . Dumper( $status ) );
    return $status;
}
         

=head2 _logout

Called from C<process_post> to process logout requests (special AJAX requests)
originating from the JavaScript side.

=cut

sub _logout {
    my ( $self ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_logout()" );

    my $rr = $self->rest_req( {
        server => $site->DOCHAZKA_WWW_BACKEND_URI,
        method => 'POST',
        path => 'session/terminate',
    } );
    if ( $rr->{'hr'}->code ne '200' ) {
        $log->error("session/terminate AJAX call FAILED: " . Dumper( $rr ) );
    };
    $self->request->{'env'}->{'psgix.session'} = {};

    #my $status = $CELL->status_ok( 'DOCHAZKA_WWW_LOGOUT_OK' );
    #$self->response->header( 'Content-Type' => 'application/json' );
    #$self->response->body( to_json( $status->expurgate ) );
    #return 1;

    my $hr = $rr->{'hr'};
    return $self->_prep_ajax_response( $hr, $rr->{'body'} );
}


=head3 _prep_ajax_response

=cut

sub _prep_ajax_response {
    my ( $self, $hr, $body ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_prep_ajax_response()" );
    $log->debug( "AJAX response body: " . Dumper( $body ) );
    my $expurgated_status;
    if ( $hr->is_success ) {
        $expurgated_status = $body;
    } else {
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

1;
