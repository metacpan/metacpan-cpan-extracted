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

# ------------------------
# This package defines how our web server handles the request-response 
# cycle. All the "heavy lifting" is done by Web::Machine and Plack.
# ------------------------

package App::MFILE::WWW::Resource;

use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use App::MFILE::HTTP qw( rest_req );
use Data::Dumper;
use Encode qw( decode_utf8 );
use JSON;
use LWP::UserAgent;
use Params::Validate qw(:all);
use Try::Tiny;

# methods/attributes not defined in this module will be inherited from:
use parent 'Web::Machine::Resource';



=head1 NAME

App::MFILE::WWW::Resource - HTTP request/response cycle




=head1 SYNOPSIS

In PSGI file:

    use Web::Machine;

    Web::Machine->new(
        resource => 'App::MFILE::WWW::Resource',
    )->to_app;




=head1 DESCRIPTION

This is where we override the default versions of various methods defined by
L<Web::Machine::Resource>.

=cut




=head1 METHODS


=head2 context

This method is where we store data that needs to be shared among
routines in this module.

=cut

sub context {
    my $self = shift;
    $self->{'context'};
}


=head2 session

=cut

sub session {
    my $self = shift;
    return $self->request->{'env'}->{'psgix.session'};
}


=head2 session_id

=cut

sub session_id {
    my $self = shift;
    return $self->request->{'env'}->{'psgix.session.options'}->{'id'};
}


=head2 service_available

This is the first method called on every incoming request.

=cut

sub service_available {
    my $self = shift;
    $log->debug( "Entering " . __PACKAGE__ . "::service_available()" );
    $log->info( "Incoming " . $self->request->method . " request for " . $self->request->path_info );
    $self->{'context'} = {};
    return 1;
}


=head2 content_types_provided

For GET requests, this is where we add our HTML body to the HTTP response.

=cut
 
sub content_types_provided { 
    [ { 'text/html' => '_render_response_html' }, ] 
}

