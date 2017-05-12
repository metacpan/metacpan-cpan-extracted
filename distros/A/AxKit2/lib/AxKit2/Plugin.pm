# Copyright 2001-2006 The Apache Software Foundation
#
# Licensed under the Apache License, Version 2.0 (the "License");
# you may not use this file except in compliance with the License.
# You may obtain a copy of the License at
#
#     http://www.apache.org/licenses/LICENSE-2.0
#
# Unless required by applicable law or agreed to in writing, software
# distributed under the License is distributed on an "AS IS" BASIS,
# WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
# See the License for the specific language governing permissions and
# limitations under the License.
#

# Base class for AxKit2 plugins

package AxKit2::Plugin;

use strict;
use warnings;

use AxKit2::Config;
use AxKit2::Constants;
use Attribute::Handlers;

# more or less in the order they will fire
# DON'T FORGET - edit "AVAILABLE HOOKS" below.
our @hooks = qw(
    logging connect pre_request post_read_request body_data uri_translation
    mime_map access_control authentication authorization fixup write_body_data
    xmlresponse response response_sent disconnect error
);
our %hooks = map { $_ => 1 } @hooks;

sub new {
    my $proto = shift;
    my $class = ref($proto) || $proto;
    bless ({}, $class);
}

sub register_hook {
    my ($self, $hook, $method, $unshift) = @_;
    
    $self->log(LOGDEBUG, "register_hook: $hook => $method");
    die $self->plugin_name . " : Invalid hook: $hook" unless $hooks{$hook};
    
    push @{$self->{__hooks}{$hook}}, sub {
        my $self = shift;
        local $self->{_hook} = $hook;
        local $self->{_client} = shift;
        local $self->{_config} = shift;
        $self->$method(@_);
    };
}

sub register_config {
    my ($self, $key, $store) = @_;
    
    AxKit2::Config->add_config_param($key, \&AxKit2::Config::TAKEMANY, $store);
}

our %validators;
sub Validate : ATTR(CODE) {
    my ($package, $symbol, $referent, $attr, $data, $phase) = @_;
    $validators{$referent} = $data;
}

# default configuration handler
our $AUTOLOAD;
sub AUTOLOAD {
    die "Undefined subroutine &$AUTOLOAD called" unless $AUTOLOAD =~ m/::conf_[^:]*$/;
    shift;
    return @_;
}

sub _set_config {
    my ($self, $key, $config, @value) = @_;
    no strict 'refs';
    my $sub = "conf_$key";
    $self->{_config} = $config;
    @value = $self->$sub(@value) if $sub;
    delete $self->{_config};
    return if (!@value);
    $config->notes($self->plugin_name.'::'.$key,@value);
}

sub _register_config {
    my $self = shift;
    no strict 'refs';
    foreach my $key (keys %{*{ref($self)."::"}}) {
        next unless $key =~ m/^conf_/ && $self->can($key);
        my $sub = $self->can($key);
        my $validator = $validators{$sub} || \&AxKit2::Config::TAKEMANY;
        $validator = \&{"AxKit2::Config::$validator"} if (ref($validator) ne 'CODE');
        $key =~ s/^conf_//;
        AxKit2::Config->add_config_param($key, $validator, sub { $self->_set_config($key,@_) });
    }
}

sub _register {
    my $self = shift;
    $self->init();
    $self->_register_config();
    $self->_register_standard_hooks();
    $self->register();
}

sub init {
    # implement in plugin
}

sub register {
    # implement in plugin
}

sub config {
    my $self = shift;
    if (@_) {
        my $key = shift;
        return $self->{_config}->notes($self->plugin_name . "::$key", @_);
    }
    $self->{_config};
}

sub client {
    my $self = shift;
    $self->{_client} || "AxKit2::Client";
}

sub log {
    my $self = shift;
    my $level = shift;
    my ($package) = caller;
    if ($package eq __PACKAGE__ || !defined $self->{_hook}) {
        $self->client->log($level, $self->plugin_name, " ", @_);
    }
    else {
        $self->client->log($level, $self->plugin_name, " $self->{_hook} ", @_);
    }
}

sub _register_standard_hooks {
    my $self = shift;
    
    for my $hook (@hooks) {
        my $hooksub = "hook_$hook";
        $hooksub  =~ s/\W/_/g;
        $self->register_hook( $hook, $hooksub ) if ($self->can($hooksub));
    }
}

