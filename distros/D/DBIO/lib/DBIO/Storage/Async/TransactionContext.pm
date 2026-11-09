package DBIO::Storage::Async::TransactionContext;
# ABSTRACT: Generic pinned-connection context for async transactions

use strict;
use warnings;

our $VERSION = '0.900004';

use DBIO::Exception ();
use Scalar::Util ();
use namespace::clean;


sub new {
  my ($class, %args) = @_;
  die('storage required') unless $args{storage};
  die('txn_conn required') unless $args{txn_conn};
  return bless {
    storage             => $args{storage},
    txn_conn            => $args{txn_conn},
    context_owner_token => $args{storage}->_context_owner_token,
  }, $class;
}


sub storage { $_[0]->{storage} }

# Snapshot captured at construction. Never derive it later from storage/pool:
# the same backend object can own a different pool generation after disconnect.
sub _context_owner_token { $_[0]->{context_owner_token} }


sub txn_conn { $_[0]->{txn_conn} }


sub pool { $_[0]->{storage}->pool }


sub in_txn { return $_[0]->_context_active ? 1 : 0 }


sub _context_active { return $_[0]->{_invalidated} ? 0 : 1 }

# The transaction has ended: nothing waits on its statements any more, and
# the context lists none. A statement still in flight keeps its Future all the
# same, until it is answered (karr k292). The context ends as ROLLBACK goes
# out, or in the finalizer on a connection nothing is waited for on -- before
# such a statement has its answer -- and the context may be that Future's only
# holder: a ->then sequence is held weakly by the Future it was made off, and
# Future.pm warns "lost a sequence Future" when the answer finds it gone. For
# a pipeline run on the transaction, that sequence is the one that leaves
# pipeline mode.
#
# So each Future is handed to itself: Future.pm's retain keeps a Future until
# it is ready -- done, failed or cancelled -- and lets go of it then, at once
# for one that is ready already. Asked through can(), as txn_do_async asks for
# its own Future: a class without retain (DBIO::Test::Future) holds a chain
# from its head and needs none.
sub _invalidate {
  my ($self) = @_;
  $self->{_invalidated} = 1;
  my $statements = delete $self->{_txn_statements} or return;
  for my $future (@$statements) {
    $future->retain if $future->can('retain');
  }
  return;
}

sub _assert_context_active {
  my ($self) = @_;
  DBIO::Exception->throw('transaction context is no longer active')
    unless $self->_context_active;

  my $backend = $self->storage;
  # The effective owner covers both the embedded connect path (a wired sync
  # storage) and a primary/standalone backend that provisions its own sync
  # sibling (ADR 0051, karr k204). Resolved through the shared helper so a bare
  # driver mock backend -- one that fulfils only the older _owner_storage
  # contract -- still works unchanged (ADR 0051 backward-compat addendum).
  #
  # Load-order: this context class is loaded standalone by dbio-async's
  # DBIO::Async::TransactionContext (use base ...) WITHOUT pulling
  # DBIO::Storage::Async, and a bare mock backend (above) is not an Async
  # subclass, so Async.pm may not be loaded yet when this runs -- the helper
  # would then be an undefined subroutine (karr core k209). A compile-time
  # `use DBIO::Storage::Async` cannot fix it: Async.pm use-s this class back
  # (its line 13), so that closes a circular use. Break the cycle with a
  # runtime require, which is idempotent and safe here because the helper is
  # only ever needed at call time (dbio-perl-syntax: require to break a genuine
  # circular dependency).
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
    $self->{storage}->_query_async_pinned($self->{txn_conn}, $sql, $bind)
  );
}

# CRUD inside a transaction MUST run on the pinned connection that
# BEGIN/COMMIT ran on, not a fresh pooled one. Each method routes
# through the storage's shared CRUD builder with the pinned connection,
# so SQL generation (insert post-processing, select_single first-row)
# is not duplicated. Forwarding to $storage->select_async etc. would
# acquire a separate pool connection and run the query OUTSIDE the
# transaction.


sub select_async {
  my $self = shift;
  $self->_assert_context_active;
  return $self->_track_statement(
    $self->{storage}->_run_crud_pinned('select', $self->{txn_conn}, @_)
  );
}

sub select_single_async {
  my $self = shift;
  $self->_assert_context_active;
  return $self->_track_statement(
    $self->{storage}->_run_crud_pinned('select_single', $self->{txn_conn}, @_)
  );
}

sub insert_async {
  my $self = shift;
  $self->_assert_context_active;
  return $self->_track_statement(
    $self->{storage}->_run_crud_pinned('insert', $self->{txn_conn}, @_)
  );
}

