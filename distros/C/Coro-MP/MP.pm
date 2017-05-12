=head1 NAME

Coro::MP - erlang-style multi-processing/message-passing framework

=head1 SYNOPSIS

   use Coro::MP;

   # exports everything that AnyEvent::MP exports as well.
   # new stuff compared to AnyEvent::MP:

   # creating/using ports from threads
   my $port = port_async {
      # thread context, $SELF is set to $port

      # returning will "kil" the $port with an empty reason
   };

   # attach to an existing port
   spawn $NODE, "::initfunc";
   sub ::initfunc {
      rcv_async $SELF, sub {
         ...
      };
   }

   # simple "tag" receives:
   my ($pid) = get "pid", 30
      or die "no pid message received after 30s";

   # conditional receive
   my ($tag, @data) = get_cond { $_[0] =~ /^group1_/ };
   my @next_msg = get_cond { 1 } 30; # 30s timeout

   # run thread in port context
   peval_async $port, {
      die "kill the port\n";
   };

   # synchronous "cal"
   my @retval = syncol 30, $port, tag => $data;

=head1 DESCRIPTION

This module (-family) implements a simple message passing framework.

Despite its simplicity, you can securely message other processes running
on the same or other hosts, and you can supervise entities remotely.

This module depends heavily on L<AnyEvent::MP>, in fact, many functions
exported by this module are identical to AnyEvent::MP functions. This
module family is simply the Coro API to AnyEvent::MP.

Care has been taken to stay compatible with AnyEvent::MP, even if
sometimes this required a less natural API (C<spawn> should indeed spawn a
thread, not just call an initfunc for example).

For an introduction to AnyEvent::MP, see the L<AnyEvent::MP::Intro> manual
page.

=head1 VARIABLES/FUNCTIONS

=over 4

=cut

package Coro::MP;

use common::sense;

use Carp ();

use AnyEvent::MP::Kernel;
use AnyEvent::MP;
use Coro;
use Coro::AnyEvent ();

use AE ();

use base "Exporter";

our $VERSION = "0.1";

our @EXPORT = (@AnyEvent::MP::EXPORT, qw(
   port_async rcv_async get get_cond syncal peval_async
));
our @EXPORT_OK = (@AnyEvent::MP::EXPORT_OK);

sub _new_coro {
   my ($port, $threadcb) = @_;

   my $coro = async_pool {
      eval { $threadcb->() };
      kil $SELF, die => $@ if $@;
   };
   $coro->swap_sv (\$SELF, \$port);

   # killing the port cancels the coro
   # delaying kil messages inside aemp guarantees
   # (hopefully) that $coro != $Coro::current.
   mon $port, sub { $coro->cancel (@_) };

   # cancelling the coro kills the port
   $coro->on_destroy (sub { kil $port, @_ });

   $coro
}

=item NODE, $NODE, node_of, configure

=item $SELF, *SELF, SELF, %SELF, @SELF...

=item snd, mon, kil, psub

These variables and functions work exactly as in AnyEvent::MP, in fact,
they are exactly the same functions, and are used in much the same way.

=item rcv

This function works exactly as C<AnyEvent::MP::rcv>, and is in fact
compatible with Coro::MP ports. However, the canonical way to receive
messages with Coro::MP is to use C<get> or C<get_cond>.

=item port

This function is exactly the same as C<AnyEvent::MP::port> and creates new
ports. You can attach a thread to them by calling C<rcv_async> or you can
do a create and attach in one operation using C<port_async>.

=item peval

This function works exactly as C<AnyEvent::MP::psub> - you could use it to
run callbacks within a port context (good for monitoring), but you cannot
C<get> messages unless the callback executes within the thread attached to
the port.

Since creating a thread with port context requires somewhta annoying
syntax, there is a C<peval_async> function that handles that for you - note
that within such a thread, you still cannot C<get> messages.

=item spawn

This function is identical to C<AnyEvent::MP::spawn>. This means that
it doesn't spawn a new thread as one would expect, but simply calls an
init function. The init function, however, can attach a new thread easily:

   sub initfun {
      my (@args) = @_;

      rcv_async $SELF, sub {
         # thread-code
      };
   }