sub hooks {
    my $self = shift;
    my $hook = shift;
    
    return $self->{__hooks}{$hook} ? @{$self->{__hooks}{$hook}} : ();
}

sub _compile {
    my ($class, $plugin, $package, $file) = @_;
    
    my $sub;
    open F, $file or die "could not open $file: $!";
    { 
      local $/ = undef;
      $sub = <F>;
    }
    close F;

    my $line = "\n#line 0 $file\n";

    my $eval = join(
                    "\n",
                    "package $package;",
                    'use AxKit2::Constants;',
                    'use AxKit2::Processor;',
                    'use base "AxKit2::Plugin";',
                    'use strict;',
                    "sub plugin_name { qq[$plugin] }",
                    'sub hook_name { return shift->{_hook}; }',
                    $line,
                    $sub,
                    "\n", # last line comment without newline?
                   );

    #warn "eval: $eval";

    $eval =~ m/(.*)/s;
    $eval = $1;

    eval $eval;
    die "eval $@" if $@;
}

1;

__END__

=head1 NAME

AxKit2::Plugin - base class for all plugins



=head1 DESCRIPTION

An AxKit2 plugin allows you to hook into various parts of processing requests
and modify the behaviour of that request. This class is the base class for all
plugins and this document covers both the details of the base class, and the
available hooks and the consequences the return codes for those hooks have.

See L</AVAILABLE HOOKS> for the hooks, and L</API> for the API provided to all
plugins.



=head1 WRITING A SIMPLE PLUGIN

Most plugin authors should start at L<AxKit2::Docs::WritingPlugins>. However
a hook consists of the following things:

=over 4

=item * An C<init()> method for initialising state.

=item * A C<register()> method for registering hooks outside of
the default naming scheme.

=item * A number of C<conf_*()> methods to define configuration directives.

=item * A number of C<hook_*()> methods to implement your hooks.

=item * Any number of helper methods.

=back

Although plugins are classes, they do not need the usual perl extra stuff such
as a C<package> declaration, a I<constructor> (such as C<new()>), nor do they
require the annoying "C<1;>" at the end of the file. AxKit2 adds those things
in for you.

All plugins are simple blessed hashes.



=head1 API

Methods marked I<virtual> below can be implemented in your plugin and will be
called at the appropriate times by the AxKit2 framework.

=head2 C<< $plugin->register >> I<(virtual)>

Called when the plugin is initialised, and should be used to call
C<< $plugin->register_hook(...) >>. However see L</AVAILABLE HOOKS> regarding
naming hook methods so they are automatically registered.

Example:

    sub register {
        my $self = shift;
        $self->register_hook('response' => 'hook_response1');
        $self->register_hook('response' => 'hook_response2');
    }

=head2 C<< $plugin->register_hook( HOOK_NAME => METHOD_NAME ) >>

Register method C<METHOD_NAME> to be called for hook C<HOOK_NAME>.

=head2 C<< $plugin->init() >> I<(virtual)>

Called when the plugin is compiled/loaded. Use this to do any per-plugin setup.

Example:

    sub init {
        my $self = shift;
        $self->{dhb} = DBI->connect(...);
    }

=head2 C<< $plugin->config >>

Retrieve the current config object. See L<AxKit2::Config>. If you pass the name of
a configuration directive I<of your own plugin>, you can get/set values directly
without bothering about name clashes with other plugins.

If you call this method in array context, it will return a list of all values that
were set, or the empty list if nothing was configured. In scalar context, only the
first value is returned.

If you pass a list following the directive name, these values replace the current values.

Directives of other plugins can be accessed through C<< $plugin->config->notes('<package name>::<directive name>') >>.

=head2 C<< $plugin->client >>

Retrieve the current client object. See L<AxKit2::Connection>.

WARNING: This object goes out of scope outside of the hook. See
F<plugins/aio/serve_file> for an example of where this might become relevant.

=head2 C<< $plugin->log( LEVEL, MESSAGE ) >>

Write a log message. Gets passed to whatever logging plugins are loaded.

=head2 C<< $plugin->plugin_name >>

Retrieve the name of this plugin

=head2 C<< $plugin->hook_name >>

Retrieve the name of the currently executing hook

=head1 CONFIGURATION DIRECTIVES

Any sub named C<< conf_E<lt>nameE<gt> >> is taken as a configuration directive. If you simply
declare a sub without supplying the function body, AxKit will store any
values given in C<< $self->config('E<lt>nameE<gt>') >>, supporting multiple values at once.

This declaration:

    sub conf_foo_bar;

