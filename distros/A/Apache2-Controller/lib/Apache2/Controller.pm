package Apache2::Controller;

=encoding utf8

=head1 NAME

Apache2::Controller - fast MVC-style Apache2 handler apps

=head1 VERSION

Version 1.001.001

=cut

use version;
our $VERSION = version->new('1.001.001');

=head1 INSTALLATION PRE-REQUISITES

You need mod_perl2, L<Apache::Test> and L<version> installed to 
build this distribution with CPAN.  
Otherwise the Makefile.PL will not run
to tell you that prerequisites failed.  
This is a drawback of using L<Apache::Test>.

=head1 SYNOPSIS

The handler IS the controller.  A2C gets all the 
abstractions out from between your controller logic and
the Apache2 methods to control input/output, status etc.
You control Apache2 directly, or use a rendering base like 
L<Apache2::Controller::Render::Template> which gives a method
to render using L<Template> Toolkit.

For Apache2 config file setup see L<Apache2::Controller::Dispatch>,
which sets a PerlResponseHandler of Apache::Controller, which
then creates your controller object and calls the chosen
method for the uri.
 
 package MyApp::C::Foo;
 use strict;
 use warnings FATAL => 'all';

 # base Apache2::Request is optional, it would limit your
 # choice of method names.  request object is in $self->{r}
 # if you do not choose to use it to get access to the 
 # Apache2 methods via $self.

 use base qw( 
     Apache2::Controller 
     Apache2::Request
 );

 use Apache2::Const -compile => qw( :http );
 sub allowed_methods {qw( default bar baz )}

 # suppose '/foo' is the uri path dispatched to this controller
 # and your dispatch uses Apache2::Controller::Dispatch::Simple

 # http://myapp.xyz/foo/
 sub default {
     my ($self) = @_;
     $self->content_type('text/plain');
     $self->print("Hello, world!\n");
     return Apache2::Const::HTTP_OK;
 }

 # http://myapp.xyz/foo/bar/biz/schnozz
 sub bar {
     my ($self, @path_args) = @_;             
     # @path_args is:
     #      qw( biz schnozz )
     #      @{ $self->{path_args} }
     #      @{ $self->pnotes->{a2c}{path_args} }

     $self->content_type('text/html');
     $self->print(q{ <p>"WE ARE ALL KOSH"</p> });
     return Apache2::Const::HTTP_OK;
 }

 # http://myapp.xyz/foo/baz
 sub baz {
     my ($self) = @_;

     return Apache2::Const::HTTP_BAD_REQUEST 
        if $self->param('goo');         # inherits Apache2::Request

     return Apache2::Const::HTTP_FORBIDDEN 
        if $self->param('boz') ne 'noz';

     $self->content_type('text/plain'); # inherits Apache2::RequestRec
     $self->sendfile('/etc/passwd');    # inherits Apache2::RequestIO

     return Apache2::Const::HTTP_OK;
 }

 1;

You could implement a pretty nice REST interface, or any other kind
of HTTP-based API, by returning the appropriate HTTP status codes.
See L<Apache2::Controller::Refcard/status> for a list.

See L<Apache2::Controller::Render::Template> for an additional base
for your controller class to render HTML with L<Template> Toolkit,
auto-selecting a template from the include path based on the 
request URI.

=head1 DESCRIPTION

Apache2::Controller is a lightweight controller framework for 
object-oriented applications designed to run only under mod_perl 
children in high-performance Apache2 handler modules.  It features URL 
dispatch with flexible configuration, auth plugins, a cookie tracker
for Apache::Session, liberty for any storage models that work under mod_perl,
rendering using Template Toolkit or direct printing with Apache or whatever
you want,
and base inheritance configuration allowing you to 
construct your applications as you need, without trying to be all things 
to all people or assimilate the world.  
It is intended as a framework for 
new applications specialized as Apache2 handlers, not as a means to 
absorb existing applications or to create portable code.  

Apache2::Controller instantiates the L<Apache2::Request> 
object and puts it in C<< $self->{r} >>.  If you want access
to the methods directly via C<< $self >>, simply use
L<Apache2::Request> as a base and it will auto-delegate
all the methods.  
See L<Apache2::Request/SUBCLASSING Apache2::Request>.

