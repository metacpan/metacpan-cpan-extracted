=head1 NAME

Coro::Semaphore - counting semaphores

=head1 SYNOPSIS

 use Coro;

 $sig = new Coro::Semaphore [initial value];

 $sig->down; # wait for signal

 # ... some other "thread"

 $sig->up;

=head1 DESCRIPTION

This module implements counting semaphores. You can initialize a mutex
with any level of parallel users, that is, you can intialize a sempahore
that can be C<down>ed more than once until it blocks. There is no owner
associated with semaphores, so one thread can C<down> it while another can
C<up> it (or vice versa), C<up> can be called before C<down> and so on:
the semaphore is really just an integer counter that optionally blocks
when it is 0.

Counting semaphores are typically used to coordinate access to
resources, with the semaphore count initialized to the number of free
resources. Threads then increment the count when resources are added
and decrement the count when resources are removed.

You don't have to load C<Coro::Semaphore> manually, it will be loaded
automatically when you C<use Coro> and call the C<new> constructor.

=over 4

=cut

package Coro::Semaphore;

use common::sense;

use Coro ();

our $VERSION = 6.511;

=item new [inital count]

Creates a new sempahore object with the given initial lock count. The
default lock count is 1, which means it is unlocked by default. Zero (or
negative values) are also allowed, in which case the semaphore is locked
by default.

=item $sem->count

Returns the current semaphore count. The semaphore can be down'ed without
blocking when the count is strictly higher than C<0>.

=item $sem->adjust ($diff)

Atomically adds the amount given to the current semaphore count. If the
count becomes positive, wakes up any waiters. Does not block if the count
becomes negative, however.

=item $sem->down

Decrement the counter, therefore "locking" the semaphore. This method
waits until the semaphore is available if the counter is zero or less.

=item $sem->wait

Similar to C<down>, but does not actually decrement the counter. Instead,
when this function returns, a following call to C<down> or C<try> is
guaranteed to succeed without blocking, until the next thread switch
(C<cede> etc.).

Note that using C<wait> is much less efficient than using C<down>, so try
to prefer C<down> whenever possible.

=item $sem->wait ($callback)

If you pass a callback argument to C<wait>, it will not wait, but
immediately return. The callback will be called as soon as the semaphore
becomes available (which might be instantly), and gets passed the
semaphore as first argument.

The callback might C<down> the semaphore exactly once, might wake up other
threads, but is I<NOT> allowed to block (switch to other threads).

=cut

#=item $status = $sem->timed_down ($timeout)
#
#Like C<down>, but returns false if semaphore couldn't be acquired within
#$timeout seconds, otherwise true.

#sub timed_down {
#   require Coro::Timer;
#   my $timeout = Coro::Timer::timeout ($_[1]);
# 
#   while ($_[0][0] <= 0) {
#      push @{$_[0][1]}, $Coro::current;
#      &Coro::schedule;
#      if ($timeout) {
#         # ugly as hell. slow, too, btw!
#         for (0..$#{$_[0][1]}) {
#            if ($_[0][1][$_] == $Coro::current) {
#               splice @{$_[0][1]}, $_, 1;
#               return;
#            }
#         }
#         die;
#      }
#   }
# 
#   --$_[0][0];
#   return 1;
#}

=item $sem->up

Unlock the semaphore again.

=item $sem->try

Try to C<down> the semaphore. Returns true when this was possible,
otherwise return false and leave the semaphore unchanged.

=item $sem->waiters

In scalar context, returns the number of threads waiting for this
semaphore. Might accidentally cause WW3 if called in other contexts, so
don't use these.

=item $guard = $sem->guard

This method calls C<down> and then creates a guard object. When the guard
object is destroyed it automatically calls C<up>.

=cut

sub guard {
   &down;
   bless [$_[0]], Coro::Semaphore::guard::
}

#=item $guard = $sem->timed_guard ($timeout)
#
#Like C<guard>, but returns undef if semaphore couldn't be acquired within
#$timeout seconds, otherwise the guard object.

#sub timed_guard {
#   &timed_down
#      ? bless \\$_[0], Coro::Semaphore::guard::
#      : ();
#}

sub Coro::Semaphore::guard::DESTROY {
   &up($_[0][0]);
}

=back

=head1 AUTHOR/SUPPORT/CONTACT

   Marc A. Lehmann <schmorp@schmorp.de>
   http://software.schmorp.de/pkg/Coro.html

=cut

1

