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

Version 0.175

=cut

our $VERSION = '0.175';
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

L<App::MFILE::WWW> can be run as a standalone "front-end web application" written
in JavaScript with an embedded HTTP server.

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

In a derived-client scenario, L<App::MFILE::WWW> serves as the foundation
upon which the "real" application is built.

The derived-client handling is triggered by providing the C<--ddist>
command-line option, i.e.

    $ mfile-www --ddist=App-Dochazka-WWW

where 'App-Dochazka-WWW' refers to the Perl module L<App::Dochazka::WWW>,
which is assumed to contain the derived client source code.

So, in the first place it is necessary to create such a Perl module. It should
have a sharedir configured and present. One such derived client,
L<App::Dochazka::WWW>, is available on CPAN.



=head1 PERL AND JAVASCRIPT

The L<App::MFILE::WWW> codebase has two parts, or "sides": the "Perl side"
and the "JavaScript side". The Perl side implements the embedded web server
and the JavaScript side implements the front-end application served to
browsers by the Perl side.

Control passes from the Perl side to the JavaScript side

=over

=item * B<synchronously> whenever the user (re)loads the page

=item * B<asynchronously> whenever the user triggers an AJAX call

=back

=head2 Perl side

The HTTP request-response cycle implemented by the Perl side is designed to
work approximately like this:

=over

=item * B<nginx> listens for incoming connections on port 80/443 of the server

=item * When a connection comes in, B<nginx> decrypts it and forwards it to a
high-numbered port where a PSGI-compatible HTTP server (such as L<Starman>) is
listening

=item * The embedded HTTP server takes the connection and passes it to the
Plack middleware.  The key middleware component is
L<Plack::Middleware::Session>, which assigns an ID to the session, stores
whatever data the server-side code needs to associate with the session, links
the session to the user's browser via a cookie, and provides the application a
hook (in the Plack environment stored in the HTTP request) to access the
session data

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


=head2 JavaScript side

The JavaScript side provides a toolkit for building web applications that

=over

=item do not require the use of a mouse; and 

=item look and feel very much like text terminal applications from the 1980s

=back

Developing a front-end application with L<App::MFILE::WWW> currently assumes
that you, the developer, will want to use RequireJS, jQuery, and QUnit.

The JavaScript code is modular. Each code module has its own file and
modules are loaded asynchronously by L<RequireJS|http://requirejs.org/>.
Also, jQuery and QUnit L<http://qunitjs.com/> are loaded automatically.

In addition to the above, L<App::MFILE::WWW> provides a number of primitives,
also referred to as "targets", that can be used to quickly slap together a web
application. The next chapter explains what these widgets are and how to use
them.



=head1 FRONT-END PRIMITIVES

The JavaScript side implements a set of primitives, or widgets, from which the
front-end application is built up. These include a menu primitive, a form
primitive for entering data, table and "browser" primitives for viewing
datasets, and a "rowselect" primitive for selecting among 

=head2 daction

The C<daction> primitive is a generalized widget that can do anything. 


=head2 dbrowser

The C<dbrowser> primitive is like C<dform>, except that it displays a set
of data objects and enables the user to "browse" the dataset using arrow keys.
Like C<dform>, the primitive includes "miniMenu" functionality through which
the user can potentially trigger actions that take the current object as input.


=head2 dcallback

The C<dcallback> primitive is useful for cases when none of the other primitives
are appropriate for displaying a given type of object, and no interactivity is
needed beyond that provided by miniMenu. The C<dcallback> primitive writes the
target title and miniMenu to the screen, along with a "dcallback" div in
between, which it populates by calling the callback function. Since the callback
function part of the target definition, it can be app-specific.


=head2 dform

The C<dform> primitive is used to implement forms consisting of read-only
fields (for viewing data), read-write fields (for entering data), or a
combination of both. A "miniMenu" can be defined, allowing the user to trigger
actions that take the current object as input.


=head2 dmenu

The C<dmenu> primitive is used to implement menus.


=head2 dnotice

The C<dnotice> primitive takes an HTML string and displays it. The same
functionality can be accomplished with a C<daction>, of course, but using the
C<dnotice> primitive ensures that the notice will have the same "look and feel"
as the other widgets.


=head2 drowselect

The C<drowselect> primitive takes an array of strings, displays them vertically
as a list, and allows the user to choose one and perform an action on it. Actions
are defined via a C<miniMenu>. The currently-selected item is displayed in
reverse-video.


=head2 dtable

The C<dtable> primitive is similar to C<dbrowser> in that it takes a set of
objects and allows the user to choose one and perform actions on it via a
C<miniMenu>. Unlike C<dbrowser>, however, it display the objects in table form.
The currently-selected object is displayed in reverse video.



=head1 JAVASCRIPT UNIT TESTS

The JavaScript side has unit tests and functional tests that can be run by
starting the application and then pointing the browser to a URL like:

    http://localhost:5001/test

The tests are implemented using QUnit. A good source of practical advise on the
use of QUnit is the QUnit Cookbook, available here:

    https://qunitjs.com/cookbook/

The QUnit API itself is documented here:

    http://api.qunitjs.com/


=head2 Adding new test cases

There are separate sets of JavaScript unit tests for each of the following
three components:

=over

=item mfile-www core

=item mfile-www demo app

=item derived application (e.g. dochazka-www)

=back

To add a new test case, go to the appropriate C<tests/> directory (in mfile-www
core, in the mfile-www demo app, or in your derived application, as
appropriate) and create a js file (use one of the other C<tests/*.js> files
as a model). Then add this file to the C<test.js> file in the parent directory.


=head1 DEVELOPMENT NOTES


=head2 UTF-8

In conformance with the JSON standard, all data passing to and from the
server are assumed to be encoded in UTF-8. Users who need to use non-ASCII
characters should check their browser's settings.


=head2 Deployment

To minimize latency, L<App::MFILE::WWW> can be deployed on the same server
as the back-end (e.g. L<App::Dochazka::REST>), but this is not required.



=head1 PACKAGE VARIABLES

For convenience, the following variables are declared with package scope:

=cut

my $dist_dir = File::ShareDir::dist_dir( 'App-MFILE-WWW' );



=head1 FUNCTIONS

=head2 init

Initialization routine - run from C<bin/mfile-www>, the server startup script.
This routine loads configuration parameters from files in the distro and site
configuration directories, and sets up logging.

FIXME: This code could be moved into the startup script.

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
