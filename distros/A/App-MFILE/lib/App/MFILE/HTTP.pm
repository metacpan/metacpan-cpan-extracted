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

Module where C<rest_req> resides.



=head1 EXPORTS

=cut

our @EXPORT_OK = qw( rest_req );




=head1 FUNCTIONS


=head2 init_ua

Initialize a LWP::UserAgent singleton object.

Takes two _mandatory_ parameters:

    - a LWP::UserAgent object
    - a scalar (filename of cookie jar)

=cut

sub init_ua {
    # process arguments
    my ( $ua, $cj ) = validate_pos( @_,
        { type => HASHREF, can => 'cookie_jar' },
        { type => SCALAR },
    );
    $ua->cookie_jar( { file => $cj } );
    return;
}


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

