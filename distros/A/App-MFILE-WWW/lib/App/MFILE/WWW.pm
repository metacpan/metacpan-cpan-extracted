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
# App::MFILE::WWW top-level module
# ------------------------

package App::MFILE::WWW;

use 5.012;
use strict;
use warnings;

use App::CELL qw( $CELL $log $site $meta );
use Exporter qw( import );
use File::ShareDir;
use File::Spec;
use Log::Any::Adapter;
use Params::Validate qw( :all );



=head1 NAME

App::MFILE::WWW - Web UI development toolkit with prototype demo app




=head1 VERSION

Version 0.156

=cut

our $VERSION = '0.156';
our @EXPORT_OK = ( '$VERSION' );



=head1 LICENSE

This software is distributed under the "BSD 3-Clause" license, the text of
which can be found in the file named C<COPYING> in the top-level distro
directory. The license text is also reprodued at the top of each source file.



=head1 SYNOPSIS

    $ man mfile-www
    $ mfile-www
    $ firefox http://localhost:5001



=head1 DESCRIPTION

This distro contains a foundation/framework/toolkit for developing the "front
end" portion of web applications. 

L<App::MFILE::WWW> is a L<Plack> application that provides a HTTP
request-response handler (based on L<Web::Machine>), CSS and HTML source code
for an in-browser "screen", and JavaScript code for displaying various
"widgets" (menus, forms, etc.) in that screen and for processing user input
from within those widgets.

In addition, infrastructure is included (but need not be used) for user
authentication, session management, and communication with a backend server via
AJAX calls.

Front ends built with L<App::MFILE::WWW> will typicaly be menu-driven,
consisting exclusively of fixed-width Unicode text, and capable of being
controlled from the keyboard, without the use of a mouse. The overall
look-and-feel is reminiscent of the text terminal era.

The distro comes with a prototype (demo) application to illustrate how the
various widgets are used.



=head1 QUICK START (DEMO)

L<App::MFILE::WWW> can be run as a standalone HTTP server providing a
self-contained demo web application, or "web frontend".

Assuming L<App::MFILE::WWW> has been installed properly, this mode of operation
can be started by running C<mfile-www>, as a normal user (even 'nobody'), with
no arguments or options:

    $ mfile-www

The start-up script will write information about its state to the standard
output. This includes the location of its log file, the port where the HTTP
server is listening (default is 5001), etc. For a detailed description of what
happens when the start-up script is run, see the POD of C<mfile-www> itself
- e.g. "man mfile-www".


=head1 DERIVED WWW CLIENTS

When you write your own web frontend using this distro, from
L<App::MFILE::WWW>'s perspective it is a "derived client" and will be referred
to as such in this document.


=head2 Derived client operation

In a derived-client scenario, L<App::MFILE::WWW> is basically used as a
library, or framework, upon which the "real" application is built.

The derived-client handling is triggered by providing the C<--ddist>
command-line option, i.e.

    $ mfile-www --ddist=App-Dochazka-WWW

Where 'App-Dochazka-WWW' refers to the Perl module L<App::Dochazka::WWW>,
which is assumed to contain the derived client source code.

So, in the first place it is necessary to create such a Perl module.  It should
have a sharedir configured and present. One such derived client,
L<App::Dochazka::WWW>, is available on CPAN.



=head1 IMPLEMENTATION DETAILS

=head2 HTTP request-response cycle

The HTTP request-response cycle is implemented as follows:

=over

=item * B<nginx> listens for incoming connections on port 80/443 of the server

=item * When a connection comes in, B<nginx> decrypts it and forwards it to a
high-numbered port where a PSGI-compatible HTTP server (such as L<Starman>) is
listening

=item * The HTTP server takes the connection and passes it to the Plack middleware.
The key middleware component is L<Plack::Middleware::Session>, which assigns an
ID to the session, stores whatever data the server-side code needs to associate
with the session, links the session to the user's browser via a cookie, and
provides the application a hook (in the Plack environment stored in the HTTP
request) to access the session data

=item * if the connection is asking for static content (defined as anything in
C<images/>, C<css/>, or C<js/>), that content is served immediately and the
request doesn't even make it into our Perl code

=item * any other path is considered dynamic content and is passed to
L<Web::Machine> for processing -- L<Web::Machine> implements the HTTP standard
as a state machine

=item * the L<Web::Machine> state machine takes the incoming request and runs
it through several functions that are overlayed in L<App::MFILE::WWW::Resource>
- an appropriate HTTP error code is returned if the request doesn't make it
through the state machine. Along the way, log messages are written to the log.

=item * as part of the state machine, all incoming requests are subject to
"authorization" (in the HTTP sense, which actually means authentication).
First, the session data is examined to determine if the request belongs to an
existing authorized session. If it doesn't, the request is treated as a
login/logout attempt -- the session is cleared and control passes to the 
JavaScript side, which, lacking a currentUser object, displays the login
dialog.

=item * once an authorized session is established, there are two types of
requests: GET and POST

=item * incoming GET requests happen whenever the page is reloaded -
in an authorized session, this causes the main menu to be displayed, but all
static content (CSS and JavaScript modules) are reloaded for a "clean slate",
as if the user had just logged in.

