package Continuity::Mapper;

use strict;
use warnings; # XXX -- development only
use CGI;
use Coro;
use Coro::Channel;
use Continuity::RequestHolder;
use Continuity::Inspector;

# Accessors
sub debug_level { exists $_[1] ? $_[0]->{debug_level} = $_[1] : $_[0]->{debug_level} }
sub debug_callback { exists $_[1] ? $_[0]->{debug_callback} = $_[1] : $_[0]->{debug_callback} }

=head1 NAME

Continuity::Mapper - Map a request onto a session

=head1 DESCRIPTION

This is the session dictionary and mapper. Given an HTTP request, mapper gives
said request to the correct continuation. Mapper makes continuations as needed
and stores them. Mapper may be subclassed to implement other strategies for
associating requests with continuations. The default strategy is (in limbo but
quite possibly) based on a cookie.

=head1 METHODS

=head2 $mapper = Continuity::Mapper->new( callback => sub { ... } )

Create a new session mapper.

L<Contuinity> does the following by default:

  $server = Continuity->new( 
    adapter  => Continuity::Adapter::HttpDaemon->new,
    mapper   => Continuity::Mapper->new( callback => \::main )
  );

L<Continuity::Mapper> fills in the following defaults:

    cookie_session => 'sid',
    ip_session => 0,
    path_session => 0,
    query_session => 0,
    assign_session_id => sub { join '', map int rand 10, 1..20 },

Only C<cookie_session> or C<query_session> should be set, but not both.
C<assign_session_id> specifies a call-back that generates a new session id
value for when C<cookie_session> is enabled and no cookie of the given name
(C<sid> in this example) is passed.  C<assign_session_id> likewise gets called
when C<query_session> is set but no GET/POST parameter of the specified name
(C<sid> in this example) is passed.

If you use C<query_session> to keep the user associated with their session,
every link and form in the application must be written to include the session
id. The currently assigned ID can be gotten at with C<< $request->session_id >>.

For each incoming HTTP hit, L<Continuity> must use some criteria for deciding
which execution context to send that hit to.  For each of these that are set
true, that element of the request will be used as part of the key that maps
requests to execution context (remembering that Continuity hopes to give each
user one unique execution context).  An "execution context" is just a unique
call to the whichever function is specified or passed as the callback, where
several such instances of the same function will be running at the same time,
each being paused to wait for more data or unpaused when data comes in.

In the simple case, each "user" gets their own execution context.  By default,
users are distinguished by their IP address, which is a very bad way to try to
make this distinction.  Corporate users behind NATs and AOL users (also behind
a NAT) will all appear to be the same few users.

C<path_session> may be set true to use the pathname of the request, such as
C<foo> in C<http://bar.com/foo?baz=quux>, as part of the criteria for deciding
which execution context to associate with that hit.  This makes it possible to
write applications that give one user more than one execution contexts.  This
is necessary to run server-push concurrently with push from the user back to
the server (see the examples directory) or to have sub-applications running on
the same port, each having its own state separate from the others.

Cookies aren't issued or read by L<Continuity>, but we plan to add support for
reading them.  I expect the name of the cookie to look for would be passed in,
or perhaps a subroutine that validates the cookies and returns it (possibly
stripped of a secure hash) back out.  Other code (the main application, or
another session handling module from CPAN, or whatnot) will have the work of
picking session IDs.

To get more sophisticated or specialized session ID computing logic, subclass
this object, re-implement C<get_session_id_from_hit()> to suit your needs, and
then pass in an instance of your subclass to as the value for C<mapper> in the
call to C<< Continuity->new) >>.  Here's an example of that sort of constructor
call:

  $server = Continuity->new( 
    mapper   => Continuity::Mapper::StrongRandomSessionCookies->new( callback => \::main )
  );

=cut

