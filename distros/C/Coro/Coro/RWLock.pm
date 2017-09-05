=head1 NAME

Coro::RWLock - reader/write locks

=head1 SYNOPSIS

 use Coro;

 $lck = new Coro::RWLock;

 $lck->rdlock; # acquire read lock
 $lck->unlock; # unlock lock again

 # or:
 $lck->wrlock; # acquire write lock
 $lck->tryrdlock; # try a readlock
 $lck->trywrlock; # try a write lock


=head1 DESCRIPTION

This module implements reader/write locks. A read can be acquired for
read by many coroutines in parallel as long as no writer has locked it
(shared access). A single write lock can be acquired when no readers
exist. RWLocks basically allow many concurrent readers (without writers)
OR a single writer (but no readers).

You don't have to load C<Coro::RWLock> manually, it will be loaded 
automatically when you C<use Coro> and call the C<new> constructor. 

=over 4

=cut

package Coro::RWLock;

use common::sense;

use Coro ();

our $VERSION = 6.514;

=item $l = new Coro::RWLock;

Create a new reader/writer lock.

=cut

sub new {
   # [rdcount, [readqueue], wrcount, [writequeue]]
   bless [0, [], 0, []], $_[0];
}

=item $l->rdlock

Acquire a read lock.

=item $l->tryrdlock

Try to acquire a read lock.

=cut

sub rdlock {
   while ($_[0][0]) {
      push @{$_[0][3]}, $Coro::current;
      &Coro::schedule;
   }
   ++$_[0][2];
}

sub tryrdlock {
   return if $_[0][0];
   ++$_[0][2];
}

=item $l->wrlock

Acquire a write lock.

=item $l->trywrlock

Try to acquire a write lock.

=cut

sub wrlock {
   while ($_[0][0] || $_[0][2]) {
      push @{$_[0][1]}, $Coro::current;
      &Coro::schedule;
   }
   ++$_[0][0];
}

sub trywrlock {
   return if $_[0][0] || $_[0][2];
   ++$_[0][0];
}

=item $l->unlock

Give up a previous C<rdlock> or C<wrlock>.

=cut

sub unlock {
   # either we are a reader or a writer. decrement accordingly.
   if ($_[0][2]) {
      return if --$_[0][2];
   } else {
      $_[0][0]--;
   }
   # now we have the choice between waking up a reader or a writer. we choose the writer.
   if (@{$_[0][1]}) {
      (shift @{$_[0][1]})->ready;
   } elsif (@{$_[0][3]}) {
      (shift @{$_[0][3]})->ready;
   }
}

1;

=back

=head1 AUTHOR/SUPPORT/CONTACT

   Marc A. Lehmann <schmorp@schmorp.de>
   http://software.schmorp.de/pkg/Coro.html

=cut