sub update_async {
  my $self = shift;
  $self->_assert_context_active;
  return $self->_track_statement(
    $self->{storage}->_run_crud_pinned('update', $self->{txn_conn}, @_)
  );
}

sub delete_async {
  my $self = shift;
  $self->_assert_context_active;
  return $self->_track_statement(
    $self->{storage}->_run_crud_pinned('delete', $self->{txn_conn}, @_)
  );
}

# Sync fallbacks -- block the event loop via ->get


sub select             { my $self = shift; $self->select_async(@_)->get        }
sub select_single      { my $self = shift; $self->select_single_async(@_)->get }
sub insert             { my $self = shift; $self->insert_async(@_)->get        }
sub update             { my $self = shift; $self->update_async(@_)->get        }
sub delete             { my $self = shift; $self->delete_async(@_)->get        }

# Delegations


sub sql_maker    { my $self = shift; $self->{storage}->sql_maker(@_)    }
sub debug        { my $self = shift; $self->{storage}->debug(@_)        }

sub pipeline {
  my ($self, $coderef) = @_;
  $self->_assert_context_active;
  if (my $refusal = $self->{storage}->_pipeline_refusal) {
    return $refusal;
  }
  # No $release: the transaction boundary hands the connection back. A $retire
  # that marks it instead, for that boundary to act on (karr k232).
  my $batch = $self->{storage}->_pipeline_on_conn(
    $self->{txn_conn}, $coderef, undef,
    sub { $self->_mark_txn_conn_unusable(@_) },
  );
  # Kept apart from the statements: the context lets go of those as it ends,
  # and the transaction's ROLLBACK waits for these (karr k331). Weakly -- what
  # holds the Future until it is ready is _track_statement and its retain
  # (karr k292); a context still in hand must not hold it any longer.
  if (Scalar::Util::blessed($batch) && $batch->can('catch')) {
    push @{ $self->{_txn_pipelines} }, $batch;
    Scalar::Util::weaken($self->{_txn_pipelines}[-1]);
  }
  return $self->_track_statement($batch);
}


sub _mark_txn_conn_unusable {
  my ($self, $error) = @_;
  $self->{_txn_conn_unusable} = 1;
  $self->{_txn_conn_unusable_error} = $error
    if defined $error && !defined $self->{_txn_conn_unusable_error};
  return;
}


sub _txn_conn_unusable_error { return $_[0]->{_txn_conn_unusable_error} }

sub _txn_conn_unusable { return $_[0]->{_txn_conn_unusable} ? 1 : 0 }


sub _set_txn_guard { $_[0]->{_txn_guard} = $_[1]; return }

sub _txn_guard { return $_[0]->{_txn_guard} }


sub _track_statement {
  my ($self, $future) = @_;
  push @{ $self->{_txn_statements} }, $future
    if Scalar::Util::blessed($future) && $future->can('catch');
  return $future;
}

sub _txn_statements { return @{ $_[0]->{_txn_statements} || [] } }


sub _txn_pending_pipelines {
  return grep { defined $_ && !$_->is_ready } @{ $_[0]->{_txn_pipelines} || [] };
}

