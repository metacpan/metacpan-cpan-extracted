
package Continuity::RequestHolder;
use strict;
use vars qw( $AUTOLOAD );

=for comment

We've got three layers of abstraction here.  Looking at things from the
perspective of the native Web serving platform and moving towards
Continuity's guts, we have:

* Either HTTP::Request or else the FastCGI equiv.

* Continuity::Adapter::HttpServer::Request and 
  Continuity::Adapter::FCGI::Request both present a uniform interface
  to the first type of object, and do HTTP protocol stuff not implemented
  by them, such as parsing GET parameters.
  This of this as the "Continuity::Request" object, except

* Continuity::RequestHolder (this object) is a simple fixed object for 
  the Continuity code hold to hold onto, that knows how to read
  the second sort of object (eg, C::A::H::Request) from a queue and
  delegates calls most tasks to that object.

We should move as much into here as possible, since it is used by all the
different Adaptors.

=cut

# Accessors

# This holds our current request
sub request { exists $_[1] ? $_[0]->{request} = $_[1] : $_[0]->{request} }

# Our queue of incoming requests
sub request_queue { exists $_[1] ? $_[0]->{request_queue} = $_[1] : $_[0]->{request_queue} }

# Used by the mapper to identify the whole queue
sub session_id { exists $_[1] ? $_[0]->{session_id} = $_[1] : $_[0]->{session_id} }

sub debug_level { exists $_[1] ? $_[0]->{debug_level} = $_[1] : $_[0]->{debug_level} }         # Debug level (integer)

sub debug_callback { exists $_[1] ? $_[0]->{debug_callback} = $_[1] : $_[0]->{debug_callback} }         # Debug callback

sub new {
    my $class = shift;
    my %args = @_;
    exists $args{$_} or warn "new_requestHolder wants $_ as a parameter"
        for qw/request_queue session_id/;
    $args{request} = undef;
    my $self = { %args };
    bless $self, $class;
    $self->Continuity::debug(2,"  ReqHolder: created, session_id: $args{session_id}");
    bless $self;
}

sub next {
    # called by the user's program from the context of their coroutine
    my $self = shift;

    go_again:

    # If we still have an open request, close it
    if($self->request) {
      $self->Continuity::debug(2,"Closing old req: " . $self->request);
      $self->request->end_request;
    }

    $self->{headers_sent} = 0;

    # Here is where we actually wait for the next request
    $self->request($self->request_queue->get);

    if($self->request->immediate) {
        goto go_again;
    }

    $self->Continuity::debug(2,"-----------------------------");

    return $self;
}

sub print {
    my $self = shift; 
    if(!$self->{headers_sent}) {
      $self->request->send_basic_header();
      $self->{headers_sent} = 1;
    }
    $self->request->print(@_);
    return $self;
}

sub send_headers {
    my $self = shift; 
    $self->{headers_sent} = 1;
    $self->request->print(@_);
    return $self;
}

# If we don't know how to do something, pass it on to the current continuity_request

sub AUTOLOAD {
  # XXX always does scalar context... should do list/sclar as appropriate
  my $method = $AUTOLOAD; $method =~ s/.*:://;
  return if $method eq 'DESTROY';
  my $self = shift;
  my (@retval) = eval { 
    $self->request->can($method)
      or die "request object doesn't implemented requested method\n"; 
    $self->request->can($method)->($self->request, @_); 
  };
  if($@) {
    $self->Continuity::debug(1, "Continuity::RequestHolder::AUTOLOAD: Error delegating method ``$method'': $@");
  }
  return wantarray ? @retval : $retval[0];
}

1;