For using other Apache2::Controller extension methods, use 
another base class like 
L<Apache2::Controller::Render::Template>, provides an easy way to
use Template Toolkit by default to render pages, selecting templates
from a directory structure that corresponds to your controller URI's.

Individual controller methods can specify plain text or other
content types and print directly through inherited L<Apache2::RequestIO> 
methods, if you use L<Apache2::Request> as a second base and suck
its methods in through that module's auto-magic.  
See L<Apache2::Request/SUBCLASSING Apache2::Request>.

Instead of abstracting Rube Goldberg devices around the Apache2 mod_perl 
methods, it stays out 
of your way and lets you use any and all of them directly through 
C<$self> as you see fit, if you use L<Apache2::Request> as a second base.
But you don't have to do that, if you don't want potential namespace
conflicts with your uri's.  For example, if you do use
L<Apache2::Request> as a base, you couldn't have a uri 'params'
or 'connection', for example, if you want to be able to use 
those Apache2 family methods.  The L<Apache2::Request> object
is always in C<< $self->{r} >> either way.

Use L<Apache2::Controller::Dispatch> from your Apache2 config file to 
send various URI requests to your page view modules.  See the 
CONFIGURATION section below.  This features a standard mechanism for uri 
dispatch in L<Apache2::Controller::Dispatch::Simple> that does not try 
to figure out what modules are available, but 
simply requires you to provide a hash that maps from uri paths to 
controller modules.  Or, dispatch plugins can be created to implement
the dispatcher's find_controller() method in some other way, like
with a TRIE for big sites or using other algorithms,
even dynamic ones based on context from the request.

L<Apache2::Controller> is the base module for each controller module. 
Depending on your dispatch mechanism, controller modules usually 
contain a list of the method names which 
are allowed as uri paths under the controller.

=head1 DISPATCH OF URI TO CONTROLLER

You do not put Apache2::Controller or your subclass into the
Apache2 server configuration.  Instead you make a subclass
of L<Apache2::Controller::Dispatch> and use that as a
PerlInitHandler.  It will map a URI to an appropriate
Apache2::Controller subclass object and method and will
use C<< $r->push_handlers() >> if successful to push Apache2::Controller
onto the modperl response handler stack, which then creates
the right handler object of your subclass and sends the
request to the right method, handling errors in a nice way.

See L<Apache2::Controller::Dispatch>
for more information and different types of URI dispatching.
Some simple types are bundled which depend on
the C<< allowed_methods() >> subroutine in your controller,
but that isn't a required feature - 
you can also implement your own dispatch subclass which
does things your way, moves allowed uris around depending
on context in the request, or whatever.

=head1 OTHER REQUEST PHASE HANDLERS

Configure other handlers in your config file to set things up
before your Apache2::Controller runs.

Most of these handlers use L<Apache2::Controller::NonResponseBase>
as a base for the object, which usually does not need to
instantiate the L<Apache2::Request> object, because they
usually run before the response phase, so you usually don't
want to parse and cache the body if you want to use input filters.
If your subclass methods of non-response Apache2::Controller
components need access to the L<Apache2::RequestRec> object C<< $r >>, 
it is always in C<< $self->{r} >>.

Some other request phase handlers register later-stage handlers,
for example to save the session or rollback uncommitted database 
transactions with C<PerlLogHandler>'s
after the connection output is complete.

The controller handler returns your set HTTP status code
or OK (0) to Apache.  In general you return the status code
that you want to set, or return OK.  Or you can set it with
C<< $r->status() >> and return OK.  
You can't return DONE or DECLINED. (If you find you need
to do that for some reason please contact me.)

See L<Apache2::Const/:http>
and L<Apache2::Controller::Refcard>.  You can also set
C<< status_line() >> or throw L<Apache2::Controller::X>
exceptions to be processed by an error template,
if you're using some form of template rendering - see
the section on errors below.

Add handlers in your config file with your own modules which 
C<use base> to inherit from these classes as you need them:

=head2 PerlHeaderParserHandler Apache2::Controller::Session

C<< $r->pnotes->{a2c}{session} >> automatically loaded from and 
stored to an L<Apache::Session> tied hash.  Pushes a PerlLogHandler
to save the session after the main controller returns OK.

See L<Apache2::Controller::Session>
and L<Apache2::Controller::Session::Cookie>.

=head2 PerlAuthenHandler Apache2::Controller::Authen::OpenID

Implements OpenID logins and redirects to your specified login 
controller by changing the dispatch selection on the fly.

See L<Apache2::Controller::Authen::OpenID>.

As for Access and Authz phases of AAA, you should
probably roll your own.  This framework isn't going
to dictate the means of your data storage or how
you organize your users.  See the mod_perl manual.

=head1 Apache2::Controller response phase handler

Apache2::Controller is set as the PerlResponseHandler if 
the dispatch class finds a valid module and method for the request.

=head2 Subclass L<Apache2::Request>

Most of the time you will want to use Apache2::Request as
a second base.  If you do this, then your controller
inherits the L<Apache2::RequestRec> methods with 
(some) modperl2 request extension libraries loaded during 
construction, or you can use others in the package namespace
and automatically get the methods.  

This way, you can call C<< $self->$methodname >> for any of
the methods associated with L<Apache2::Request>, 
L<Apache2::RequestRec> and some of their friends.  
Watch the log for warnings about redefined subroutines, or 
C<< use warnings FATAL => 'all' >> to keep yourself on the
right track.

To use a simplified example:

 package MyApp::C::SomeURIController;
 use base qw( 
     Apache2::Controller 
     Apache2::Request 
 );

 my %pats = (
     shipto => qr{ \A (.*?) \z }mxs,
     addr   => qr{ \A (.*?) \z }mxs,
     zip    => qr{ \A (\d{5}) \z }mxs,
 );
 
 sub set_shipping_address {
     my ($self) = @_;

     # $self->param() is Apache::Request param():
     my ($shipto, $addr, $zip) 
         = map {
             $self->param($_) =~ $pats{$_};
             $1 || return Apache2::Const::SERVER_ERROR;
         } qw( shipto addr zip );
     $self->content_type('text/plain');
     $self->print('Your package is on its way.');
     return Apache2::Const::HTTP_OK
 }

At any rate, your Apache2::Controller child object 
normally subclasses 
itself into Apache2::Request which magically
delegates all those methods
to the internal hash value C<< $self->{r} >>, which is the actual 
Apache2::Request object.
See L<Apache2::Request/SUBCLASSING Apache2::Request>
about those gory details.  

Whether 
you call C<< $self->$apache2_request_method >> or 
C<< $self->{r}->$apache2_request_method >> matters not,
you still ask the same object, so you might as well use
C<< $self->$method >> to make it look clean.

But, if you don't want to pollute your namespace of
potential URI handlers with the Apache2::Request* family
method namespace, don't use Apache2::Request as a base.
C<< $self->{r} >> is still an Apache2::Request object,
which gets you to all the RequestRec, RequestUtil,
RequestIO methods etc.

The rest of this manual assumes that you do use
L<Apache2::Request> as a base in your controller,
and refers to its methods via C<< $self >>.  Just
keep in mind that you don't have to, but can
access those methods via C<< $self->{r} >>.

=head1 RETURN VALUES

Your controller methods should use C<< eval { } >> if necessary and
act accordingly, set the right things for C<Apache2::RequestRec> 
and return the right HTTP constant.  See L<Apache2::Const/:http>
and L<Apache2::Controller::Refcard>.

In the event of an error, if you wish, use L<Apache2::Controller::X>
and throw one with field 'status' set to a valid HTTP return code.  
This lets you implement nice error templates if your controller uses 
L<Apache2::Controller::Render::Template> as a base.
See L<ERRORS> below.

Success in the controller method normally should just return the
appropriate HTTP status code.  You can return HTTP_OK (200) if that
is what you mean, or it is the default status if you return OK (0).

Or, if you do C<< $self->status( Apache2::Const::HTTP_SOMETHING ) >>
and then just C<< return() >>
or return OK (0), Apache2::Controller will not override the set status.

