package DBIO::Storage::Async::PipelineContext;
# ABSTRACT: Generic pinned-connection context for async pipeline batches

use strict;
use warnings;

our $VERSION = '0.900004';

use Carp 'croak';
use Scalar::Util ();
use DBIO::Exception ();
use namespace::clean;


sub new {
  my ($class, %args) = @_;
  die('storage required') unless $args{storage};
  die('pipeline_conn required') unless $args{pipeline_conn};
  return bless {
    storage             => $args{storage},
    pipeline_conn       => $args{pipeline_conn},
    context_owner_token => $args{storage}->_context_owner_token,
  }, $class;
}


sub storage { $_[0]->{storage} }

# Snapshot captured at construction. Never derive it later from storage/pool:
# the same backend object can own a different pool generation after disconnect.
sub _context_owner_token { $_[0]->{context_owner_token} }


sub pipeline_conn { $_[0]->{pipeline_conn} }


sub pool { $_[0]->{storage}->pool }


sub future_class { $_[0]->{storage}->future_class }


sub in_txn { 0 }


sub _context_active { ! $_[0]->{_invalidated} }

# Called by the pipeline scaffold once the synchronous batch run is over. From
# here on the bracketed connection is heading back to the pool, so the context
# must no longer accept work -- see _context_active.
sub _invalidate { $_[0]->{_invalidated} = 1; return }

sub _assert_context_active {
  my ($self) = @_;
  DBIO::Exception->throw('pipeline context is no longer active')
    unless $self->_context_active;

  my $backend = $self->storage;
  # The effective owner covers both the embedded connect path (a wired sync
  # storage) and a primary/standalone backend that provisions its own sync
  # sibling (ADR 0051, karr k204). Resolved through the shared helper so a bare
  # driver mock backend -- one that fulfils only the older _owner_storage
  # contract -- still works unchanged (ADR 0051 backward-compat addendum).
  #
  # Load-order: this context class is loaded standalone by dbio-async's
  # DBIO::Async::PipelineContext (use base ...) WITHOUT pulling
  # DBIO::Storage::Async, and a bare mock backend is not an Async subclass, so
  # Async.pm may not be loaded yet when this runs -- the helper would then be an
  # undefined subroutine (karr core k209). A compile-time
  # `use DBIO::Storage::Async` cannot fix it: Async.pm use-s this class back
  # (its line 14), so that closes a circular use. Break the cycle with a runtime
  # require, which is idempotent and safe here because the helper is only ever
  # needed at call time (dbio-perl-syntax: require to break a genuine circular
  # dependency).
  require DBIO::Storage::Async;
  my $owner = DBIO::Storage::Async::_effective_owner_of($backend);
  DBIO::Exception->throw('async context ownership cannot be proven')
    unless $owner;
  $owner->_assert_async_context_owner($self);
  return $self;
}


sub _query_async {
  my ($self, $sql, $bind) = @_;
  $self->_assert_context_active;
  return $self->_track_statement(
    $self->{storage}->_query_async_pinned($self->{pipeline_conn}, $sql, $bind)
  );
}


sub _track_statement {
  my ($self, $future) = @_;
  return $future unless Scalar::Util::blessed($future)
    && $future->can('then') && $future->can('is_ready')
    && !$future->is_ready;
  my $gate = ref($future)->new;
  $self->{storage}->_hold_derived($future->then(
    sub { $gate->done(@_) unless $gate->is_ready; return },
    sub { $gate->fail(@_) unless $gate->is_ready; return },
  ));
  push @{ $self->{_statements} }, $gate;
  return $gate;
}

# Every kept statement Future, answered or not, in the order handed out.
sub _statements { return @{ $_[0]->{_statements} || [] } }

# Every statement still open fails with the error that ended the batch.
sub _fail_open_statements {
  my ($self, $error) = @_;
  for my $gate (grep { !$_->is_ready } $self->_statements) {
    $gate->fail($error);
  }
  return;
}

# CRUD inside the batch MUST run on the connection the scaffold put into
# pipeline mode, not a fresh pooled one -- that is the whole point of the
# bracket. Each method routes through the storage's shared CRUD builder with
# the bracketed connection, so SQL generation (insert post-processing,
# select_single first-row) is not duplicated. Forwarding to
# $storage->select_async etc. would acquire a separate pool connection and run
# the query OUTSIDE the pipeline.


sub select_async {
  my $self = shift;
  $self->_assert_context_active;
  return $self->_track_statement(
    $self->{storage}->_run_crud_pinned('select', $self->{pipeline_conn}, @_)
  );
}

sub select_single_async {
  my $self = shift;
  $self->_assert_context_active;
  return $self->_track_statement(
    $self->{storage}->_run_crud_pinned('select_single', $self->{pipeline_conn}, @_)
  );
}

sub insert_async {
  my $self = shift;
  $self->_assert_context_active;
  return $self->_track_statement(
    $self->{storage}->_run_crud_pinned('insert', $self->{pipeline_conn}, @_)
  );
}

sub update_async {
  my $self = shift;
  $self->_assert_context_active;
  return $self->_track_statement(
    $self->{storage}->_run_crud_pinned('update', $self->{pipeline_conn}, @_)
  );
}

sub delete_async {
  my $self = shift;
  $self->_assert_context_active;
  return $self->_track_statement(
    $self->{storage}->_run_crud_pinned('delete', $self->{pipeline_conn}, @_)
  );
}

# No blocking counterparts. The sync form of every other DBIO async surface is
# "call the *_async twin and ->get it" -- which cannot work here: a batched
# statement's result arrives at _pipeline_sync, and the sync only runs once the
# batch coderef has returned. ->get inside the batch would therefore wait for a
# result whose delivery is waiting on the caller it is blocking. Refusing with
# the reason beats hanging the process (and beats "Can't locate object method",
# which reads like the context is simply incomplete).