sub new {

  my $class = shift; 
  my $self = bless { 
      sessions => { },
      sessions_last_access => { },
      ip_session => 0,
      path_session => 0,
      cookie_session => 'sid',
      cookie_life => '+2d',
      query_session => 0,
      debug_level => 0,
      debug_callback => sub { print "@_\n" },
      assign_session_id => sub { join '', 1+int rand 9, map int rand 10, 2..20 },
      implicit_first_next => 1,
      @_,
  }, $class;
  $self->{callback} or die "Mapper: callback not set.\n";
  return $self;

}

=head2 $mapper->get_session_id_from_hit($request)

Uses the defined strategies (ip, path, cookie) to create a session identifier
for the given request. This is what you'll most likely want to override, if
anything.

$request is generally an HTTP::Request, though technically may only have a
subset of the functionality.

=cut

sub get_session_id_from_hit {
  my ($self, $request) = @_;
  my $session_id = '';
  my $sid;
  $self->Continuity::debug(2,"        URI: ", $request->uri);

  # IP based sessions
  if($self->{ip_session}) {
    my $ip = $request->headers->header('Remote-Address')
             || $request->peerhost;
    $session_id .= '.' . $ip;
  }

  # Path sessions
  if($self->{path_session}) {
    my ($path) = $request->uri =~ m{/([^?]*)};
    $path =~ s/\.//g; # ./ and / are the same thing, and hey -- we use the dot as our separator anyway
    $path ||= '/';  # needed to make it consistent
    $session_id .= '.' . $path;
  }

  # Query sessions
  if($self->{query_session}) {
    $sid = $request->param($self->{query_session}) || '';
    $self->Continuity::debug(2,"    Session: got query '$sid'");
  }

  # Cookie sessions
  if($self->{cookie_session}) {
    my $cookie = $request->get_cookie($self->{cookie_session});
    $sid = $cookie if $cookie;
    $self->Continuity::debug(2,"    Session: got cookie '$sid'") if $sid;
  }

  if(($self->{query_session} or $self->{cookie_session}) and ! $sid) {
      $sid = $self->{assign_session_id}->($request);
      $self->Continuity::debug(2,"    New SID: $sid");
      $request->set_cookie( CGI->cookie(
        -name    => $self->{cookie_session},
        -value   => $sid,
        -expires => $self->{cookie_life},
      )) if $self->{cookie_session};
  }

  $session_id .= $sid if $sid;

  $self->Continuity::debug(2," Session ID: ", $session_id);

  return $session_id;

}

=head2 $mapper->map($request)

Send the given request to the correct session, creating it if necessary.

This implementation uses the C<get_session_id_from_hit()> method of this same class
to get an identifying string from information in the request object.
This is used as an index into C<< $self->{sessions}->{$session_id} >>, which holds
a queue of pending requests for the session to process.

So actually C<< map() >> just drops the request into the correct session queue.

=cut

sub map {

  my ($self, $request, $adapter) = @_;
  my $session_id = $self->get_session_id_from_hit($request, $adapter);

  $self->{sessions_last_access}->{$session_id} = time;

  $self->Continuity::debug(2,"    Session: count " . (scalar keys %{$self->{sessions}}));

  if( ! $self->{sessions}->{$session_id} ) {
      $self->Continuity::debug(2,"    Session: No request queue for this session ($session_id), making a new one.");
      $self->{sessions}->{$session_id} = $self->new_request_queue($session_id);
  }

  my $request_queue = $self->{sessions}->{$session_id};

  $self->enqueue($request, $request_queue);

  return $request;

}

=head2 $mapper->reap($age)

Reap all sessions older than $age.

Reaping is done through the 'immediate' execution request mechanism. A special
request is sent to the session that the session executes instead of user code.
The special request then called Coro::terminate to kill itself.

=cut

sub reap {
    my $self = shift;
    my $age = shift or die "pass reap a number of seconds";
    my $sessions = $self->{sessions};
    my $sessions_last_access = $self->{sessions_last_access};
    for my $session_id (keys %$sessions ) {
        next if $sessions_last_access->{$session_id} + $age > time;
        $self->Continuity::debug(2, "Session $session_id is being reaped!");
        my $request = do {
            package Continuity::Request::Death;
            use base 'Continuity::Request';
            sub immediate { Coro::terminate(0); }
            bless { }, __PACKAGE__;
        };
        $self->enqueue($request, $sessions->{$session_id});
        delete $sessions->{$session_id};
        delete $sessions_last_access->{$session_id};
    }
}