See L<Apache2::Controller::Refcard> for a list of HTTP return constants
and corresponding numbers and messages.

=head2 REDIRECTS, ETC.

As an example of return values, take browser redirects.
There's no need for an abstraction mechanism around redirects
since you have direct access to the Apache methods.

 package MyApp::Controller::Somewhere;
 use base qw( Apache2::Controller Apache2::Request );
 use Apache2::Const -compile => qw( REDIRECT );

 # maybe dispatched from http://myapp.xyz/somewhere/go_elsewhere
 sub go_elsewhere {
     my ($self, @path_args) = @_;
     $self->err_headers_out->add(Location => 'http://foo.bar');
     return Apache2::Const::REDIRECT;
 }

Keep in mind that if you use other request phase processors that
push a C<PerlLogHandler> like 
L<Apache2::Controller::DBI::Connector> or
L<Apache2::Controller::Session>, those will still run,
but for example the session controller won't save the session
if you set or return an http status higher than the HTTP_OK family
(HTTP_MULTIPLE_CHOICES (300) or higher.)

You should also not fiddle with the connection by causing
Apache2 to close it prematurely, else the post-response handlers 
may not run or won't run synchronously before another request 
is received that may have depended on their behavior.
(For example, you can't use a C<< PerlCleanupHandler >>
to do things like that because the request has already closed,
and it doesn't get processed before taking in the next request,
even when running in single-process mode.)

=head1 ERRORS

If you decide to set an error status code, you can print your
own content and return that status code.

If you want to use error templates, 
barf L<Apache2::Controller::X> objects.  These print a stack trace
to the error log at the WARN level of L<Log::Log4perl> from
this module's namespace.  If errors crop up from
other A2C request phase handlers, try setting
WARN log level for L<Apache2::Controller::NonResponseBase>
or L<Apache2::Controller::NonResponseRequest>.

Also see L<Apache2::Controller::Render::Template>.

You can use or subclass L<Apache2::Controller::X>,
to use C<< a2cx() >>,
or you can throw your own exception objects,
or just C<< die() >>, or C<< croak() >>,
or set C<< $self->status >>, headers etc., possibly printing content, 
or return the appropriate status from your controller method.

See L<Apache2::Controller::X> for help on throwing exceptions
with HTTP status, data dumps, etc.

If your code does break, die or throw an exception, this is 
caught by Apache2::Controller.  If your controller module implements
an C<<error() >> method, 
then C<< $handler->error() >> will be called passing the C<< $EVAL_ERROR >>
or exception object as the first argument.

 package MyApp::C::Foo;
 use YAML::Syck;
 # ...
 sub error {
     my ($self, $X) = @_;
     $self->status( Apache2::Const::HTTP_BAD_REQUEST );
     $self->content_type('text/plain');
     $self->print("Take this job and shove it!\n", "\n", $X, "\n");
     if ($X->isa('Apache2::Controller::X')) {
        # usually you wouldn't show gory details to the user...
        $self->print(Dump($X->dump)) if $X->dump;
        $self->print($X->trace) if $X->trace;  
     }
 }

For instance 
L<Apache2::Controller::Render::Template> implements
C<< error() >> for you, which looks for
the appropriately named error template as
F<template_dir/errors/###.html>.

Of course, all exceptions are sent to the error log using
L<Log::Log4perl> DEBUG() before the handler completes, and
any refusal status greater or equal to 400 (HTTP_BAD_REQUEST) 
will be written to the access log with L<Apache2::Log> log_reason() 
using the first few characters of the error.

See L<Apache2::Controller::Session/ERRORS> for how to control
whether or not a session is saved.  Usually it is automatically
saved, but not if you have an error.

C<< error() >> does not have to roll back DBI handles if you
use L<Apache2::Controller::DBI::Connector>, as this is
rolled back automatically in the C<< PerlLogHandler >>
phase if you don't commit the transaction.

=head1 CONTROLLER CLOSURES

