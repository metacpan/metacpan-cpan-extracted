=head1 NAME

Coro::Event - do events the coro-way, with Event

=head1 SYNOPSIS

 use Coro;
 use Coro::Event;

 sub keyboard : Coro {
    my $w = Coro::Event->io(fd => \*STDIN, poll => 'r');
    while() {
       print "cmd> ";
       my $ev = $w->next; my $cmd = <STDIN>;
       unloop unless $cmd ne "";
       print "data> ";
       my $ev = $w->next; my $data = <STDIN>;
    }
 }

 loop;

 # wait for input on stdin for one second
 Coro::Event::do_io (fd => \*STDIN, timeout => 1) & Event::Watcher::R
    or die "no input received";

 # use a separate thread for event processing, if impossible in main:
 Coro::async { Event::loop };

=head1 DESCRIPTION

This module enables you to create programs using the powerful Event model
(and module), while retaining the linear style known from simple or
threaded programs.

This module provides a method and a function for every watcher type
(I<flavour>) (see L<Event>). The only difference between these and the
watcher constructors from Event is that you do not specify a callback
function - it will be managed by this module.

Your application should just create all necessary threads and then call
C<Event::loop>.

Please note that even programs or modules (such as L<Coro::Handle>) that
use "traditional" event-based/continuation style will run more efficient
with this module then when using only Event.

=head1 WARNING

Please note that Event does not support multithreading. That means that
you B<MUST NOT> block in an event callback. Again: In Event callbacks,
you I<must never ever> call a Coro function that blocks the current
thread.

While this seems to work superficially, it will eventually cause memory
corruption and often results in deadlocks.

Best practise is to always use B<Coro::unblock_sub> for your callbacks.

=head1 SEMANTICS

Whenever Event blocks (e.g. in a call to C<one_event>, C<loop> etc.),
this module cede's to all other threads with the same or higher
priority. When any threads of lower priority are ready, it will not
block but run one of them and then check for events.

The effect is that coroutines with the same or higher priority than
the blocking coroutine will keep Event from checking for events, while
coroutines with lower priority are being run, but Event checks for new
events after every cede. Note that for this to work you actually need to
run the event loop in some thread.

=head1 FUNCTIONS

=over 4

=cut

package Coro::Event;

use common::sense;

use Carp;

use Coro;
use Event qw(loop unloop); # we are re-exporting this for historical reasons

use XSLoader;

use base Exporter::;

our @EXPORT = qw(loop unloop sweep);

BEGIN {
   our $VERSION = 6.511;

   local $^W = 0; # avoid redefine warning for Coro::ready;
   XSLoader::load __PACKAGE__, $VERSION;
}

=item $w = Coro::Event->flavour (args...)

Create and return a watcher of the given type.

Examples:

  my $reader = Coro::Event->io (fd => $filehandle, poll => 'r');
  $reader->next;

=cut

=item $w->next

Wait for and return the next event of the event queue of the watcher. The
returned event objects support two methods only: C<hits> and C<got>, both
of which return integers: the number this watcher was hit for this event,
and the mask of poll events received.

=cut

=item do_flavour args...

Create a watcher of the given type and immediately call it's next method,
returning the event.

This is less efficient then calling the constructor once and the next
method often, but it does save typing sometimes.

=cut

for my $flavour (qw(idle var timer io signal)) {
   push @EXPORT, "do_$flavour";
   my $new = \&{"Event::$flavour"};
   my $class = "Coro::Event::$flavour";
   my $type = $flavour eq "io" ? 1 : 0;
   @{"${class}::ISA"} = (Coro::Event::, "Event::$flavour");
   my $coronew = sub {
      # how does one do method-call-by-name?
      # my $w = $class->SUPER::$flavour(@_);

      shift eq Coro::Event::
         or croak "event constructor \"Coro::Event->$flavour\" must be called as a static method";

      my $w = $new->($class,
         desc   => $flavour,
         @_,
         parked => 1,
      );

      _install_std_cb $w, $type;
      
      # reblessing due to Event being broken
      bless $w, $class
   };
   *{    $flavour } = $coronew;
   *{"do_$flavour"} = sub {
      unshift @_, Coro::Event::;
      @_ = &$coronew;
      &Coro::schedule while &_next;
      $_[0]->cancel;
      &_event
   };
}

# do schedule in perl to avoid forcing a stack allocation.
# this is about 10% slower, though.
sub next($) {
   &Coro::schedule while &_next;
   &_event
}

sub Coro::Event::Event::hits { $_[0][3] }
sub Coro::Event::Event::got  { $_[0][4] }

=item sweep

Similar to Event::one_event and Event::sweep: The idle task is called once
(this has the effect of jumping back into the Event loop once to serve new
events).

The reason this function exists is that you sometimes want to serve events
while doing other work. Calling C<Coro::cede> does not work because
C<cede> implies that the current coroutine is runnable and does not call
into the Event dispatcher.

=cut

sub sweep {
   Event::one_event 0; # for now
}

# very inefficient
our $IDLE = new Coro sub {
   while () {
      Event::one_event;
      Coro::schedule if Coro::nready;
   }
};
$IDLE->{desc} = "[Event idle thread]";

$Coro::idle = $IDLE;

1;

=back

=head1 AUTHOR/SUPPORT/CONTACT

   Marc A. Lehmann <schmorp@schmorp.de>
   http://software.schmorp.de/pkg/Coro.html

=cut

