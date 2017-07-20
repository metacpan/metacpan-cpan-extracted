=head1 NAME

Coro::SemaphoreSet - efficient set of counting semaphores

=head1 SYNOPSIS

 use Coro;

 $sig = new Coro::SemaphoreSet [initial value];

 $sig->down ("semaphoreid"); # wait for signal

 # ... some other "thread"

 $sig->up ("semaphoreid");

=head1 DESCRIPTION

This module implements sets of counting semaphores (see
L<Coro::Semaphore>). It is nothing more than a hash with normal semaphores
as members, but is more efficiently managed.

This is useful if you want to allow parallel tasks to run in parallel but
not on the same problem. Just use a SemaphoreSet and lock on the problem
identifier.

You don't have to load C<Coro::SemaphoreSet> manually, it will be loaded 
automatically when you C<use Coro> and call the C<new> constructor. 

=over 4

=cut

package Coro::SemaphoreSet;

use common::sense;

our $VERSION = 6.513;

use Coro::Semaphore ();

=item new [initial count]

Creates a new semaphore set with the given initial lock count for each
individual semaphore. See L<Coro::Semaphore>.

=cut

sub new {
   bless [defined $_[1] ? $_[1] : 1], $_[0]
}

=item $semset->down ($id)

Decrement the counter, therefore "locking" the named semaphore. This
method waits until the semaphore is available if the counter is zero.

=cut

sub down {
   # Coro::Semaphore::down increases the refcount, which we check in _may_delete
   Coro::Semaphore::down ($_[0][1]{$_[1]} ||= Coro::Semaphore::_alloc $_[0][0]);
}

#ub timed_down {
#  require Coro::Timer;
#  my $timeout = Coro::Timer::timeout ($_[2]);
#
#  while () {
#     my $sem = ($_[0][1]{$_[1]} ||= [$_[0][0]]);
#
#     if ($sem->[0] > 0) {
#        --$sem->[0];
#        return 1;
#     }
#
#     if ($timeout) {
#        # ugly as hell.
#        for (0..$#{$sem->[1]}) {
#           if ($sem->[1][$_] == $Coro::current) {
#              splice @{$sem->[1]}, $_, 1;
#              return 0;
#           }
#        }
#        die;
#     }
#
#     push @{$sem->[1]}, $Coro::current;
#     &Coro::schedule;
#  }
#

=item $semset->up ($id)

Unlock the semaphore again. If the semaphore reaches the default count for
this set and has no waiters, the space allocated for it will be freed.

=cut

sub up {
   my ($self, $id) = @_;

   my $sem = $self->[1]{$id} ||= Coro::Semaphore::_alloc $self->[0];

   Coro::Semaphore::up $sem;

   delete $self->[1]{$id}
      if _may_delete $sem, $self->[0], 1;
}

=item $semset->try ($id)

Try to C<down> the semaphore. Returns true when this was possible,
otherwise return false and leave the semaphore unchanged.

=cut

sub try {
   Coro::Semaphore::try (
      $_[0][1]{$_[1]} ||= $_[0][0] > 0
         ? Coro::Semaphore::_alloc $_[0][0]
         : return 0
   )
}

=item $semset->count ($id)

Return the current semaphore count for the specified semaphore.

=cut

sub count {
   Coro::Semaphore::count ($_[0][1]{$_[1]} || return $_[0][0]);
}

=item $semset->waiters ($id)

Returns the number (in scalar context) or list (in list context) of
waiters waiting on the specified semaphore.

=cut

sub waiters {
   Coro::Semaphore::waiters ($_[0][1]{$_[1]} || return);
}

=item $semset->wait ($id)

Same as Coro::Semaphore::wait on the specified semaphore.

=cut

sub wait {
   Coro::Semaphore::wait ($_[0][1]{$_[1]} || return);
}

=item $guard = $semset->guard ($id)

This method calls C<down> and then creates a guard object. When the guard
object is destroyed it automatically calls C<up>.

=cut

sub guard {
   &down;
   bless [@_], Coro::SemaphoreSet::guard::
}

#ub timed_guard {
#  &timed_down
#     ? bless [$_[0], $_[1]], Coro::SemaphoreSet::guard::
#     : ();
#

sub Coro::SemaphoreSet::guard::DESTROY {
   up @{$_[0]};
}

=item $semaphore = $semset->sem ($id)

This SemaphoreSet version is based on Coro::Semaphore's. This function
creates (if necessary) the underlying Coro::Semaphore object and returns
it. You may legally call any Coro::Semaphore method on it, but note that
calling C<< $semset->up >> can invalidate the returned semaphore.

=cut

sub sem {
   bless +($_[0][1]{$_[1]} ||= Coro::Semaphore::_alloc $_[0][0]),
         Coro::Semaphore::;
}

1;

=back

=head1 AUTHOR/SUPPORT/CONTACT

   Marc A. Lehmann <schmorp@schmorp.de>
   http://software.schmorp.de/pkg/Coro.html

=cut