will create this entry:

    $self->config('foo_bar');

and can be used in a variety of ways in the config file:

    FooBar demo
    foobar demo
    fOObAR demo
    foo-bar demo
    foo_bar demo
    FOo_bAr demo

which are all equivalent.

This CamelCase declaration:

    sub conf_FooBar;

will create this entry:

    $self->config('FooBar');

and will have I<exactly> the same config file syntax as the previous example.

By default, multiple values are accepted and stored, while quoting is supported:

    FooBar demo1 demo2 "demo 3"

For different ways of parsing/validating configuration directives, you can add
a custom validation routine:

    # use predefined "only one argument allowed" validator
    sub FooBar : Validate(TAKE1);
    
    # this directive takes a comma separated list of values
    sub FooBar : Validate(sub { split(/,/,shift); });

If you want to have custom actions when the directive is parsed, supply a function body:

    # store a database connection instead
    sub FooBar { my ($self, $value) = @_; return DBI->connect($value); }
    
    # preprocess parameters
    sub FooBar { my ($self, @values) = @_; return join(",",@values); }
    
    # return empty list means: don't store anything
    sub FooBar { my ($self, @values) = @_; return (); }

Of course, all this can be combined:

    # this is a rather nonsensical example, do you spot why?
    sub FooBar : Validate(sub { split(/,/,shift); }) {
        my ($self, @values) = @_;
        return join(",",@values);
    }


=head1 AVAILABLE HOOKS

In order to hook into a particular phase of the request you simply write a
method called C<hook_NAME> where C<NAME> is the name of the hook you wish to
connect to.

