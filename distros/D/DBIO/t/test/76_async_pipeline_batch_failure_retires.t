use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k396. A pipeline hands its connection back only when everything about
# its batch is decided:
#
#   * every statement Future the batch issued is answered, and so is the
#     Future the coderef returned -- a late error never reaches a connection
#     that has been lent to someone else meanwhile;
#   * a batch that fails -- the coderef died, the sync or the returned Future
#     failed, the batch Future was cancelled -- retires its connection instead
#     of releasing it, fails every statement Future still open with the
#     batch's error, and sends no sync on that path;
#   * inside a transaction the pipeline only marks the connection unusable;
#     the transaction boundary decides what becomes of it.
#
# The fake wire answers a statement only at the sync, like a real pipeline, so
# a statement left unsynced stays pending until the scaffold decides it.

{
  package K396::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K396::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { K396::Conn->new(++$_[0]->{_next_id}) }
  sub _shutdown_connection { push @{ $_[0]->{closed} }, $_[1]->{id} }
  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

{
  package K396::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub pool {
    return $_[0]->{pool} ||= K396::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => 'DBIO::Test::Future',
    );
  }

  # Statements of a batch wait on the wire for the sync; the transaction's own
  # statements are answered at once.
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, $sql;
    return $self->future_class->done if $sql =~ /\A(?:BEGIN|COMMIT|ROLLBACK)\z/;
    my $wire = $self->future_class->new;
    push @{ $self->{wire} }, $wire;
    return $wire;
  }

  sub _pipeline_enter { push @{ $_[0]->{captured} }, 'PIPELINE_ENTER'; 1 }

  sub _pipeline_sync {
    my ($self) = @_;
    push @{ $self->{captured} }, 'PIPELINE_SYNC';
    $_->done(1) for grep { !$_->is_ready } @{ $self->{wire} };
    return $self->{sync_future} || $self->future_class->done;
  }

  sub _pipeline_exit { push @{ $_[0]->{captured} }, 'PIPELINE_EXIT'; 1 }
}

sub new_backend {
  my (%knobs) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $backend = K396::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  $backend->{wire}     = [];
  $backend->{$_} = $knobs{$_} for keys %knobs;
  return $backend;
}

sub outcome {
  my ($f) = @_;
  return (undef, 'pending') unless $f->is_ready;
  my $value;
  return ($value, undef) if eval { $value = $f->get; 1 };
  return (undef, "$@");
}

sub retired_not_released {
  my ($backend, $label) = @_;
  my $pool = $backend->pool;
  is_deeply $pool->{release_log} // [], [], "$label: the connection was not released";
  is_deeply $pool->{closed} // [], [ 1 ], "$label: it was retired, closed exactly once";
}

# ---------------------------------------------------------------------------
# The coderef dies after batching two statements. Asserts: the pipeline fails
# with that error; both statement Futures fail with the same error instead of
# staying open; the connection is retired, not released; no sync went out; the
# transport answering the two statements later is harmless.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my @stmts;
  my $f = $backend->pipeline(sub {
    my ($batch) = @_;
    push @stmts, $batch->_query_async('SELECT 1', []), $batch->_query_async('SELECT 2', []);
    die "coderef died after batching two statements\n";
  });

  my (undef, $error) = outcome($f);
  like $error, qr/coderef died after batching two statements/,
    'coderef dies: the pipeline fails with its error';
  for my $i (0, 1) {
    my (undef, $e) = outcome($stmts[$i]);
    like $e, qr/coderef died after batching two statements/,
      "coderef dies: statement $i fails with the batch error";
  }
  ok !(grep { $_ eq 'PIPELINE_SYNC' } @{ $backend->{captured} }),
    'coderef dies: no sync is sent';
  retired_not_released($backend, 'coderef dies');

  my $late = eval { $_->done(1) for @{ $backend->{wire} }; 1 };
  ok $late, 'coderef dies: a transport answering late finds the Futures decided'
    or diag $@;
  my (undef, $e0) = outcome($stmts[0]);
  like $e0, qr/coderef died/, 'coderef dies: the late answer changes nothing';
}

# ---------------------------------------------------------------------------
# The success path is unchanged: sync, exit, release once, the coderef's value.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my @stmts;
  my $f = $backend->pipeline(sub {
    my ($batch) = @_;
    push @stmts, $batch->_query_async('SELECT 1', []), $batch->_query_async('SELECT 2', []);
    return DBIO::Test::Future->needs_all(@stmts);
  });
  my ($got, $error) = outcome($f);
  is $error, undef, 'success: the pipeline succeeds';
  ok $_->is_ready && !$_->is_failed, 'success: statement Future is done' for @stmts;
  is_deeply $backend->{captured},
    [ 'PIPELINE_ENTER', 'SELECT 1', 'SELECT 2', 'PIPELINE_SYNC', 'PIPELINE_EXIT' ],
    'success: enter, statements, sync, exit';
  is_deeply $backend->pool->{release_log}, [ 1 ], 'success: released once';
  is_deeply $backend->pool->{closed} // [], [], 'success: not retired';
}

# ---------------------------------------------------------------------------
# The Future the coderef returned fails after the sync. The connection is not
# back in the pool before that Future is decided, so the late error cannot hit
# a connection lent to a waiter; it is retired when the error arrives, and the
# waiter gets a fresh one.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my $pool    = $backend->pool;
  my $late    = DBIO::Test::Future->new;
  my $f = $backend->pipeline(sub {
    my ($batch) = @_;
    $batch->_query_async('SELECT 1', []);
    return $late;
  });
  my $waiter = $pool->acquire;

  ok !$f->is_ready, 'late failure: the pipeline waits for the returned Future';
  ok !$waiter->is_ready, 'late failure: the connection was not lent out in the meantime';
  is_deeply $pool->{release_log} // [], [], 'late failure: nothing released yet';

  $late->fail("late batch error\n");
  my (undef, $error) = outcome($f);
  like $error, qr/late batch error/, 'late failure: the pipeline fails with it';
  retired_not_released($backend, 'late failure');
  ok $waiter->is_ready, 'late failure: the waiter is served';
  is $waiter->get->{id}, 2, 'late failure: on a fresh connection, not the failed one'
    if $waiter->is_ready;
}

# ---------------------------------------------------------------------------
# A pipeline failing inside a transaction only marks the connection unusable;
# the transaction boundary retires it. The statements fail with the batch error.
# ---------------------------------------------------------------------------
{
  my $backend = new_backend();
  my (@stmts, $ctx, $marked_after_pipeline);
  my $f = $backend->txn_do_async(sub {
    ($ctx) = @_;
    my $p = $ctx->pipeline(sub {
      my ($batch) = @_;
      push @stmts, $batch->_query_async('SELECT 1', []), $batch->_query_async('SELECT 2', []);
      die "batch died in a transaction\n";
    });
    $marked_after_pipeline = $ctx->_txn_conn_unusable;
    return $p;
  });

  my (undef, $error) = outcome($f);
  like $error, qr/batch died in a transaction/, 'txn pipeline: the transaction fails with it';
  ok $marked_after_pipeline, 'txn pipeline: the pipeline marked the connection unusable';
  for my $i (0, 1) {
    my (undef, $e) = outcome($stmts[$i]);
    like $e, qr/batch died in a transaction/, "txn pipeline: statement $i fails with the batch error";
  }
  retired_not_released($backend, 'txn pipeline');
}

done_testing;