=item cal

This function is identical to C<AnyEvent::MP::cal>. The easiest way to
make a synchronous call is to use Coro's rouse functionality:

   # send 1, 2, 3 to $port and wait up to 30s for reply
   cal $port, 1, 2, 3, rouse_cb, 30;
   my @reply = rouse_wait;

You can also use C<syncal> if you want, and are ok with learning yet
another function with a weird name:

   my @reply = syncal 30, $port, 1, 2, 3;

=item $local_port = port_async { ... }

Creates a new local port, and returns its ID. A new thread is created and
attached to the port (see C<rcv_async>, below, for details).

=cut

sub rcv_async($$);

sub port_async(;&) {
   my $id = "$UNIQ." . $ID++;
   my $port = "$NODE#$id";

   @_
      ? rcv_async $port, shift
      : AnyEvent::MP::rcv $port, undef;

   $port
}

=item rcv_async $port, $threadcb

This function creates and attaches a thread on a port. The thread is set
to execute C<$threadcb> and is put into the ready queue. The thread will
receive all messages not filtered away by tagged receive callbacks (as set
by C<AnyEvent::MP::rcv>) - it simply replaces the default callback of an
AnyEvent::MP port.

The special variable C<$SELF> will be set to C<$port> during thread
execution.

When C<$threadcb> returns or the thread is canceled, the return/cancel
values become the C<kil> reason.

It is not allowed to call C<rcv_async> more than once on a given port.

=cut

sub rcv_async($$) {
   my ($port, $threadcb) = @_;

   my (@queue, $coro);

   AnyEvent::MP::rcv $port, sub {
      push @queue, \@_; # TODO, take copy?
      $coro->ready; # TODO, maybe too many unwanted wake-ups?
   };

   $coro = _new_coro $port, $threadcb;
   $coro->{_coro_mp_queue} = \@queue;
}

=item @msg = get $tag

=item @msg = get $tag, $timeout

Find, dequeue and return the next message with the specified C<$tag>. If
no matching message is currently queued, wait up to C<$timeout> seconds
(or forever if no C<$timeout> has been specified or it is C<undef>) for
one to arrive.

Returns the message with the initial tag removed. In case of a timeout,
the empty list. The function I<must> be called in list context.

Note that empty messages cannot be distinguished from a timeout when using
C<rcv>.

Example: send a "log" message to C<$SELF> and then get and print it.

   snd $SELF, log => "text";
   my ($text) = get "log";
   print "log message: $text\n";

Example: receive C<p1> and C<p2> messages, regardless of the order they
arrive in on the port.

   my @p1 = get "p1";
   my @21 = get "p2";

Example: assume a message with tag C<now> is already in the queue and fetch
it. If no message was there, do not wait, but die.

   my @msg = get "now", 0
      or die "expected now emssage to be there, but it wasn't";

=cut

sub get($;$) {
   my ($tag, $timeout) = @_;

   my $queue = $Coro::current->{_coro_mp_queue}
      or Carp::croak "Coro::MP::get called from thread not attached to any port";

   my $i;

   while () {
      $queue->[$_][0] eq $tag
         and return @{ splice @$queue, $_, 1 }
         for $i..$#$queue;

      $i = @$queue;

      # wait for more messages
      if (ref $timeout) {
         schedule;
         defined $i or return; # timeout

      } elsif (defined $timeout) {
         $timeout or return;

         my $current = $Coro::current;
         $timeout = AE::timer $timeout, 0, sub {
            undef $i;
            $current->ready;
         };
      } else {
         $timeout = \$i; # dummy
      }
   }
}

=item @msg = get_cond { condition... } [$timeout]

Similarly to C<get>, looks for a matching message. Unlike C<get>,
"matching" is not defined by a tag alone, but by a predicate, a piece of
code that is executed on each candidate message in turn, with C<@_> set to
the message contents.

The predicate code is supposed to return the empty list if the message
didn't match. If it returns anything else, then the message is removed
from the queue and returned to the caller.

In addition, if the predicate returns a code reference, then it is
immediately called invoked on the removed message.