sub select        { $_[0]->_no_blocking('select')        }
sub select_single { $_[0]->_no_blocking('select_single') }
sub insert        { $_[0]->_no_blocking('insert')        }
sub update        { $_[0]->_no_blocking('update')        }
sub delete        { $_[0]->_no_blocking('delete')        }

sub _no_blocking {
  my ($self, $op) = @_;
  croak "Blocking ->$op is not available inside a pipeline batch: a batched "
    . "statement resolves at the pipeline sync, which runs after the batch "
    . "coderef returns -- blocking on it here would deadlock. Call "
    . "->${op}_async and return an aggregate Future from the batch.";
}

# Delegations


sub sql_maker { my $self = shift; $self->{storage}->sql_maker(@_) }
sub debug     { my $self = shift; $self->{storage}->debug(@_)     }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::Async::PipelineContext - Generic pinned-connection context for async pipeline batches

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The batch context handed to the coderef of
L<DBIO::Storage::Async/pipeline>. Pipeline mode is B<per-connection> state:
a statement is only batched if it is sent on the very connection the
scaffold put into pipeline mode. This context is what makes that structural
instead of advisory -- it carries the bracketed connection and routes every
CRUD call through the storage's shared C<_run_crud_pinned> builder onto it,
exactly as L<DBIO::Storage::Async::TransactionContext> does for the pinned
transaction connection (dbio-async ADR 0002 / ADR 0003).

Without it, an C<*_async> call inside the batch coderef would go through the
pooled path and take a B<different> connection out of the pool -- running
outside the bracket, unbatched, and at C<< pool_size => 1 >> only after the
pipeline has released. The statements would still execute; the round-trip
economy the batch was written for would silently not happen.

The context is only valid for the synchronous run of the batch coderef: once
the coderef returns, the scaffold invalidates the context, syncs, exits
pipeline mode and releases the connection. A query issued on the context past
that point throws a L<DBIO::Exception> (C<pipeline context is no longer
active>) instead of reaching a connection that is back in the pool.

=head1 ATTRIBUTES

=head2 storage

The parent L<DBIO::Storage::Async> instance.

=head2 pipeline_conn

The connection the batch is bracketed on, for the duration of the batch
coderef.

=head2 pool

Shortcut to C<< $self->storage->pool >>. It asks the storage each time, so
it is the storage's pool as it stands now, not a record of where
L</pipeline_conn> came from: after the storage was disconnected it is another
pool, and with a transport that builds its pool lazily, calling it builds one.
The batch does not go through it -- L<DBIO::Storage::Async/pipeline> hands
L</pipeline_conn> back to the pool it acquired it from.

=head2 future_class

Shortcut to C<< $self->storage->future_class >> -- the batch coderef needs it
to build the aggregate Future it hands back
(C<< $ctx->future_class->needs_all(@futures) >>).

=head2 in_txn

Always false -- a pipeline batch is not a transaction. Bracketing a batch
issues no C<BEGIN>; each statement in it commits on its own unless the caller
opened a transaction itself.

=head1 METHODS

=head2 new

  my $ctx = DBIO::Storage::Async::PipelineContext->new(
      storage       => $storage,
      pipeline_conn => $conn,
  );

Creates a new pipeline context around the bracketed connection. Requires
C<storage> and C<pipeline_conn>.

=head2 _context_active

True while the batch coderef is running synchronously; false once the
L<DBIO::Storage::Async/pipeline> scaffold has invalidated the context (it does
so the instant the coderef returns, before the pipeline sync). A
context-bound L<DBIO::ResultSet>/L<DBIO::Row>/L<DBIO::ResultSetColumn> consults
this before routing an C<*_async> op onto the context and refuses B<loudly>
rather than silently re-issuing on a pooled connection once it is false -- the
window is exactly ADR 0003's "valid only for the synchronous run of the batch
coderef" (ADR 0045).

=head2 _query_async

Executes a raw statement on the bracketed connection through
L<DBIO::Storage::Async/_query_async_pinned>, so it is batched onto the
pipeline rather than sent on a freshly acquired pooled connection.

=head2 _track_statement

  return $batch->_track_statement($future);

Keep the Future of a statement this context hands out, and return it. The
scaffold (L<DBIO::Storage::Async/_pipeline_on_conn>) waits for every kept
statement before the connection goes back, and fails the ones still open with
the batch's error when the batch fails. A pending Future is
returned behind a gate of its own: whichever is answered first -- the
transport or the scaffold -- settles it, and the other finds it settled and
does nothing. A synchronous throw from one of the CRUD methods is not tracked:
nothing was handed out.

=head2 select_async

=head2 select_single_async

=head2 insert_async

=head2 update_async

=head2 delete_async

Same arguments and resolution shapes as the storage methods of the same names
(L<DBIO::Storage::Async/select_async> etc.), but every statement runs on the
bracketed L</pipeline_conn> through the storage's shared pinned CRUD builder,
so it is batched instead of taking a separate pooled connection. Each throws
a L<DBIO::Exception> once the context is no longer active or its ownership
cannot be proven.

=head2 select

=head2 select_single

=head2 insert

=head2 update

=head2 delete

Deliberately refused: each croaks, naming the C<*_async> form to use
instead. A batched statement only resolves at the pipeline sync, which runs
after the batch coderef has returned, so blocking on it inside the coderef
would deadlock.

=head2 sql_maker

=head2 debug

Delegate to the parent storage's C<sql_maker> and C<debug>.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