=item * Note that L<App::MFILE::WWW> pays no attention to the URI - if the user
enters a path (e.g. http://mfile.site/some/bogus/path), this will be treated
like any other page (re)load and the path is simply ignored.

=item * if the session is expired or invalid, any incoming GET request will
cause the login dialog to be displayed.

=item * well-formed POST requests are directed to the C<process_post> routine
in L<App::MFILE::WWW::Dispatch>. In derived-distro mode, the derived distro
must provide its own dispatch module.

=item * under ordinary operation, the user will spend 99% of her time
interacting with the JavaScript code running in her browser, which will
communicate asynchronously as needed with the back-end (which must be
implemented separately) via AJAX calls.

=back


=head1 DEVELOPMENT NOTES

The L<App::MFILE::WWW> codebase has two parts, or "sides": the "Perl side"
and the "JavaScript side". Control passes from the Perl side to the
JavaScript side

=over

=item * B<synchronously> whenever the user (re)loads the page

=item * B<asynchronously> whenever the user triggers an AJAX call

=back


=head3 JavaScript side

=head4 Modular (RequireJS)

The JavaScript code is modular. Each code module has its own file and
modules are loaded asynchronously by L<RequireJS|http://requirejs.org/>.

=head4 Unit testing (QUnit)

The JavaScript code included in this package is set up for unit testing
using the QUnit L<http://qunitjs.com/> library.



=head3 UTF-8

In conformance with the JSON standard, all data passing to and from the
server are assumed to be encoded in UTF-8. Users who need to use non-ASCII
characters should check their browser's settings.


=head2 Deployment

To minimize latency, L<App::MFILE::WWW> can be deployed on the same server
as the back-end (e.g. L<App::Dochazka::REST>), but this is not required.

=cut



=head1 PACKAGE VARIABLES

For convenience, the following variables are declared with package scope:

=cut

my $dist_dir = File::ShareDir::dist_dir( 'App-MFILE-WWW' );



=head1 FUNCTIONS

=head2 init

Initialization routine - run from C<bin/mfile-www>, the server startup script.
This routine loads configuration parameters from files in the distro and site
configuration directories, and sets up logging.

=cut

sub init {
    my %ARGS = validate( @_, { 
        mode => { type => SCALAR, optional => 1 }, # 'STANDALONE' or 'DDIST', defaults to 'STANDALONE'
        ddist_sharedir => { type => SCALAR, optional => 1 },
        sitedir => { type => SCALAR, optional => 1 },
        debug_mode => { type => SCALAR, optional => 1 },
    } );

    # * determine mode
    my $mode = $ARGS{'mode'} || 'STANDALONE';
    if ( $mode =~ m/^(standalone|ddist)$/i ) {
        if ( $mode =~ m/^ddist$/i ) {
            $mode = 'DDIST';
        } else {
            $mode = 'STANDALONE';
        }
    }

    # * load site configuration
    my $status = _load_config( %ARGS );
    return $status if $status->not_ok;

    # * mode-specific meta configuration
    $meta->set( 'META_WWW_STANDALONE_MODE', ( $mode eq 'STANDALONE' ) );

    # * set up logging
    return $CELL->status_not_ok( "MFILE_APPNAME not set!" ) if not $site->MFILE_APPNAME;
    my $debug_mode;
    if ( exists $ARGS{'debug_mode'} ) {
        $debug_mode = $ARGS{'debug_mode'};
    } else {
        $debug_mode = $site->MFILE_WWW_DEBUG_MODE || 0;
    }
    unlink $site->MFILE_WWW_LOG_FILE if $site->MFILE_WWW_LOG_FILE_RESET;
    Log::Any::Adapter->set('File', $site->MFILE_WWW_LOG_FILE );
    $log->init( ident => $site->MFILE_APPNAME, debug_mode => $debug_mode );
    $log->info( "Initializing " . $site->MFILE_APPNAME );

    return $CELL->status_ok;
}

sub _load_config {
    my %ARGS = @_;
    my $status;
    my $sitedir_loaded = 0;

    #Log::Any::Adapter->set( 'File', "$ENV{HOME}/.mfile-www-early-debug.log" );
    #$log->init( ident => 'MFILE-WWW', debug_mode => 1 );

    # always load the App::MFILE::WWW distro sharedir
    my $target = File::Spec->catfile( $dist_dir, 'config' );
    print "Loading App::MFILE::WWW configuration parameters from $target\n";
    $status = $CELL->load( sitedir => $target );
    return $status if $status->not_ok;

    # load additional sitedir if provided by caller in argument list
    if ( $ARGS{sitedir} ) {
        $target = $ARGS{sitedir};
        print "Loading App::MFILE::WWW configuration parameters from $target\n";
        $status = $CELL->load( sitedir => $target );
        return $status if $status->not_ok;
        $sitedir_loaded = 1;
    }

    # if ddist_sharedir was given, attempt to load configuration from that, too
    if ( $ARGS{ddist_sharedir} and ! $sitedir_loaded ) {
        $target = File::Spec->catfile( $ARGS{ddist_sharedir}, 'config' );
        print "Loading App::MFILE::WWW configuration parameters from $target\n";
        $status = $CELL->load( sitedir => $target );
        return $status if $status->not_ok;
    }

    return $CELL->status_ok;
}

1;