If a C<$timeout> is specified and is not C<undef>, then, after this many
seconds have been passed without a matching message arriving, the empty
list will be returned.

Example: fetch the next message, wait as long as necessary.

   my @msg = get_cond { 1 };

Example: fetch the next message whose tag starts with C<group1_>.

   my ($tag, @data) = get_cond { $_[0] =~ /^group1_/ };

Example: check whether a message with tag C<child_exit> and a second
elemet of C<$pid> is in the queue already.

   if (
      my (undef, $pid, $status) =
         get_cond {
            $_[0] eq "child_exit" && $_[1] == $pid
         } 0
   ) {
      warn "child $pid did exit with status $status\n";
   }

Example: implement a server that reacts to C<log>, C<exit> and C<reverse>
messages, and exits after 30 seconds of idling.

   my $reverser = port_async {
      while() {
         get_cond {
            $_[0] eq "exit" and return sub {
               last; # yes, this is valid
            };
            $_[0] eq "log" and return sub {
               print "log: $_[1]\n";
            };
            $_[0] eq "reverse" and return sub {
               my (undef, $text, @reply) = @_;
               snd @reply, scalar reverse $text;
            };

            die "unexpected message $_[0] received";
         } 30
            or last;
      }
   };

=cut

sub _true { 1 }

sub get_cond(;&$) {
   my ($cond, $timeout) = @_;

   my $queue = $Coro::current->{_coro_mp_queue}
      or Carp::croak "Coro::MP::get_cond called from thread not attached to any port";

   my ($i, $ok);

   $cond ||= \&_true;

   while () {
      do
         {
            local *_ = $queue->[$_];
            if ($ok = &$cond) {
               splice @$queue, $_, 1;
               &$ok if "CODE" eq ref $ok;
               return @_;
            }
         }
      for $i..$#$queue;

      $i = @$queue;

      # wait for more messages
      if (ref $timeout) {
         schedule;
         defined $i or return; # timeout

      } elsif (defined $timeout) {
         $timeout or return;

         my $current = $Coro::current;
         $timeout = AE::timer $timeout, 0, sub {
            undef $i;
            $current->ready;
         };
      } else {
         $timeout = \$i; # dummy
      }
   }
}

=item $async = peval_async { BLOCK }

Sometimes you want to run a thread within a port context, for error
handling.

This function creates a new, ready, thread (using C<Coro::async>), sets
C<$SELF> to the the current value of C<$SELF> while it executing, and
calls the given BLOCK.

This is very similar to C<psub> - note that while the BLOCK exeuctes in
C<$SELF> port context, you cannot call C<get>, as C<$SELF> can only be
attached to one thread.

Example: execute some Coro::AIO code concurrently in another thread, but
make sure any errors C<kil> the originating port.

   port_async {
      ...
      peval_async {
         # $SELF set, but cannot call get etc. here

         my $fh = aio_open ...
            or die "open: $!";

         aio_close $fh;
      };
   };

=cut

sub peval_async($$) {
   _new_coro $_[0], $_[1]
}

=item @reply = syncal $port, @msg, $callback[, $timeout]

The synchronous form of C<cal>, a simple form of RPC - it sends a message
to the given C<$port> with the given contents (C<@msg>), but adds a reply
port to the message.

The reply port is created temporarily just for the purpose of receiving
the reply, and will be C<kil>ed when no longer needed.

Then it will wait until a reply message arrives, which will be returned to
the caller.

If the C<$timeout> is defined, then after this many seconds, when no
message has arrived, the port will be C<kil>ed and an empty list will be
returned.

If the C<$timeout> is undef, then the local port will monitor the remote
port instead, so it eventually gets cleaned-up.

Example: call the string reverse example from C<get_cond>.

   my $reversed = syncal 1, $reverse, reverse => "Rotator";

=cut

sub syncal($@) {
   my ($timeout, @msg) = @_;

   cal @msg, Coro::rouse_cb, $timeout;
   Coro::rouse_wait
}

=back

=head1 SEE ALSO

L<AnyEvent::MP::Intro> - a gentle introduction.

L<AnyEvent::MP> - like Coro::MP, but event-based.

L<AnyEvent>.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

=cut

1

