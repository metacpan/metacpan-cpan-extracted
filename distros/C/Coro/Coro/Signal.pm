=head1 NAME

Coro::Signal - thread signals (binary semaphores)

=head1 SYNOPSIS

 use Coro;

 my $sig = new Coro::Signal;

 $sig->wait; # wait for signal

 # ... some other "thread"

 $sig->send;

=head1 DESCRIPTION

This module implements signals/binary semaphores/condition variables
(basically all the same thing). You can wait for a signal to occur or send
it, in which case it will wake up one waiter, or it can be broadcast,
waking up all waiters.

It is recommended not to mix C<send> and C<broadcast> calls on the same
C<Coro::Signal> without some deep thinking: while it should work as
documented, it can easily confuse you :->

You don't have to load C<Coro::Signal> manually, it will be loaded
automatically when you C<use Coro> and call the C<new> constructor.

=over 4

=cut

package Coro::Signal;

use common::sense;

use Coro::Semaphore ();

our $VERSION = 6.511;

=item $sig = new Coro::Signal;

Create a new signal.

=item $sig->wait

Wait for the signal to occur (via either C<send> or C<broadcast>). Returns
immediately if the signal has been sent before.

=item $sig->wait ($callback)

If you pass a callback argument to C<wait>, it will not wait, but
immediately return. The callback will be called under the same conditions
as C<wait> without arguments would continue the thrad.

The callback might wake up any number of threads, but is I<NOT> allowed to
block (switch to other threads).

=item $sig->send

Send the signal, waking up I<one> waiting process or remember the signal
if no process is waiting.

=item $sig->broadcast

Send the signal, waking up I<all> waiting process. If no process is
waiting the signal is lost.

=item $sig->awaited

Return true when the signal is being awaited by some process.

=cut

#=item $status = $s->timed_wait ($timeout)
#
#Like C<wait>, but returns false if no signal happens within $timeout
#seconds, otherwise true.
#
#See C<wait> for some reliability concerns.
#
#=cut

#ub timed_wait {
#  require Coro::Timer;
#  my $timeout = Coro::Timer::timeout($_[1]);
#
#  unless (delete $_[0][0]) {
#     push @{$_[0][1]}, $Coro::current;
#     &Coro::schedule;
#
#     return 0 if $timeout;
#  }
#
#  1
#

1;

=back

=head1 AUTHOR/SUPPORT/CONTACT

   Marc A. Lehmann <schmorp@schmorp.de>
   http://software.schmorp.de/pkg/Coro.html

=cut