Example:

  sub hook_logging {

If your plugin needs to hook into the same hook more than once, you will need
to write a C<register()> method as shown above. This is usually the case if you
need continuations for some reason (such as doing asynchronous I/O).

All hooks are called as a method on an instance of the plugin object. Params
below are listed without the C<$plugin> or C<$self> object as the first param.

For some plugins returning C<CONTINUATION> is valid. For details on how
continuations work in AxKit2 see L</CONTINUATIONS> below.

In all cases below, returning C<DECLINED> means other plugins/methods for the
same hook get called. Any other return value means execution stops for that
hook.

Following are the available hooks:

=head2 logging

Params: LEVEL, ARGS

Called when something calls C<< $obj->log(...) >> within AxKit. Logger is
expected to provide a way to set log level and ignore logging below the current
level.

Return Values:

=over 4

=item * C<DECLINED> - continue on to further logging plugins

=item * Anything else - stop logging

=back


=head2 connect

Params: None

Called immediately upon connect.

Return Values:

=over 4

=item * C<OK/DECLINED> - connection is OK to go on to be processed

=item * Anything else - connection is rejected

=back


=head2 pre_request

Params: None

Called before headers are received. Useful if keep-alives are present as this
is called after a keep-alive request finishes but before the next request.


=head2 post_read_request

Params: HEADER

Called after the headers are received and parsed. Passed the C<AxKit2::HTTPHeaders>
object for the incoming headers.

Return Values:

=over 4

=item * C<OK/DECLINED> - Continue processing request if method is either
C<GET> or C<HEAD>.

=item * C<DONE> - assumes response has been sent in full. Stops processing
request.

=item * Anything else - sends the appropriate error response to the browser.

=back


=head2 body_data

Params: BREF

Called for C<POST>, C<PUT>, etc verbs as each packet of body data is received.
The param is a SCALAR reference to the data received.

Return Values:

=over 4

=item * C<OK/DECLINED> - Data received and processed.

=item * C<DONE> - End of data received - process the rest of the request.

=item * Anything else - sends the appropriate error response to the browser.

=back


=head2 uri_translation

Params: HEADERS, URI

Called to translate the URI into a filename and path_info. See
F<plugins/uri_to_file> for an example of what needs to be done.

Return Values:

=over 4

=item * C<OK/DECLINED> - Continue processing the request

=item * C<DONE> - Stop processing. Response has been sent.

=item * Anything Else - send the appropriate error response to the browser.

=back


=head2 mime_map

Params: HEADERS, FILENAME

Called to set the MIME type for the given filename. See F<plugins/fast_mime_map>
for an example of what needs to be achieved.

Return Values - see L</uri_translation> above.


=head2 access_control

Params: HEADERS

Return Values - see L</uri_translation> above.


=head2 authentication

Params: HEADERS

Return Values - see L</uri_translation> above.


=head2 authorization

Params: HEADERS

Return Values - see L</uri_translation> above.


=head2 fixup

Params: HEADERS

Return Values - see L</uri_translation> above.


=head2 xmlresponse

Params: PROCESSOR, HEADERS

If this URI is to be treated as an XML request, this hook is for you. Passed an
C<AxKit2::Processor> object and the headers.

Return Value:

=over 4

=item * C<DECLINED> - Not treated as XML. Proceed to regular response hook.

=item * C<OK> [, C<PROCESSOR>]

XML Processed. If provided with a C<PROCESSOR> runs
C<< PROCESSOR->output() >> which in the normal case causes the HTML or
XML to be output to the browser. Stops processing the request at this point.

=item * C<DONE> - Output has been sent to the browser. Stop processing.

=item * Anything Else - send the appropriate error response to the browser.

=back


=head2 response

Params: HEADERS

Main response phase. Used for sending normal responses to the client.

Return Value:

=over 4

=item * C<DECLINED> - Sends a 404 response to the browser.

=item * C<OK> or C<DONE> - Stops processing this request. Response has been
sent.

=item * Anything Else - send the appropriate error response to the browser.

=back


=head2 response_sent

Params: CODE

Called after the response has been sent to the browser. The parameter is the
response code used (e.g. 200 for OK, 404 for Not Found, etc).

The return codes for this hook are used to determine if the connection should
be kept open in a keep-alive request.

Return Value:

=over 4

=item * C<DECLINED/OK> - Use default keep-alive response depending on request
type.

=item * C<DONE> - Request was OK, but don't keep the connection open.

=item * Anything Else - ... TBD.

=back


=head2 disconnect

TBD

=head2 error

Params: ERROR

Called whenever a hook C<die()>s or returns C<SERVER_ERROR>.

Return Value:

=over 4

=item * C<DECLINED> - Use default error handler

=item * C<OK/DONE> - Error was sent to browser. Ignore.

=item * Anything Else - Send a different error to the browser.

=back


=head1 CONTINUATIONS

AxKit2 is entirely single threaded, and so it is important not to do things that
take significant runtime away from the main event loop. A simple example of this
might be looking up a request on a remote web server - while the AxKit process
waits for the response it is important to allow AxKit to continue on processing
other requests.

In order to achieve this AxKit2 uses a simplified version of a technique known
in computer science terms as a I<continuation>.

In simple english, this is a way to suspend execution of one request and
I<continue> it at an arbitrary later time.

AxKit2 has a form of continuations based on the core event loop. Some hooks can
suspend execution by returning C<CONTINUATION>, and have execution of the
request continue when some event has occured.

A typical usage of this is when you need to perform an action that may take some
time. An example of this is disk I/O - typical I/O in the common POSIX
read/write style APIs occurs in a blocking manner - when you ask for a C<read()>
the disk seeks to the position you need it to go to when it can do so and the
read is performed as soon as possible before the API call returns. This may take
very little CPU time because the OS has to wait until the disk head is in the
correct position to perform the actions requested. But it does take "clock" time
which can be put to better use responding to other requests.

In asynchronous I/O the action is requested and a callback is provided to
be called when the action has occured. This allows the event loop to continue
processing other requests while we are waiting for the disk.

This is better explained with a simple example. For this example we'll take the
C<stat()> system call in an attempt to find out if the filename we are
requesting is a directory or not. In perl we would normally perform this with
the following code:

    sub hook_response {
        my $self = shift;
        my $filename = $self->client->headers_in->filename;
        if (-d $filename) {
            ....
        }
        $self->do_something_else();
        return OK;
    }

However with AIO and continuations we can re-write that as:

    sub hook_response1 {
        my $self = shift;
        my $client = $self->shift;
        my $filename = $self->client->headers_in->filename;
        IO::AIO::aio_stat $filename, sub {
            if (-d _) {
                ...
            }
            $self->do_something_else();
            $client->finish_continuation;
        };
        return CONTINUATION;
    }
    
    sub hook_response2 {
        return DECLINED;
    }

A first read will prove one thing - AIO and continuations are a I<lot> harder
than regular procedural code. However often the performance benefits are worth
it.

In general if you need to use continuations then consult the plugins in the
F<aio/> directory, and send emails to the mailing list, as they are generally
a big source of hard to locate bugs.


=head1 SEE ALSO

L<AxKit2::Connection>

L<AxKit2::HTTPHeaders>

L<AxKit2::Constants>

L<AxKit2::Processor>

=cut