=head2 $request_queue = $mapper->new_request_queue($session_id)

Returns a brand new session request queue, and starts a session to pull
requests out the other side.

=cut

sub new_request_queue {
  my $self = shift;
  my $session_id = shift or die;

  # Create a request_queue, and hook the adapter up to feed it
  my $request_queue = Coro::Channel->new();
  my $request_holder = Continuity::RequestHolder->new(
    request_queue  => $request_queue,
    session_id     => $session_id,
    debug_level    => $self->debug_level,
    debug_callback => $self->debug_callback,
  );

  # We need something to start pulling on the other side of this queue, so
  # we'll set that up now. It won't actually be triggered until _after_ we put
  # something in the queue though. I know, because we wouldn't be making a
  # new_request_queue unless we were about to put something into said queue :)
  async {
    local $Coro::current->{desc} = 'Continuity Session';
 
    $request_holder->next if $self->{implicit_first_next};
    $self->{callback}->($request_holder, @_);

    # Well the callback returned! So they must be done... session over.
    $request_holder->end_request();
    delete $self->{sessions}->{$session_id};
    $self->Continuity::debug(2,"Session $session_id closed");
  };

  return $request_queue;
}

=head2 $mapper->enqueue($request, $request_queue|$session_id)

Add the given request to the given request queue.

This is a good spot to override for some tricky behaviour... mostly for
pre-processing requests before they get to the session handler. This particular
implementation will optionally print the HTTP headers for you.

Currently C<die>s if the session_id doesn't map to a correct request queue, but
pass an invalid reference and it'll probably die anyway.

=cut

sub enqueue {
  my ($self, $request, $request_queue) = @_;

  # TODO: This might be one spot to hook STDOUT onto this request
  # nope, Coro changes context all the time.  any select() would soon become wrong.
 
  # if they didn't pass us an actual queue object, see if it's the session_id for one
  ref($request_queue) or $request_queue = $self->{sessions}->{$request_queue}; 
  $request_queue or die "didn't pass a valid session_id or request queue";

  # Drop the request into this end of the request_queue
  $request_queue->put($request);

  # XXX needed for FastCGI (because it is blocking...)
  cede;

}

=head2 $mapper->sessions

Returns a list of session IDs of active sessions, useful as arguments to L<Continuity::Mapper>.

=cut

sub sessions {
    return @{ $_[0]->{sesssions} };
}

=head2 $mapper->inspect($session_id, sub { ... } )

Run code in another coroutine's execution context.
The execution context includes the call stack, including all of the data returned by
L<Carp::confess>, L<Padwalker>, L<caller>, and so on.

This creates an L<Continuity::Inspector> instance and sends it over the request queue.
It's just a bit of a shorthand for the same thing.

Returns false if the session_id doesn't exist.

  my $server = Continuity->new();
  my @sessions;
  while(! @sessions) {
      @sessions = Continuity->mapper->sessions or sleep 1;
  }
  $server->mapper->inspect( $sessions[0], sub { use Carp; Carp::confess; }, );

=cut

sub inspect {
    my $self = shift;
    my $session_id = shift;
    my $callback = shift;
    exists $self->{sessions}->{$session_id} or return;
    my $inspector = Continuity::Inspector->new(callback => $callback) or die;
    $inspector->inspect($self->{sessions}->{$session_id});
}

=head1 SEE ALSO

L<Continuity>, L<Coro>

=head1 AUTHOR

  Brock Wilcox <awwaiid@thelackthereof.org> - http://thelackthereof.org/

=head1 COPYRIGHT

  Copyright (c) 2004-2014 Brock Wilcox <awwaiid@thelackthereof.org>. All
  rights reserved.  This program is free software; you can redistribute it
  and/or modify it under the same terms as Perl itself.

=cut

1;

