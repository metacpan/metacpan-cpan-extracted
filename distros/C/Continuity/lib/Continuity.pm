package Continuity;

our $VERSION = '1.6';

=head1 NAME

Continuity - Abstract away statelessness of HTTP, for stateful Web applications

=head1 SYNOPSIS

  #!/usr/bin/perl

  use strict;
  use Continuity;

  my $server = new Continuity;
  $server->loop;

  sub main {
    my $request = shift;
    $request->print("Your name: <form><input type=text name=name></form>");
    $request->next; # this waits for the form to be submitted!
    my $name = $request->param('name');
    $request->print("Hello $name!");
  }

=head1 DESCRIPTION

Continuity is a library to simplify web applications. Each session is written
and runs as a persistent application, and is able to request additional input
at any time without exiting. This is significantly different from the
traditional CGI model of web applications in which a program is restarted for
each new request.

The program is passed a C<< $request >> variable which holds the request
(including any form data) sent from the browser. In concept, this is a lot like
a C<$cgi> object from CGI.pm with one very very significant difference. At any
point in the code you can call $request->next. Your program will then suspend,
waiting for the next request in the session. Since the program doesn't actually
halt, all state is preserved, including lexicals -- getting input from the
browser is then similar to doing C<< $line = <> >> in a command-line
application.

=head1 GETTING STARTED

The first thing to make a note of is that your application is a continuously
running program, basically a self contained webserver. This is quite unlike a
CGI.pm based application, which is re-started for each new request from a
client browser. Once you step away from your CGI.pm experience this is actually
more natural (IMO), more like writing an interactive desktop or command-line
program.

Here's a simple example:

  #!/usr/bin/perl

  use strict;
  use Continuity;

  my $server = new Continuity;
  $server->loop;

  sub main {
    my $request = shift;
    while(1) {
      $request->print("Hello, world!");
      $request->next;
      $request->print("Hello again!");
    }
  }

First, check out the small demo applications in the eg/ directory of the
distribution. Sample code there ranges from simple counters to more complex
multi-user ajax applications. All of the basic uses and some of the advanced
uses of Continuity are covered there.

Here is an brief explanation of what you will find in a typical application.

Declare all your globals, then declare and create your server. Parameters to
the server will determine how sessions are tracked, what ports it listens on,
what will be served as static content, and things of that nature. You are
literally initializing a web server that will serve your application to client
browsers. Then call the C<loop> method of the server, which will get the server
listening for incoming requests and starting new sessions (this never exits).

  use Continuity;
  my $server = Continuity->new( port => 8080 );
  $server->loop;

Continuity must have a starting point when starting new sessions for your
application. The default is C<< \&::main >> (a sub named "main" in the default
global scope), which is passed the C<< $request >> handle. See the
L<Continuity::Request> documentation for details on the methods available from
the C<$request> object beyond this introduction.

  sub main {
    my $request = shift;
    # ...
  }

Outputting to the client (that is, sending text to the browser) is done by
calling the C<$request-E<gt>print(...)> method, rather than the plain C<print> used
in CGI.pm applications.

  $request->print("Hello, guvne'<br>");
  $request->print("'ow ya been?");

HTTP query parameters (both GET and POST) are also gotten through the
C<$request> handle, by calling C<$p = $request-E<gt>param('x')>, just like in
CGI.pm.

  # If they go to http://webapp/?x=7
  my $input = $request->param('x');
  # now $input is 7

Once you have output your HTML, call C<$request-E<gt>next> to wait for the next
response from the client browser. While waiting other sessions will handle
other requests, allowing the single process to handle many simultaneous
sessions.

  $request->print("Name: <form><input type=text name=n></form>");
  $request->next;                   # <-- this is where we suspend execution
  my $name = $request->param('n');  # <-- start here once they submit

Anything declared lexically (using my) inside of C<main> is private to the
session, and anything you make global is available to all sessions. When
C<main> returns the session is terminated, so that another request from the
same client will get a new session. Only one continuation is ever executing at
a given time, so there is no immediate need to worry about locking shared
global variables when modifying them.

=head1 ADVANCED USAGE