Apache2::Controller's package space structure lets you take advantage
of closures that access variables in your controller subclass
package space, which are cached by modperl in child processes
across independent web requests.  Be careful with that and use
Devel::Size to keep memory usage down.  I have no idea how this
would work under threaded mpm.

=head1 CONTENT TYPE

Your controller should set content type with C<< $self->content_type() >>
to something specific if you need that.  Otherwise it will let
mod_perl set it to whatever it chooses when you start to print.
This is usually text/html.

=head1 LOGGING

Apache2::Controller uses L<Log::Log4perl>.  See that module
for information on how to set up a format file or statement.
For example, in a perl startup script called at Apache2 start time,
do something like:

 use Log::Log4perl; 
     log4perl.rootLogger=DEBUG, LogFile
     log4perl.appender.LogFile=Log::Log4perl::Appender::File
     log4perl.appender.LogFile.filename=/var/log/mysite_error_log
     log4perl.appender.LogFile.layout=PatternLayout
     log4perl.appender.LogFile.layout.ConversionPattern=%M [%L]: %m%n
 };
 Log::Log4perl->init(\$logconf);

These settings will be cloned to every modperl child on fork.

=head1 MVC

Apache2::Controller provides the controller, mainly.  
L<Apache2::Controller::Render::Template> is one example
of a view that can be used as a second base with
C<use base> in your controller module.  As for the Model
part of Model-View-Controller, Apache2::Controller leaves
that entirely up to you and does not force you to
wrap anything in an abstraction class.  

The C<handler()> subroutine is in your base class and your
controller modules will be running from memory in the mod_perl
child interpreter.  So,
you can use package namespace effectively to store data
that will persist in the mod_perl child across requests.

=head1 LOAD BALANCING

A2C does not have to load 
all site modules for every page handler, which could help with load-balancing
highly optimized handlers for specific URI's while having a universal
application installer.  

Picture if you will, a programming utopia in which all engineers
are respected, highly paid and content, and managers make
correct decisions to rely on open-source software.

You deploy the same Apache, the
same CPAN modules and your whole application package to every server,
and attach a url-generating subroutine to the L<Template|Template> stash
that puts in a different hostname when the URI is one of your
load-intensive functions.  

 <a href="[% myurl('/easy') %]">easy</a> "http://pony.x.y/easy"

 <a href="[% myurl('/hard') %]">hard</a> "http://packhorse.x.y/hard"

Web designers can be taught to use this function C<< myurl() >>, 
but system admins
maintain the map that it loads to figure out what servers to use.

Then the Apache2 config files on those
packhorse servers would pre-load only the subclassed controllers
that you needed, and redirect all other uri requests to the pony servers.

=cut

use strict;
use warnings FATAL => 'all';
use English '-no_match_vars';

use base qw( Apache2::Controller::Methods );

use Readonly;
use Scalar::Util qw( blessed );
use Log::Log4perl qw(:easy);

use YAML::Syck;
use Digest::SHA qw( sha224_base64 );
use URI;
use HTTP::Status qw( status_message );
use Scalar::Util qw( looks_like_number );

use Apache2::Controller::X;
use Apache2::Controller::Funk qw( log_bad_request_reason );

use Apache2::Request;
use Apache2::RequestRec ();
use Apache2::RequestIO ();
use Apache2::RequestUtil ();
use Apache2::Log;
use Apache2::Const -compile => qw( :common :http );

=head1 FUNCTIONS

=head2 a2c_new

 $handler = MyApp::C::ControllerSubclass->a2c_new( Apache2::RequestRec object )

This is called by handler() to create the Apache2::Controller object
via the module chosen by your L<Apache2::Controller::Dispatch> subclass.

We use C<< a2c_new >> instead of the conventional C<< new >>
because, in case you want to suck in the L<Apache2::Request>
methods with that module's automagic, then you don't get
confused about how C<<SUPER::>> behaves.  Otherwise you
get into a mess of keeping track of the order of bases
so you don't call C<< Apache2::Request->new() >> by accident,
which breaks everything.

=head3 subclassing C<a2c_new()>

