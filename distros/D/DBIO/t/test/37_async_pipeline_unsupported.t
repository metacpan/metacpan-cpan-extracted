use strict;
use warnings;
use Test::More;
use Test::Exception;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;

# karr core k218 -- a transport that cannot pipeline (it does not override the
# _pipeline_enter seam, e.g. dbio-mysql-ev) must refuse $storage->pipeline and
# $ctx->pipeline with an error written for the CALLER: which transport, and that
# it does not support pipeline(). Before k218 the caller got the seam's
# "Subclass must override _pipeline_enter($conn)", which reads as a bug in the
# caller's own subclass.
#
# The claims this file pins:
#   * the refusal is a DBIO::Exception naming the transport class and pipeline();
#   * it is decided BEFORE anything is touched: no pool acquire, the batch
#     coderef never runs, and inside a transaction no statement reaches the
#     pinned connection -- the refusal fails the transaction, which rolls back;
#   * a transport that DOES override _pipeline_enter is not affected.

{
  package K218::Pool;

  sub new { bless { acquired => [], txn_acquired => [], released => [], n => 0 }, $_[0] }
  sub future_class { 'DBIO::Test::Future' }

  sub acquire {
    my ($self) = @_;
    my $conn = 'POOLED-' . ++$self->{n};
    push @{ $self->{acquired} }, $conn;
    return DBIO::Test::Future->done($conn);
  }

  sub acquire_txn {
    my ($self) = @_;
    my $conn = 'TXN-' . ++$self->{n};
    push @{ $self->{txn_acquired} }, $conn;
    return DBIO::Test::Future->done($conn);
  }

  sub release   { push @{ $_[0]->{released} }, $_[1]; 1 }
  sub available { 1 }
  sub shutdown  { 1 }
}

{
  # A transport with a query path but no pipeline seams -- the mysql-ev shape.
  package K218::NoPipeline;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }
  sub pool             { $_[0]->{pool} ||= K218::Pool->new }

  sub _query_async {
    my ($self, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, conn => 'POOLED-QUERY' };
    return DBIO::Test::Future->done;
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, { sql => $sql, conn => $conn };
    return DBIO::Test::Future->done;
  }
}

{
  package K218::WithPipeline;
  our @ISA = ('K218::NoPipeline');

  sub _pipeline_enter { push @{ $_[0]->{captured} }, { sql => 'PIPELINE_ENTER', conn => $_[1] }; 1 }
  sub _pipeline_exit  { push @{ $_[0]->{captured} }, { sql => 'PIPELINE_EXIT',  conn => $_[1] }; 1 }
  sub _pipeline_sync  {
    push @{ $_[0]->{captured} }, { sql => 'PIPELINE_SYNC', conn => $_[1] };
    return DBIO::Test::Future->done;
  }
}

sub new_backend {
  my ($class) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = $class->new($schema);
  $backend->{captured} = [];
  my $owner = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  return $backend;
}

sub trail { [ map { $_->{sql} . '@' . $_->{conn} } @{ $_[0]->{captured} } ] }

sub failure_of {
  my ($f) = @_;
  my $e;
  eval { $f->get; 1 } or $e = $@;
  return $e;
}

my $refusal = qr/K218::NoPipeline does not support pipeline\(\) \(no _pipeline_enter\)/;

# ---------------------------------------------------------------------------
# $storage->pipeline on a transport without the seam
# ---------------------------------------------------------------------------
{
  my $backend = new_backend('K218::NoPipeline');
  my $ran = 0;

  my $f;
  lives_ok { $f = $backend->pipeline(sub { $ran++; return 1 }) }
    'pipeline still reports through its Future, it does not throw synchronously';

  my $e = failure_of($f);
  isa_ok $e, 'DBIO::Exception', 'the refusal';
  like "$e", $refusal, 'the refusal names the transport and pipeline()';
  unlike "$e", qr/Subclass must override/,
    'and is not the transport-author message of the bare seam';

  is $ran, 0, 'the batch coderef never ran';
  is_deeply $backend->pool->{acquired}, [], 'no connection was taken from the pool';
  is_deeply $backend->pool->{released}, [], 'so none had to be handed back';
}

# ---------------------------------------------------------------------------
# $ctx->pipeline inside a transaction on a transport without the seam
# ---------------------------------------------------------------------------
{
  my $backend = new_backend('K218::NoPipeline');
  my $ran = 0;

  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->pipeline(sub { $ran++; return 1 });
  });

  my $e = failure_of($f);
  isa_ok $e, 'DBIO::Exception', 'the in-transaction refusal';
  like "$e", $refusal, 'names the transport and pipeline()';

  is $ran, 0, 'the batch coderef never ran';
  is_deeply trail($backend), [ 'BEGIN@TXN-1', 'ROLLBACK@TXN-1' ],
    'nothing reached the pinned connection between BEGIN and the ROLLBACK the refusal causes';
  is_deeply $backend->pool->{acquired}, [], 'no pooled connection was taken';
  is_deeply $backend->pool->{released}, [ 'TXN-1' ],
    'the transaction connection is released once, by the transaction boundary';
}

# ---------------------------------------------------------------------------
# A transport that overrides the seam is unaffected
# ---------------------------------------------------------------------------
{
  my $backend = new_backend('K218::WithPipeline');
  my $f = $backend->pipeline(sub { return 'batched' });
  is scalar $f->get, 'batched', 'a pipelining transport still runs the batch';
  is_deeply trail($backend),
    [ 'PIPELINE_ENTER@POOLED-1', 'PIPELINE_SYNC@POOLED-1', 'PIPELINE_EXIT@POOLED-1' ],
    'bracketed on the pooled connection as before';
}

done_testing;