Merely using the above code can completely change the way you think about web
application infrastructure. But why stop there? Here are a few more things to
ponder.

=head2 Coro::Event

Since Continuity is based on L<Coro>, we also get to use L<Coro::Event>. This
means that you can set timers to wake a continuation up after a while, or you
can have inner-continuation signaling by watch-events on shared variables.

=head2 Multiple sessions per-user

For AJAX applications, we've found it handy to give each user multiple
sessions. In the chat-ajax-push demo each user gets a session for sending
messages, and a session for receiving them. The receiving session uses a
long-running request (aka COMET) and watches the globally shared chat message
log. When a new message is put into the log, it pushes to all of the ajax
listeners.

=head2 Lexical storage and callback links

Don't forget about those pretty little lexicals you have at your disposal.
Taking a hint from the Seaside folks, instead of regular links you could have
callbacks that trigger a anonymous subs. Your code could look like:

  use Continuity;
  use strict;
  my @callbacks;
  my $callback_count;
  Continuity->new->loop;
  sub gen_link {
    my ($text, $code) = @_;
    $callbacks[$callback_count++] = $code;
    return qq{<a href="?cb=$callback_count">$text</a>};
  }
  sub process_links {
    my $request = shift;
    my $cb = $request->param('cb');
    if(exists $callbacks[$cb]) {
      $callbacks[$cb]->($request);
      delete $callbacks[$cb];
    }
  }
  sub main {
    my $request = shift;
    my $x;
    my $link1 = gen_link('This is a link to stuff' => sub { $x = 7  });
    my $link2 = gen_link('This is another link'    => sub { $x = 42 });
    $request->print($link1, $link2);
    $request->next;
    process_links($request);
    $request->print("\$x is now: $x");
  }

=head2 Scaling

To scale a Continuity-based application beyond a single process you need to
investigate the keywords "session affinity". The Seaside folks have a few
articles on various experiments they've done for scaling, see the wiki for
links and ideas. Note, however, that premature optimization is evil. We
shouldn't even be talking about this.

=head1 EXTENDING AND CUSTOMIZING

This library is designed to be extensible but have good defaults. There are two
important components which you can extend or replace.

The Adapter, such as the default L<Continuity::Adapt::HttpDaemon>, actually
makes the HTTP connections with the client web browser. If you want to use
FastCGI or even a non-HTTP protocol, then you will use or create an Adapter.

The Mapper, such as the default L<Continuity::Mapper>, identifies incoming
requests from The Adapter and maps them to instances of your program. In other
words, Mappers keep track of sessions, figuring out which requests belong to
which session. The default mapper can identify sessions based on any
combination of cookie, IP address, and URL path. Override The Mapper to create
alternative session identification and management.

=head1 METHODS

The main instance of a continuity server really only has two methods, C<new>
and C<loop>. These are used at the top of your program to do setup and start
the server. Please look at L<Continuity::Request> for documentation on the
C<$request> object that is passed to each session in your application.

=cut

use strict;
use warnings;

use Coro;
use HTTP::Status; # to grab static response codes. Probably shouldn't be here
use Continuity::RequestHolder;
use List::Util 'first';

sub debug_level :lvalue { $_[0]->{debug_level} }         # Debug level (integer)
sub adapter :lvalue { $_[0]->{adapter} }
sub mapper :lvalue { $_[0]->{mapper} }
sub debug_callback :lvalue { $_[0]->{debug_callback} }

=head2 $server = Continuity->new(...)

The C<Continuity> object wires together an Adapter and a mapper.
Creating the C<Continuity> object gives you the defaults wired together,
or if user-supplied instances are provided, it wires those together.

Arguments:

=over 4

=item * C<callback> -- coderef of the main application to run persistently for each unique visitor -- defaults to C<\&::main>

=item * C<adapter> -- defaults to an instance of C<Continuity::Adapt::HttpDaemon>

=item * C<mapper> -- defaults to an instance of C<Continuity::Mapper>

=item * C<docroot> -- defaults to C<.>

