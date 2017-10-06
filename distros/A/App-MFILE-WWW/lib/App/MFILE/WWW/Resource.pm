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

package App::MFILE::WWW::Resource;

use strict;
use warnings;

use App::CELL qw( $CELL $log $meta $site );
use Data::Dumper;
use Encode qw( decode_utf8 encode_utf8 );
use File::Temp qw( tempfile );
use HTTP::Request::Common qw( GET PUT POST DELETE );
use JSON;
use LWP::UserAgent;
use Params::Validate qw(:all);
use Try::Tiny;

# methods/attributes not defined in this module will be inherited from:
use parent 'Web::Machine::Resource';

# user agent lookup table
our $ualt = {};



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


=head2 remote_addr

=cut

sub remote_addr {
    my $self = shift;
    return $self->request->{'env'}->{'REMOTE_ADDR'};
}


=head2 session

=cut

sub session {
    my $self = shift;
    if ( @_ ) {
        $self->request->{'env'}->{'psgix.session'} = shift;
    }
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
    if ( $r->path_info =~ m/test/i ) {
        $log->debug( "Running unit tests" );
        $entity = $self->test_html();
    } else {
        $log->debug( "Running the app" );
        $entity = $self->main_html( $ce, $cepriv );
    }
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


=head2 is_authorized

Since all requests go through this function at a fairly early stage, we
leverage it to validate the session.

=cut

sub is_authorized {
    my ( $self ) = @_;

    $log->debug( "Entering " . __PACKAGE__ . "::is_authorized()" );

    my $r = $self->request;
    my $session = $self->session;
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
    $log->debug( "Entering " . __PACKAGE__ . "::main_html" );

    $cepriv = '' unless defined( $cepriv );
    $log->debug( "Entering " . __PACKAGE__ . "::main_html() with \$ce " .
                 Dumper($ce) . " and \$cepriv " . $cepriv );

    my $r = '<!DOCTYPE html>';
    $r .= '<html>';
    $r .= '<head>';
    $r .= '<meta charset="utf-8">';
    $r .= '<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">';
    $r .= '<meta http-equiv="Pragma" content="no-cache">';
    $r .= '<meta http-equiv="Expires" content="0">';
    $r .= "<title>App::MFILE::WWW " . $meta->META_MFILE_APPVERSION . "</title>";
    $r .= '<link rel="stylesheet" type="text/css" href="/css/start.css" />';

    # Bring in RequireJS with testing == 0 (false)
    $r .= $self->_require_js(0, $ce, $cepriv);

    $r .= '</head>';
    $r .= '<body>';

    # Start the main app logic
    $r .= '<script>require([\'main\']);</script>';

    $r .= '</body>';
    $r .= '</html>';
    return $r;
}


=head3 test_html

Generate html for running (core and app) unit tests. The following JS files are
run (in this order):

=over

=item test.js (in mfile-www core)

=item test.js (in app, e.g. dochazka-www)

=item test-go.js (in mfile-www core)

=back

=cut

sub test_html {
    my ( $self ) = @_;
    $log->debug( "Entering " . __PACKAGE__ . "::test_html" );

    my $r = '';
    
    $r = '<!DOCTYPE html>';
    $r .= '<html>';
    $r .= '<head>';
    $r .= '<meta charset="utf-8">';
    $r .= '<meta http-equiv="Cache-Control" content="no-cache, no-store, must-revalidate">';
    $r .= '<meta http-equiv="Pragma" content="no-cache">';
    $r .= '<meta http-equiv="Expires" content="0">';
    $r .= "<title>App::MFILE::WWW " . $meta->META_MFILE_APPVERSION . " (Unit testing)</title>";
    $r .= '<link rel="stylesheet" type="text/css" href="/css/qunit.css" />';

    # Bring in RequireJS with testing == 1 (true)
    $r .= $self->_require_js(1);

    $r .= '</head><body>';
    $r .= '<div id="qunit"></div>';
    $r .= '<div id="qunit-fixture"></div>';

    # Run unit tests; see:
    # - test.js (in mfile-www core)
    # - app/test.js (in app; e.g. dochazka-www
    # - test-go.js (in mfile-www core)
    $r .= '<script>require([\'test\', \'app/test\', \'test-go\']);</script>';

    $r .= '</body></html>';
    return $r;
}


# HTML necessary for RequireJS
sub _require_js {
    my ( $self, $testing, $ce, $cepriv ) = @_;

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
    $r .= "currentUserPriv: " . ( $cepriv ? "\'$cepriv\'" : 'null' ) . ',';

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
    $r .= 'dummyParam: null,';

    # unit tests running?
    $r .= "testing: " . ( $testing ? 'true' : 'false' );

    $r .= '} } });';
    $r .= '</script>';
    return $r;
} 


=head2 login_status

=cut

sub login_status {
    my ( $self, $code, $message, $body_json ) = @_;

    my $status;

    if ( $code == 200 ) {
        $self->session->{'ip_addr'} = $self->remote_addr;
        my $cu = $body_json->{'payload'}->{'emp'};
        delete $cu->{'passhash'};
        delete $cu->{'salt'};
        $self->session->{'currentUser'} = $cu;
        $self->session->{'currentUserPriv'} = $body_json->{'payload'}->{'priv'};
        $self->session->{'last_seen'} = time;
        $log->debug(
            "Login successful, currentUser is now " .
            Dumper( $body_json->{'payload'}->{'emp'} ) .
            " and privilege level is " . $body_json->{'payload'}->{'priv'}
        );
        $status = $CELL->status_ok( 'MFILE_WWW_LOGIN_OK', payload => $body_json->{'payload'} );
    } else {
        $self->session({});
        $log->debug( "Login unsuccessful, reset session" );
        $status = $CELL->status_not_ok(
            'MFILE_WWW_LOGIN_FAIL: %s',
            args => [ $code ],
            payload => { code => $code, message => $message },
        );
    }
    $self->response->header( 'Content-Type' => 'application/json' );
    $self->response->body( to_json( $status->expurgate ) );
    return $status;
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


=head2 rest_req

Algorithm: send request to REST server, get JSON response, decode it, return
it.

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
    my $self = shift;

    # process arguments
    my $ua = $self->ua();
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

1;
