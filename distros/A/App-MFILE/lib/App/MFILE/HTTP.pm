# ************************************************************************* 
# Copyright (c) 2014, SUSE LLC
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
#
# HTTP module
#
package App::MFILE::HTTP;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $site $meta );
use Data::Dumper;
use Encode qw( encode_utf8 );
use Exporter qw( import );
use HTTP::Request::Common qw( GET PUT POST DELETE );
use JSON;
use LWP::UserAgent;
use Params::Validate qw( :all );
use Try::Tiny;



=head1 NAME

App::MFILE::HTTP - general REST request forwarder for MFILE-based clients



=head1 SYNOPSIS

    use App::MFILE::HTTP qw( rest_req );



=head1 DESCRIPTION

Module where C<rest_req> and other shared code resides.



=head1 EXPORTS

=cut

our @EXPORT_OK = qw(
    rest_req
    _is_authorized
);



=head1 FUNCTIONS


=head2 rest_req

Algorithm: send request to REST server, get JSON response, decode it, return it.

Takes a single _mandatory_ parameter: a LWP::UserAgent object

Optionally takes PARAMHASH:

    server => [URI OF REST SERVER]         default is 'http://0:5000'
    method => [HTTP METHOD TO USE]         default is 'GET'
    nick => [NICK FOR BASIC AUTH]          optional
    password => [PASSWORD FOR BASIC AUTH]  optional
    path => [PATH OF REST RESOURCE]        default is '/'
    req_body => [HASHREF]                  optional

Returns HASHREF containing:

    hr => HTTP::Response object (stripped of the body)
    body => [BODY OF HTTP RESPONSE, IF ANY] 

=cut

sub rest_req {

    # process arguments
    my $ua = shift;
    die "Bad user agent object" unless ref( $ua ) eq 'LWP::UserAgent';
    my %ARGS = validate( @_, {
        server =>   { type => SCALAR,  default => 'http://localhost:5000' },
        method =>   { type => SCALAR,  default => 'GET', regex => qr/^(GET|POST|PUT|DELETE)$/ },
        nick =>     { type => SCALAR,  optional => 1 },
        password => { type => SCALAR,  default => '' },
        path =>     { type => SCALAR,  default => '/' },
        req_body => { type => HASHREF, optional => 1 },
    } );
    $ARGS{'path'} =~ s/^\/*/\//;

    my $r;
    {
        no strict 'refs';
        $r = &{ $ARGS{'method'} }( $ARGS{'server'} . encode_utf8( $ARGS{'path'} ), 
                Accept => 'application/json' );
    }

    if ( $ARGS{'nick'} ) {
        $r->authorization_basic( $ARGS{'nick'}, $ARGS{'password'} );
    }

    if ( $ARGS{'method'} =~ m/^(POST|PUT)$/ ) {
        $r->header( 'Content-Type' => 'application/json' );
        if ( my $body = $ARGS{'req_body'} ) {
            my $tmpvar = JSON->new->utf8(0)->encode( $body );
            $r->content( encode_utf8( $tmpvar ) );
        }
    }

    # request is ready - send it and get response
    my $response = $ua->request( $r );

    # process response
    my $body_json = $response->decoded_content;
    $log->debug( "rest_req: decoded JSON body " . Dumper $body_json );
    $response->content('');
    my $body;
    try {
        $body = JSON->new->decode( $body_json );
    } catch {
        $body = { 'code' => $body, 'text' => $body };
    };

    return { 
        hr => $response,
        body => $body
    };
}


=head2 _is_authorized

This function does the actual work for C<is_authorized> in the Dispatch.pm
module of an C<App::MFILE::WWW>-based application.

This function belongs in Dispatch.pm - it is here only to prevent code
duplication.

=cut

sub _is_authorized {
    my ( $self ) = @_;

    $log->debug( "Entering " . __PACKAGE__ . "::_is_authorized()" );

    my $r = $self->request;
    #my $session = $r->{'env'}->{'psgix.session'};
    my $session = $self->session;
    #my $remote_addr = $r->{'env'}->{'REMOTE_ADDR'};
    my $remote_addr = $self->remote_addr;
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
    return ( $r->method eq 'GET' ) ? 1 : 0;
}


=head2 _is_fresh

Takes a single argument, the PSGI session, which is assumed to contain a
C<last_seen> attribute containing the number of seconds since epoch when the
session was last seen.

=cut

sub _is_fresh {
    my ( $session ) = validate_pos( @_, { type => HASHREF } );

    return 0 unless my $last_seen = $session->{'last_seen'};

    return ( time - $last_seen > $site->MFILE_WWW_SESSION_EXPIRATION_TIME )
        ? 0
        : 1;
}


1;