=item * C<staticp> -- defaults to C<< sub { $_[0]->url =~ m/\.(jpg|jpeg|gif|png|css|ico|js)$/ } >>, used to indicate whether any request is for static content

=item * C<debug_level> -- Set level of debugging. 0 for nothing, 1 for warnings and system messages, 2 for request status info. Default is 1

=item * C<debug_callback> -- Callback for debug messages. Default is print.

=back

Arguments passed to the default adapter:

=over 4

=item * C<port> -- the port on which to listen

=item * C<no_content_type> -- defaults to 0, set to 1 to disable the C<Content-Type: text/html> header and similar headers

=back

Arguments passed to the default mapper:

=over 4

=item * C<cookie_session> -- set to name of cookie or undef for no cookies (defaults to 'cid')

=item * C<query_session> -- set to the name of a query variable for session tracking (defaults to undef)

=item * C<assign_session_id> -- coderef of routine to custom generate session id numbers (defaults to a simple random string generator)

=item * C<cookie_life> -- lifespan of the cookie, as in CGI::set_cookie (defaults to "+2d")

=item * C<ip_session> -- set to true to enable ip-addresses for session tracking (defaults to false)

=item * C<path_session> -- set to true to use URL path for session tracking (defaults to false)

=item * C<implicit_first_next> -- set to false to get an empty first request to the main callback (defaults to true)

=back

=cut

sub new {

  my $this = shift;
  my $class = ref($this) || $this;

  no strict 'refs';
  my $self = bless { 
    docroot => '.',   # default docroot
    mapper => undef,
    adapter => undef,
    debug_level => 1,
    debug_callback => sub { print STDERR "@_\n" },
    reload => 1, # XXX
    callback => (exists &{caller()."::main"} ? \&{caller()."::main"} : undef),
    staticp => sub { $_[0]->url =~ m/\.(jpg|jpeg|gif|png|css|ico|js)$/ },
    no_content_type => 0,
    reap_after => undef,
    allowed_methods => ['GET', 'POST'],
    @_,
  }, $class;

  use strict 'refs';

  if($self->{reload}) {
    eval "use Module::Reload";
    $self->{reload} = 0 if $@;
    $Module::Reload::Debug = 1 if $self->debug_level > 1;
  }

  # Set up the default Adapter.
  # The adapter plugs the system into a server (probably a Web server)
  # The default has its very own HTTP::Daemon running.
  if(!$self->{adapter} || !(ref $self->{adapter})) {
    my $adapter_name = 'HttpDaemon';
    if(defined &Plack::Runner::new) {
      require Continuity::Adapt::PSGI;
      $adapter_name = 'PSGI';
    }
    my $adapter = "Continuity::Adapt::" . ($self->{adapter} || $adapter_name);
    eval "require $adapter";
    die "Continuity: Unknown adapter '$adapter'\n" if $@;
    $self->{adapter} = $adapter->new(
      docroot => $self->{docroot},
      server => $self,
      debug_level => $self->debug_level,
      debug_callback => $self->debug_callback,
      no_content_type => $self->{no_content_type},
      $self->{port} ? (LocalPort => $self->{port}) : (),
      $self->{cookie_life} ? (cookie_life => $self->{cookie_life}) : (), 
    );
  }

  # Set up the default mapper.
  # The mapper associates execution contexts (continuations) with requests 
  # according to some criteria. The default version uses a combination of
  # client IP address and the path in the request.

  if(!$self->{mapper}) {

    require Continuity::Mapper;

    my %optional;
    $optional{LocalPort} = $self->{port} if defined $self->{port};
    for(qw/ip_session path_session query_session cookie_session assign_session_id 
           implicit_first_next/) {
        # be careful to pass 0 too if the user specified 0 to turn it off
        $optional{$_} = $self->{$_} if defined $self->{$_}; 
    }

    $self->{mapper} = Continuity::Mapper->new(
      debug_level => $self->debug_level,
      debug_callback => sub { print "@_\n" },
      callback => $self->{callback},
      server => $self,
      %optional,
    );

  } else {

    # Make sure that the provided mapper knows who we are
    $self->{mapper}->{server} = $self;

  }

  $self->start_request_loop;

  return $self;
}

