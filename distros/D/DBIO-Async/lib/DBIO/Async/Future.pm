package DBIO::Async::Future;
# ABSTRACT: The Future a caller waits on for a pool connection, blocking via Future::IO

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'Future';

use Future::IO ();
use Scalar::Util ();



sub new {
  my $proto = shift;
  my $self  = $proto->SUPER::new(@_);
  if (ref $proto and my $mark = $proto->{dbio_async_pool_wait}) {
    $self->{dbio_async_pool_wait} = $mark;
  }
  return $self;
}


sub mark_pool_wait {
  my ($self, $pool) = @_;
  my $mark = [ $pool, $self ];
  Scalar::Util::weaken($_) for @$mark;
  $self->{dbio_async_pool_wait} = $mark;
  return $self;
}


sub await {
  my $self = shift;
  return $self if $self->is_ready;

  # A pending Future of the implementation's class, made by cloning one of its
  # own: its await runs the implementation's loop until it is ready. The
  # sleep it is cloned from is left to elapse -- this dist cancels a Future in
  # one place only (Storage _let_go, t/13) -- and the tick is never cancelled,
  # only dropped with this Future when the wait dies.
  my $tick = Future::IO->sleep(0)->new;

  $self->on_ready(sub { $tick->done unless $tick->is_ready });

  my $ok = eval { $tick->await; 1 };
  my $error = $@;
  return $self if $ok;

  $self->_withdraw_dying_wait($error);
  die $error;
}

sub _withdraw_dying_wait {
  my ($self, $error) = @_;
  my $mark = $self->{dbio_async_pool_wait} or return;
  my ($pool, $waiter) = @$mark;
  return unless $pool && $waiter;
  $waiter->fail($error) if $pool->_withdraw_waiter($waiter);
  return;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Async::Future - The Future a caller waits on for a pool connection, blocking via Future::IO

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The waiter L<DBIO::Async::Pool> queues when a caller has to wait for a
connection (L<DBIO::Async::Pool/_new_waiter>). It is a plain
L<Future> in every respect but two:

=over 4

=item * B<Blocking drives the loop.> Every C<< ->then >> off a pending Future
is made with that Future's own C<new>, so the whole chain a caller builds on the
wait -- the Future C<acquire> returns, the query chained off it, the Future a
sync storage method finally C<< ->get >>s (ADR 0001) -- is of this class. A plain
Future knows no event loop and croaks I<is not yet complete and does not provide
-E<gt>await> on a C<get> while pending. Here L</await> drives L<Future::IO>
instead: on whichever implementation is loaded, the built-in one or a
C<Future::IO::Impl::*>, with no event loop required.

=item * B<A blocking wait that dies takes its waiter back.> When the loop cannot
go on -- the built-in implementation dies with I<Cowardly refusing to sit idle
and do nothing> when nothing is on it, which is the sync call made inside a
transaction block of a pool of one, whose holder is the caller itself -- the
waiter is withdrawn from the pool's queue
(L<DBIO::Storage::PoolBase/_withdraw_waiter>) and failed with the error, and the
error goes on to the caller. Left queued, the next release would hand the
connection to a waiter nobody reads, and the pool would be wedged.

=back

Callers that stay asynchronous see a Future like any other; nothing here is
involved unless C<get> or C<await> is called on a pending one. What an
implementation does with the poll that C<await> makes is its own (the built-in
one dies on a loop with nothing on it; under a real loop the same case hangs, as
the loop is never asked to stop) -- see
L<DBIO::Async::Storage/FUTURE::IO IMPLEMENTATIONS>.

=head1 METHODS

=head2 new

  my $waiter  = DBIO::Async::Future->new;
  my $derived = $waiter->new;

As a class method, a plain pending Future. On an instance, a new one that
carries the instance's pool mark along (L</mark_pool_wait>), the way
L<IO::Async::Future> carries its loop: every Future derived with C<then> from a
pool wait knows the wait it hangs off.

=head2 mark_pool_wait

  $waiter->mark_pool_wait($pool);

Records on the waiter, and so on everything derived from it, the pool that
queued it. The pool and the waiter are held B<weakly>: the pool holds the
waiter in its queue, and a Future derived from it must not keep either alive.
Returns the waiter.

=head2 await

  $future->await;

Blocks until the Future is ready, running L<Future::IO> -- one made-up pending
Future of the loaded implementation's own class (cloned from a C<sleep>, so
the C<await> is the implementation's) that is resolved when this one settles,
awaited. Does not throw on a failed Future, as C<await> in L<Future> does not.

If the implementation dies while it waits, the waiter this Future hangs off is
withdrawn from its pool and failed, if it is still queued, and the error is
rethrown (see L</DESCRIPTION>).

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