sub _render_response_html { 
    my ( $self ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::_render_response_html" );

    my $r = $self->request;
    my $session = $r->{'env'}->{'psgix.session'};
    my $ce = $session->{'currentUser'};
    my $cepriv = $session->{'currentUserPriv'};
    my $entity;
    $entity = ( $r->path_info =~ m/test/i )
        ? $self->test_html( $ce, $cepriv )
        : $self->main_html( $ce, $cepriv );
    return $entity;
}



=head2 charsets_provided

This method causes L<Web::Machine> to encode the response body in UTF-8. 

=cut

sub charsets_provided { 
    [ 'utf-8' ]; 
}



=head2 default_charset

Really use UTF-8 all the time.

=cut

sub default_charset { 
    'utf-8'; 
}



=head2 allowed_methods

Determines which HTTP methods we recognize.

=cut

sub allowed_methods {
    [ 'GET', 'POST', ]; 
}



=head2 uri_too_long

Is the URI too long?

=cut

sub uri_too_long {
    my ( $self, $uri ) = @_;

    ( length $uri > $site->MFILE_URI_MAX_LENGTH )
        ? 1
        : 0;
}


=head2 known_content_type

Looks at the 'Content-Type' header of POST requests, and generates
a "415 Unsupported Media Type" response if it is anything other than
'application/json'.

=cut

sub known_content_type {
    my ( $self, $content_type ) = @_;

    #$log->debug( "known_content_type: " . Dumper $content_type );
    # for GET requests, we don't care about the content
    return 1 if $self->request->method eq 'GET';

    # some requests may not specify a Content-Type at all
    return 0 if not defined $content_type;

    # unfortunately, Web::Machine sometimes sends the content-type
    # as a plain string, and other times as an
    # HTTP::Headers::ActionPack::MediaType object
    if ( ref( $content_type ) eq '' ) {
        return ( $content_type =~ m/application\/json/ ) ? 1 : 0;
    }
    if ( ref( $content_type ) eq 'HTTP::Headers::ActionPack::MediaType' ) {
        $log->debug( "Content type is a HTTP::Headers::ActionPack::MediaType object!" );
        return $content_type->match( 'application/json' ) ? 1 : 0;
    }
    return 0;
}


=head2 malformed_request

This test examines the request body. It can either be empty or contain
valid JSON; otherwise, a '400 Malformed Request' response is returned.
If it contains valid JSON, it is converted into a Perl hashref and 
stored in the 'request_body' attribute of the context.

=cut

sub malformed_request {
    my ( $self ) = @_;
    
    # get the request body, which is UTF-8 ENCODED, so we decode it
    # into a normal Perl scalar
    my $body = decode_utf8( $self->request->content );

    return 0 if not defined $body or $body eq '';
    return 0 if defined $self->context and exists $self->context->{'request_body'};

    $log->debug( "malformed_request: incoming content body ->$body<-" );

    # there is a request body -- attempt to convert it
    my $result = 0;
    try {
        $self->context->{'request_body'} = JSON->new->utf8(0)->decode( $body );
    } 
    catch {
        $log->error( "Caught JSON error: $_" );
        $result = 1;
    };

    if ( $result == 0 ) {
        $log->debug( "malformed_request: body after JSON decode " . 
            ( ( $self->context->{'request_body'}->{'method'} eq 'LOGIN' ) 
                ? 'login/logout request' 
                : Dumper $self->context->{'request_body'} ) );
    }

    return $result;
}


=head3 main_html

Takes the session object and returns HTML string to be displayed in the user's
browser.

FIXME: might be worth spinning this off into a separate module.

=cut

sub main_html {
    my ( $self, $ce, $cepriv ) = @_;

    $cepriv = '' unless defined( $cepriv );
    $log->debug( "Entering " . __PACKAGE__ . "::main_html() with \$ce " .
                 Dumper($ce) . " and \$cepriv " . $cepriv );

    my $r = '<!DOCTYPE html><html>';

    $r .= '<head><meta charset="utf-8">';
    $r .= "<title>App::MFILE::WWW " . $meta->META_MFILE_APPVERSION . "</title>";
    $r .= '<link rel="stylesheet" type="text/css" href="/css/start.css" />';

    # Bring in RequireJS
    $r .= $self->_require_js($ce, $cepriv);

    $r .= '</head>';
    $r .= '<body>';

    # Start the main app logic
    $r .= '<script>require([\'main\']);</script>';

    $r .= '</body>';
    $r .= '</html>';
    return $r;
}


=head3 test_html

Generate html for running unit tests

=cut

sub test_html {
    my ( $self, $ce, $cepriv ) = @_;

    my $r = '';
    
    $r = '<!DOCTYPE html><html>';
    $r .= '<head><meta charset="utf-8">';
    $r .= "<title>App::MFILE::WWW " . $meta->META_MFILE_APPVERSION . " (Unit testing)</title>";
    $r .= '<link rel="stylesheet" type="text/css" href="/css/qunit.css" />';

    # Bring in RequireJS
    $r .= $self->_require_js($ce, $cepriv);

    $r .= '</head><body>';
    $r .= '<div id="qunit"></div>';
    $r .= '<div id="qunit-fixture"></div>';

    # Start unit tests
    $r .= '<script>require([\'test\']);</script>';

    $r .= '</body></html>';
    return $r;
}


# HTML necessary for RequireJS
sub _require_js {
    my ( $self, $ce, $cepriv ) = @_;

    my $r = '';

    $r .= "<script src='" . $site->MFILE_WWW_JS_REQUIREJS . "'></script>";

    $r .= '<script>';

    # configure RequireJS
    $r .= 'require.config({';

    # baseUrl is where we have all our JavaScript files
    $r .= 'baseUrl: "' . $site->MFILE_WWW_REQUIREJS_BASEURL . '",';

    # map 'jquery' module to 'jquery-private.js'
    # (of course, the real 'jquery.js' must be present in 'js/')
    $r .= 'map: {';
    $r .= "    '*': { 'jquery': 'jquery-private' },";
    $r .= "    'jquery-private': { 'jquery': 'jquery' }";
    $r .= '},';

    # path config
    $r .= 'paths: {';
    $r .= '    "app": "../' . $site->MFILE_APPNAME . '",';  # sibling to baseUrl
    $r .= '    "QUnit": "qunit"';                           # in baseUrl
    $r .= '},';

    # QUnit needs some coaxing to work together with RequireJS
    $r .= 'shim: {';
    $r .= '    "QUnit": {';
    $r .= '        exports: "QUnit",';
    $r .= '        init: function () {';
    $r .= '            QUnit.config.autoload = false;';
    $r .= '            QUnit.config.autostart = false;';
    $r .= '        }';
    $r .= '    }';
    $r .= '}';

    # end of require.config
    $r .= "});";

    # initialize configuration parameters that we need on JavaScript side
    $r .= 'requirejs.config({ config: {';
    $r .= '\'cf\': { ';

    # appName, appVersion
    $r .= 'appName: \'' . $site->MFILE_APPNAME . '\',';
    $r .= 'appVersion: \'' . $meta->META_MFILE_APPVERSION . '\',';

    # standaloneMode (boolean; false means "derived distro mode")
    $r .= 'standaloneMode: \'' . ( $meta->META_WWW_STANDALONE_MODE ? 'true' : 'false' ) . '\',';

    # currentUser
    $r .= "currentUser: " . ( $ce ? to_json( $ce ) : 'null' ) . ',';
    $r .= 'currentUserPriv: \'' . ( $cepriv || 'null' ) . '\',';

    # loginDialog
    $r .= 'loginDialogChallengeText: \'' . $site->MFILE_WWW_LOGIN_DIALOG_CHALLENGE_TEXT . '\',';
    $r .= 'loginDialogMaxLengthUsername: ' . $site->MFILE_WWW_LOGIN_DIALOG_MAXLENGTH_USERNAME . ',';
    $r .= 'loginDialogMaxLengthPassword: ' . $site->MFILE_WWW_LOGIN_DIALOG_MAXLENGTH_PASSWORD . ',';

    # session data
    $r .= 'displaySessionData: ' . ( $site->MFILE_WWW_DISPLAY_SESSION_DATA ? 'true' : 'false' ) . ',';
    if ( $site->MFILE_WWW_DISPLAY_SESSION_DATA ) {
        $r .= 'sessionID: \'' . $self->session_id . '\',';
        $r .= 'sessionLastSeen: \'' . ( exists $self->session->{'last_seen'} ? $self->session->{'last_seen'} : 'never' ) . '\',';
    }

    # REST server URI
    if ( defined( $site->DOCHAZKA_WWW_BACKEND_URI ) ) {
        $r .= 'restURI: \'' . $site->DOCHAZKA_WWW_BACKEND_URI . '\',';
    }

    # dummyParam in last position so we don't have to worry about comma/no comma
    $r .= 'dummyParam: null';

    $r .= '} } });';
    $r .= '</script>';
    return $r;
} 

1;