sub start_request_loop {
  my ($self) = @_;
  async {
    local $Coro::current->{desc} = 'Continuity Request Loop';
    while(1) {
      $self->debug(3, "Getting request from adapter");
      my $r = $self->adapter->get_request;
      $self->debug(3, "Handling request");
      $self->handle_request($r);
    }
  };
}

sub handle_request {
  my ($self, $r) = @_;

  if($self->{reload}) {
    Module::Reload->check;
  }

  my $method = $r->method;
  unless(first { $_ eq $method } @{$self->{allowed_methods}}) {
    $r->conn->send_error(
      RC_BAD_REQUEST,
      "$method not supported -- only (@{$self->{allowed_methods}}) for now"
    );
    $r->conn->close;
    return;
  }

  # We need some way to decide if we should send static or dynamic
  # content.
  # To save users from having to re-implement (likely incorrectly)
  # basic security checks like .. abuse in GET paths, we should provide
  # a default implementation -- preferably one already on CPAN.
  # Here's a way: ask the mapper.

  if($self->{staticp}->($r)) {
    $self->debug(3, "Sending static content... ");
    $self->{adapter}->send_static($r);
    $self->debug(3, "done sending static content.");
    return;
  }

  # Right now, map takes one of our Continuity::RequestHolder objects (with conn and request set) and sets queue

  # This actually finds the thing that wants it, and gives it to it
  # (executes the continuation)
  $self->debug(3, "Calling map... ");
  $self->mapper->map($r);
  $self->debug(3, "done mapping.");
  $self->debug(2, "Done processing request, waiting for next\n");
}

=head2 $server->loop()

Calls Coro::Event::loop and sets up session reaping. This never returns!

=cut

no warnings 'redefine';

sub loop {
  my ($self) = @_;

  if($self->{adapter}->can('loop_hook')) {
      return $self->{adapter}->loop_hook;
  }
  
  eval 'use Coro::Event';
  $self->reaper;

  Coro::Event::loop();
}

sub reaper {
  # This is our reaper event. It looks for expired sessions and kills them off.
  # TODO: This needs some documentation at the very least
  # XXX hello?  configurable timeout?  hello?
  my $self = shift;
  async {
    local $Coro::current->{desc} = 'Session Reaper';
     my $timeout = 300;  
     $timeout = $self->{reap_after} if $self->{reap_after} and $self->{reap_after} < $timeout;
     my $timer = Coro::Event->timer(interval => $timeout, );
     while ($timer->next) {
        $self->debug(3, "debug: loop calling reap");
        $self->mapper->reap($self->{reap_after}) if $self->{reap_after};
     }
  };
  # cede once to get the reaper running
  cede;
}

# This is our internal debugging tool.
# Call it with $self->Continuity::debug(2, '...');
sub debug {
  my ($self, $level, @msg) = @_;
  my $output;
  if($self->debug_level && $level <= $self->debug_level) {
    if($level > 2) {
      my ($package, $filename, $line) = caller;
      $output .= "$package:$line: ";
    }
    $output .= "@msg";
    $self->debug_callback->($output) if $self->can('debug_callback');
  }
}

=head1 SEE ALSO

See the Wiki for development information, more waxing philosophic, and links to
similar technologies such as L<http://seaside.st/>.

Website/Wiki: L<http://continuity.tlt42.org/>

L<Continuity::Request>, L<Continuity::RequestCallbacks>, L<Continuity::Mapper>,
L<Continuity::Adapt::HttpDaemon>, L<Coro>

L<AnyEvent::DBI> and L<Coro::Mysql> for concurrent database access.

=head1 AUTHOR

  Brock Wilcox <awwaiid@thelackthereof.org> - http://thelackthereof.org/
  Scott Walters <scott@slowass.net> - http://slowass.net/
  Special thanks to Marc Lehmann for creating (and maintaining) Coro

=head1 COPYRIGHT

  Copyright (c) 2004-2014 Brock Wilcox <awwaiid@thelackthereof.org>. All
  rights reserved.  This program is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.

=cut

1;