To set params for the L<Apache2::Request> object,
you have to subclass C<a2c_new()>.

 package MyApp::ControllerBase;
 use base qw( Apache2::Controller Apache2::Request );

 sub a2c_new {
     my ($class, $r) = @_;
     return SUPER::new(
         $class, $r,
         POST_MAX => 65_535,
         TEMP_DIR => '/dev/shm',
     );
     # $self is already blessed in the class hierarchy
 }

 package MyApp::Controller::SomeURI;
 use base qw( MyApp::ControllerBase );
 sub allowed_methods qw( uri_one uri_two );
 sub uri_one { # ...

If you need to do the same stuff every time a request
starts, you can override the constructor through a
class hierarchy.

 package MyApp::ControllerBase;
 use base qw( Apache2::Controller Apache2::Request );

 sub new {
     my ($class, $r, @apr_override_args) = @_;
     my $self = SUPER::new(
         $class, $r,
         POST_MAX => 65_535,
         TEMP_DIR => '/dev/shm',
         @apr_override_args,
     );

     # $self is already blessed in the class hierarchy

     # do request-startup stuff common to all controller modules

     return $self;
 }

 package MyApp::Controller::SomeURI;
 use base qw( MyApp::ControllerBase );
 sub allowed_methods qw( uri_one uri_two );
 sub new {
     my ($class, $r) = @_;

     my $self = SUPER::a2c_new(
        $class, $r,
     );

     # no need to bless, A2C blesses into the child class

     # do request-startup stuff for this specific controller

     return $self;
 }

 sub uri_one {
     my ($self) = @_;
     $self->content_type('image/gif');
     # ...
     return Apache2::Const::HTTP_OK;
 }
 sub uri_two { # ...

Similarly, to do something always at the end of every 
request, from within the dispatched PerlResponseHandler:

 package MyApp::Controller::SomeURI;
 use Devel::Size;
 use Log::Log4perl qw(:easy);
 my $MAX = 40 * 1024 * 1024;
 sub DESTROY {
     my ($self) = @_;
     my $size = total_size($self);  # whoo baby!
     INFO("size of $self->{class} is bigger than $MAX!") if $size > $MAX;
     return; # self is destroyed
 }

See L<USING INHERITANCE> below for more tips.

=cut

my %temp_dirs  = ( );
my %post_maxes = ( );

sub a2c_new {
    my ($class, $r, @apr_opts) = @_;

    DEBUG sub {
        "new $class, reqrec is '$r', apr_opts:\n".Dump(\@apr_opts)
    };

    my $self = {
        class       => $class,
    };

    bless $self, $class;

    DEBUG "creating Apache2::Request object";
    my $req = Apache2::Request->new( $r, @apr_opts );
    DEBUG "request object is '$req'";

    $self->{r} = $req;  # for Apache2::Request subclass automagic

    my $pnotes_a2c = $req->pnotes->{a2c} || { };

    my $method = $pnotes_a2c->{method};

    $self->{method}      = $method;
    $self->{path_args}   = $pnotes_a2c->{path_args};

    # don't instantiate the 'session' key of $self unless it's implemented
    # in some earlier stage of the apache lifecycle.
    my $session = $pnotes_a2c->{session};
    if ($session) {
        $self->{session} = $session;
        DEBUG(sub{"found and attached session to controller self:\n".Dump($session)});
        # this is the same reference as the pnotes reference still,
        # so the cleanup handler will find all changes made to it
    }

    DEBUG sub { Dump({
        # for simple debugging, stringify objects, otherwise this can get huge
        map {($_ => defined $self->{$_} ? "$self->{$_}" : undef)} keys %$self 
    }) };

    return $self;
}

=head1 METHODS

Methods are also extended by other modules in the A2C family.
See L<Apache2::Controller::Methods>.

=head2 handler

 # called from Apache, your subclass pushed to PerlResponseHandler
 # by your A2C dispatch handler:
 MyApp::Controller::Foo->handler( Apache2::RequestRec object )

The handler is pushed from an Apache2::Controller::Dispatch
subclass and via your dispatched subclass of Apache2::Controller.
It should not be set in the config file.  It looks
for the controller module name in C<< $r->pnotes->{a2c}{controller} >>
and for the method name in C<< $r->pnotes->{a2c}{method} >>.

Errors are intercepted and if the handler object was created
and implements an C<< $handler->error($exception) >> method 
then the exception will be passed as the argument.

An HTTP status code of HTTP_BAD_REQUEST or greater will 
cause log_reason to be called with a truncated error string
and the uri for recording in the access log.

=cut

my %supports_error_method = ( );

sub handler : method {
    my ($class, $r) = @_;
    return $class if !defined $r;

    my $pnotes_a2c = $r->pnotes->{a2c} || { };

    my $method = $pnotes_a2c->{method};

    DEBUG("$class -> $method");

    my ($handler, $status, $X, $used_error_method_successfully) = ( );
    eval {

        $handler = $class->a2c_new($r);
        $method  = $handler->{method};

        DEBUG("executing $class -> $method()");
        my $args = $pnotes_a2c->{path_args} || [];
        $status = $handler->$method(@{$args});
        $status = $r->status() if !defined $status;

        if (defined $status) {
            if (ref $status || !looks_like_number($status)) {
                a2cx message => "Controller returned or set non-numeric status",
                    status  => Apache2::Const::SERVER_ERROR,
                    dump    => { controller_set_status => $status };
            }
            elsif ($status < 0) {
                a2cx message => "controller must set http status >= 0",
                    status  => Apache2::Const::SERVER_ERROR,
                    dump    => { controller_set_status => $status };
            }
        }
    };
    if ($X = $EVAL_ERROR) {

        my $ref = ref($X);
        my $blessed = $ref && blessed($X);

        my $error_method_status;

        # if appropriate and able to call self->error(), do that now
        if ($handler && !$pnotes_a2c->{use_standard_errors}) {

            eval {
                if (exists $supports_error_method{$class}) {
                    $error_method_status = $handler->error($X);
                } 
                elsif ($class->can('error')) {
                    $supports_error_method{$class} = 1;
                    $error_method_status = $handler->error($X); 
                }
                $used_error_method_successfully = 1;
            };

            # trap unknown errors that might have been thrown
            # by the error() subroutine
            $X = Exception::Class->caught('Apache2::Controller::X')
                || $EVAL_ERROR 
                || $X;
        }

        my $x_status = $ref && $blessed && $X->can('status')
            ? $X->status : undef;

        $status 
          = defined $x_status               ? $x_status
          : defined $error_method_status    ? $error_method_status
          : !defined $status                ? Apache2::Const::SERVER_ERROR
          : $status == Apache2::Const::OK   ? Apache2::Const::HTTP_OK
          : Apache2::Const::SERVER_ERROR
          ;

        WARN "Exception processing status: $status";

        if ($ref && $blessed) {
            WARN sub { "dump:\n"    .Dump($X->dump)     } if $X->can('dump');
            WARN sub { "data:\n"    .Dump($X->data)     } if $X->can('data');
            WARN sub { "trace:\n"   .Dump($X->trace)    } if $X->can('trace');
            WARN "$X";
        }
        else {
            WARN("Caught an unknown error: $X");
        }
    }

    DEBUG("done with handler processing...");
    DEBUG(sub {
        my $ctype = $r->content_type();
        "content type is ".($ctype || '[undef]');
    });
    
    $r->status($status) if $status;

    DEBUG(sub { 
        my $stat  = defined $status ? $status : '';
        my $sline = $r->status_line() || '[none]';
        my $smsg  
            = defined $status 
            ? (status_message($status) || '[no msg]') 
            : 'N/A';
        my $debugstatus = defined $status ? $status : '[status not defined]';
        "status: $debugstatus ($smsg); status_line='$sline'";
    });

    if (defined $status && $status >= Apache2::Const::HTTP_BAD_REQUEST) {
        # if status is an error, file error (possibly truncated) as a 
        # log_reason in the access log for why this request was denied.
        # (is this desirable?)
        log_bad_request_reason($r, $X);
    }

    if (!defined $status) {
        return Apache2::Const::OK;
    }
    elsif ($used_error_method_successfully) {
        # if used a supplied error() method, stop the phase 
        # so Apache doesn't append its standard error messages
        # over whatever the controller already wrote.
        # unless there is a way to detect whether output has been written?
        # get the position of the output handle maybe?
        return Apache2::Const::DONE;
    }
    else {
        return $status == Apache2::Const::HTTP_OK
            ? Apache2::Const::OK
            : $status;
    }

    # supposedly you can return the http status, but it doesn't work right
    # if you return HTTP_OK.  shouldn't it?
}

=head1 USING INHERITANCE

There is no need for a predefined sequence of start-up or clean-up
routines that Apache2::Controller would have to check for in your
controller module.  

Instead, you use inheritance to streamline your code and share
common pieces, like in L<subclassing a2c_new( )> above.

If your methods need to do cleanup after finishing,
for example,
they should add a line to call a shared cleanup method.

 package MyApp::Cleanup;
 sub cleanup {
     my ($self) = @_;
     # ...
 }

 package MyApp::C::Foo;
 use base qw( Apache2::Controller Apache2::Request MyApp::Cleanup );
 sub allowed_methods {qw( foo bar )}

 sub foo {
     # ...
     $self->cleanup();
     return;
 }
 # or...
 sub bar {
     # ...
     $self->push_handler(PerlCleanupHandler => sub {
         # ...
     });
     return;
 }

Or better yet...

 package MyApp::Cleanup;
 sub DESTROY {
     my ($self) = @_;
     # ...
 }

 package MyApp::C::Foo;
 use base qw( Apache2::Controller MyApp::Cleanup );
 sub allowed_methods {qw( foo bar )}

 sub foo {
    # ...
    return;
 }

 sub bar {
    # ...
    return;
 }

There is no need for a predefined method sequence that
tries to run for each request, because Apache2 already
provides a robust abstraction of the request lifecycle
with many stages for which you can register handler subroutines.
If you can wrap your head around it, inheritance provides many 
solutions to problems for which elaborate measures are commonly 
re-invented.  For example if you wanted cleanup done the same way every 
time without having to remember that C<< $self->cleanup() >> line 
for each new
method, overload the constructor as per L<subclassing a2c_new( )> above 
and register a PerlCleanupHandler for every request instead,
or use a base with a DESTROY method.

Otherwise the framework ends up doing a lot of work every time
to ask, "did they implement this?  did they implement that?"
and that gets in your way, or you have to write those routines
every time even if they don't do anything, or whatever.  Bleah.
Implement what you want to implement from the controller methods.
The framework won't provide you with any more structure.

=head1 EXAMPLES

Browse the source package from CPAN
and check out t/lib/* and t/conf/extra.conf.last.in.

=head1 RELATED MODULES

L<Apache2::Controller::Directives>

L<Apache2::Controller::Methods>

L<Apache2::Controller::X>

L<Apache2::Controller::Dispatch>

L<Apache2::Controller::Session>

L<Apache2::Controller::DBI::Connector>

L<Apache2::Controller::Auth::OpenID>

L<Apache2::Controller::Refcard>

L<Apache2::Controller::Funk>

=head1 SEE ALSO

L<Apache2::RequestRec> and friends

L<Apache2::Request>

L<Apache2::AuthenOpenID>

L<http://perl.apache.org>

L<http://perl.apache.org/docs/2.0/user/handlers/http.html>

=head1 THANKS

Many thanks to David Ihnen, Adam Prime, André Warnier
and all the great people on the modperl mailing list.

Special thanks to Nobuo Danjou for Apache2::AuthenOpenID
which edumacated me on how the OpenID authen module
should work.

Super thanks to Roberto C. Sánchez for help packaging
up A2C for Debian distribution.

Of course, thanks to the many mod_perl and Apache authors
and all the CPAN authors whose modules this depends on.
Wow!  This stuff is so cool!

=head1 AUTHOR

Mark Hedges, C<hedges +(a t)- formdata.biz>

=head1 COPYRIGHT AND LICENSE

Copyright 2008-2010 Mark Hedges.  CPAN: markle

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

This software is provided as-is, with no warranty 
and no guarantee of fitness
for any particular purpose.


=cut

1;