sub txn_do_async {
  my $self = shift;
  $self->_assert_context_active;
  DBIO::Exception->throw(
    'nested txn_do_async on a transaction context is not supported: there is '
    . 'no async savepoint, so it could only open an independent transaction '
    . 'on a second pool connection. Call $ctx->storage->txn_do_async if an '
    . 'independent transaction is really intended'
  );
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::Async::TransactionContext - Generic pinned-connection context for async transactions

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The transaction context handed to the coderef of
L<DBIO::Storage::Async/txn_do_async>. It pins every CRUD operation to the
single connection that C<BEGIN>/C<COMMIT>/C<ROLLBACK> ran on, routing them
through the storage's shared C<_run_crud_pinned> builder so SQL generation
(INSERT post-processing, C<select_single> first-row) is never duplicated.

This is the loop-agnostic default returned by
L<DBIO::Storage::Async/_txn_context_class>. It knows the pinned connection
as C<txn_conn> only -- the key L</new> takes it under and the method that
answers it -- so a transport backend that overrides
L<DBIO::Storage::Async/_txn_conn_accessor> to another name supplies a context
class of its own through C<_txn_context_class> as well: one whose C<new> takes
the connection under that name and that has a method of that name answering
it, which is where core asks for it.

=head1 ATTRIBUTES

=head2 storage

The parent L<DBIO::Storage::Async> instance.

=head2 txn_conn

The pinned connection handle for the duration of this transaction. The method
core asks a context for its connection through, under the name
L<DBIO::Storage::Async/_txn_conn_accessor> answers.

=head2 pool

Shortcut to C<< $self->storage->pool >>. It asks the storage each time, so
it is the storage's pool as it stands now, not a record of where L</txn_conn>
came from: after the storage was disconnected it is another pool, and with a
transport that builds its pool lazily, calling it builds one. The transaction
does not go through it -- L<DBIO::Storage::Async/txn_do_async> hands
L</txn_conn> back to the pool it acquired it from.

=head2 in_txn

True while this transaction context is active; false once the transaction
has sent its C<COMMIT> or C<ROLLBACK>, or has ended without either (a failed
C<BEGIN>, say).

=head1 METHODS

=head2 new

  my $ctx = DBIO::Storage::Async::TransactionContext->new(
      storage  => $storage,
      txn_conn => $conn,
  );

Creates a new transaction context. Requires C<storage> and the pinned
connection as C<txn_conn> -- the name
L<DBIO::Storage::Async/_txn_conn_accessor> answers by default, and the only
one this class takes: under any other key it dies with C<txn_conn required>,
which L<DBIO::Storage::Async/txn_do_async> turns into the failure of the
transaction.

=head2 _context_active

True while the transaction is live. A context-bound
L<DBIO::ResultSet>/L<DBIO::Row>/L<DBIO::ResultSetColumn> consults this before
routing an C<*_async> op onto the context (ADR 0045).

Unlike L<DBIO::Storage::Async::PipelineContext>, the transaction context stays
active while the callback's Future is pending -- its pinned connection is held
from C<BEGIN> through the terminal C<COMMIT>/C<ROLLBACK> path, so a
context-bound resultset used inside the transaction's own C<< ->then >> chain
legitimately still runs on the pinned connection. The transaction scaffold
invalidates it the moment it sends C<COMMIT> or C<ROLLBACK> --
a statement issued after that would run after the transaction, outside it --
and in any case before returning that connection to the pool. Once
invalidated, direct context CRUD and nested C<txn_do_async> calls refuse rather
than touching a connection whose transaction has ended.

=head2 _query_async

Executes a query on the pinned transaction connection without releasing
it back to the pool. Uses L<DBIO::Storage::Async/_query_async_pinned>.

=head2 select_async

=head2 select_single_async

=head2 insert_async

=head2 update_async

=head2 delete_async

Same arguments and resolution shapes as the storage methods of the same names
(L<DBIO::Storage::Async/select_async> etc.), but every statement runs on the
pinned L</txn_conn>, inside the transaction, through the storage's shared
pinned CRUD builder. Each throws a L<DBIO::Exception> once the context is no
longer active or its ownership cannot be proven.

The context keeps every Future these methods return (L</_track_statement>).
A statement that fails fails the transaction -- also when nothing awaits its
Future, and also when the coderef catches the failure and carries on
(L<DBIO::Storage::Async/txn_do_async>).

=head2 select

=head2 select_single

=head2 insert

=head2 update

=head2 delete

Blocking forms: call the C<*_async> method of the same name on this context
and wait for it with C<< ->get >>, blocking the event loop.

=head2 sql_maker

=head2 debug

Delegate to the parent storage's C<sql_maker> and C<debug>.

=head2 pipeline

  $txn_ctx->pipeline(sub {
      my ($batch) = @_;
      ...
  });

Runs a L<DBIO::Storage::Async/pipeline> batch on B<this transaction's pinned>
L</txn_conn>, not on a connection of its own: the bracket
(C<_pipeline_enter>/C<_pipeline_sync>/C<_pipeline_exit>) and every statement
issued through the batch context run inside the transaction, and the pipeline
does not release the connection -- only the transaction boundary does. Throws
a L<DBIO::Exception> once this context is no longer active. On a transport
that cannot pipeline it returns a failed Future (a L<DBIO::Exception> naming
the transport) before anything is sent on L</txn_conn>; see
L<DBIO::Storage::Async/_pipeline_refusal>.

A batch whose C<_pipeline_exit> dies leaves L</txn_conn> in pipeline mode.
The pipeline cannot hand the connection back itself -- it is the
transaction's -- so it marks it through L</_mark_txn_conn_unusable>, and the
transaction ends without waiting on it: no C<COMMIT>, a best-effort
C<ROLLBACK>, and the connection is retired from the pool instead of released
(L<DBIO::Storage::Async/txn_do_async>).

The pipeline's Future is kept like a statement's (L</_track_statement>): if it
fails, the transaction fails. And like a statement's it is kept until it is
ready when the transaction ends first -- the coderef died while the sync was
outstanding, say. That Future is the sequence that leaves pipeline mode once
the sync is answered; let go of early, it never ran. The
statements B<inside> the batch are the
batch context's, not this one's; a failure the batch coderef drops is not seen
here (see L<DBIO::Storage::Async/_txn_commit_rolled_back> for the transport
that can see it anyway).

=head2 txn_do_async

Refuses with a L<DBIO::Exception>. A nested transaction would have to be a
savepoint on L</txn_conn>, and the async layer has no savepoint seam; the only
thing this could otherwise do is open an B<independent> transaction on a second
pool connection, which commits even when this one rolls back and deadlocks as
soon as it waits on a lock this transaction holds (this transaction's C<COMMIT>
in turn waits on it).

When an independent transaction is what you want, ask for it by name:

  $txn_ctx->storage->txn_do_async(sub { ... });

=head2 _mark_txn_conn_unusable

  $txn_ctx->_mark_txn_conn_unusable;

Record that something run on L</txn_conn> left it in a state no statement can
rely on -- a pipeline whose C<_pipeline_exit> died, so the connection is still
in pipeline mode. L</pipeline> calls it; the transaction
scaffold reads it back through L</_txn_conn_unusable>. Nothing else changes:
the context stays active until the transaction ends.

=head2 _txn_conn_unusable

True once L</_mark_txn_conn_unusable> was called. The transaction scaffold in
L<DBIO::Storage::Async/txn_do_async> then sends no C<COMMIT> and waits for no
C<ROLLBACK> on L</txn_conn>, and retires it from the pool instead of releasing
it.

=head2 _txn_conn_unusable_error

The error L</_mark_txn_conn_unusable> was given, the first one. A pipeline
that failed on the transaction connection passes the error that ended its
batch; the transaction then fails with it instead of the
generic refusal. C<undef> when none was given.

=head2 _set_txn_guard

  $txn_ctx->_set_txn_guard({ pool => $pool, conn => $conn, done => 0, lease => $lease });

=head2 _txn_guard

The record L<DBIO::Storage::Async/txn_do_async> keeps of what became of the
transaction's connection: its pool, the connection, and C<done> once it was
released or retired. Every path that hands the connection back
or cuts the transaction short asks it, so the connection goes back once --
a cancel and the finalizer, say, do not both retire it.

=head2 _track_statement

  return $txn_ctx->_track_statement($future);

Keep C<$future> -- the Future of a statement this context hands out -- until
the transaction ends, and return it. L</_query_async>, the five C<*_async>
CRUD methods and L</pipeline> hand out their Future through it; a
context-bound L<DBIO::ResultSet>/L<DBIO::Row> routes through those methods and
is covered with them.

Held strongly, so a Future nobody else keeps -- a statement issued and not
awaited -- still reports how it ended. A synchronous throw from one of those
methods is not tracked: nothing was handed out, and the caller already holds
the error.

The holding ends with the statement's answer, not with the transaction. A
transaction can end with a statement still in flight: its coderef died or its
Future failed, and C<ROLLBACK> went out at once; or its connection was left
unusable and nothing is waited for on it. The context lists no statement from
then on (L</_txn_statements>), but each Future it kept is held until it is
ready -- done, failed or cancelled -- through its own C<retain>, where its
class has one (L<Future> has). Before, the context let go of them as it ended.
A statement's Future is typically a C<< ->then >> sequence that the Future it
was made off holds only weakly; dropped by its one holder, it was freed, and
L<Future> warned I<lost a sequence Future> when the answer came. A class
without C<retain> holds such a chain from its head (L<DBIO::Test::Future>) or
is settled from the start (L<DBIO::Future::Immediate>), and needs none.

=head2 _txn_statements

  my @futures = $txn_ctx->_txn_statements;

Every statement Future L</_track_statement> kept, in the order they were handed
out. Before it sends C<COMMIT>, L<DBIO::Storage::Async/txn_do_async> waits
until all of them have settled; if one failed, the transaction is rolled back
and fails with that statement's error. Empty once the transaction has ended
-- also when a statement is still in flight then: its Future is kept until it
is answered (L</_track_statement>), but nothing waits on it any more and it is
not listed.

=head2 _txn_pending_pipelines

  my @futures = $txn_ctx->_txn_pending_pipelines;

The Futures of the pipelines L</pipeline> ran on this transaction that are not
ready yet, in the order they were started. Unlike L</_txn_statements> it keeps
answering after the transaction has ended. A pipeline's Future is ready once
its sync is answered and the connection has left pipeline mode, which is the
point from which a statement can be sent on L</txn_conn> again.
L<DBIO::Storage::Async/txn_do_async> sends the C<ROLLBACK> that follows a
block that died only when none is left.

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
