package Continuity::Inspector;

use strict;
use Data::Dumper;
use Coro;
use Coro::Semaphore;

# Accessors
sub debug_level { exists $_[1] ? $_[0]->{debug_level} = $_[1] : $_[0]->{debug_level} }
sub debug_callback { exists $_[1] ? $_[0]->{debug_callback} = $_[1] : $_[0]->{debug_callback} }

=head1 NAME

Continuity::Inspector

=head1 DESCRIPTION

Implements the same API as the "Request" objects created by 
L<Continuity::Adapt::HttpDaemon> and other adapters.
These faked request objects go over the request queue but instead of
containing a request from a user, they contain a request from another
part of the system.

Use L<Continuity::Mapper> instead.

=head2 C<< new(callback => sub { ... } ) >>

Call with the code to run in another coroutine's execution context.
The execution context includes the call stack, including all of the data returned by
L<Carp::confess>, L<Padwalker>, L<caller>, and so on.

One Inspector instance can be reused but can only on one context at a time or else
the locking stuff will probably go all breaky.

=cut

sub new {
  my $class = shift;
  my %args = @_;
  my $self = {
    peeks_pending => undef,
    # requester => $args{requester}, # pointless
    callback => $args{callback},
    debug_level => $args{debug_level} || 1,
    debug_callback => $args{debug_callback} || sub { print "@_\n" },
  };
  bless $self, $class;
  return $self;
}

=head2 C<< $inspector->inspect( $session_queue  ) >>

It's a bit silly that this is here but having it here helps with locking.
L<Continuity::Mapper> has a bit nicer interface to the same thing.

=cut

sub inspect {
  my $self = shift;
  my $queue = shift or return;
  $self->{peeks_pending} = Coro::Semaphore->new(0);
  $queue->put($self);
  $self->{peeks_pending}->down;
  return 1;
}

sub immediate {
  my $self = shift;
  $self->{callback}->();
  $self->{peeks_pending}->up; # ${ $self->{peeks_pending} } = 0;
  return 1;
}

# fake enough of the API that Continuity::RequestHolder doesn't blow up

sub end_request { }

sub send_basic_header { }

sub close { }

sub send_error { }

sub print {
  warn "Printing from inspector! You probably don't want this...\n";
}

1;

