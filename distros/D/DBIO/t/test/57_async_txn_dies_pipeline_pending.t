use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k331 (finding 3 of the 2026-10-08 async review, k275). A transaction
# whose block dies -- or whose inner Future fails -- while a pipeline run on
# its context ($ctx->pipeline) still waits for its sync answer used to send
# ROLLBACK on the connection at once, in pipeline mode, and hand the
# connection back to the pool right behind it. The pipeline's bracket ends
# (_pipeline_exit) only when the sync is answered, so until then the idle
# connection in the pool was in pipeline mode, and whoever borrowed it in
# that window got a connection that rejects a plain query (EV::Pg).
#
# The claim this file pins, against the contract of txn_do_async (the
# connection goes back out of pipeline mode, ROLLBACK is sent on a connection
# that takes it):
#
#   * nothing is sent on the transaction's connection in pipeline mode;
#   * the connection is not handed back to the pool while it is in pipeline
#     mode -- not even idle, not even for the moment until the sync is
#     answered: an acquire in that window does not get it;
#   * once the sync is answered the bracket ends, ROLLBACK goes out on the
#     connection out of pipeline mode, and the transaction fails with the
#     error that ended it;
#   * a pipeline whose sync is already answered is as before: ROLLBACK at once.
#
# Mock only: the fake wire keeps pipeline mode on the connection object and a
# real PoolBase of size 1 hands it out.

{
  package K331B::Conn;
  sub new { bless { id => $_[1], in_pipeline => 0 }, $_[0] }
}

{
  package K331B::Pool;
  use base 'DBIO::Storage::PoolBase';

  sub _create_connection { K331B::Conn->new(++$_[0]->{_next_id}) }
  sub _shutdown_connection {
    my ($self, $conn) = @_;
    push @{ $self->{closed} }, $conn->{id};
  }

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} },
      { conn => $conn->{id}, in_pipeline => $conn->{in_pipeline} };
    return $self->SUPER::release($conn);
  }
}

{
  package K331B::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= K331B::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => 'DBIO::Test::Future',
    );
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, $sql;
    push @{ $self->{sent_in_pipeline} }, $sql if $conn->{in_pipeline};
    return $self->future_class->done;
  }

  sub _pipeline_enter {
    my ($self, $conn) = @_;
    push @{ $self->{captured} }, 'PIPELINE_ENTER';
    $conn->{in_pipeline} = 1;
    return 1;
  }

  sub _pipeline_sync {
    my ($self, $conn) = @_;
    push @{ $self->{captured} }, 'PIPELINE_SYNC';
    return $self->{sync_future};
  }

  sub _pipeline_exit {
    my ($self, $conn) = @_;
    push @{ $self->{captured} }, 'PIPELINE_EXIT';
    die "exit croaked: pipeline not idle\n" if $self->{die_exit};
    $conn->{in_pipeline} = 0;
    return 1;
  }
}

sub new_backend {
  my $schema  = DBIO::Test->init_schema;
  my $backend = K331B::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured}    = [];
  $backend->{sync_future} = DBIO::Test::Future->new;
  return $backend;
}

sub outcome {
  my ($f) = @_;
  return (undef, 'pending') unless $f->is_ready;
  my $value;
  return ($value, undef) if eval { $value = $f->get; 1 };
  return (undef, "$@");
}

for my $case (
  [ 'the coderef dies with the pipeline waiting for its sync',
    sub {
      my ($ctx) = @_;
      $ctx->pipeline(sub { return 1 });
      die "block gave up\n";
    } ],
  [ 'the coderef returns a failed Future with the pipeline waiting',
    sub {
      my ($ctx) = @_;
      $ctx->pipeline(sub { return 1 });
      return DBIO::Test::Future->fail("block failed\n");
    } ],
) {
  my ($how, $coderef) = @$case;
  my $label = $how;
  my $backend = new_backend();
  my $pool    = $backend->pool;

  my $txn = $backend->txn_do_async($coderef);

  # The sync is not answered yet: the bracket is open on the connection.
  is_deeply $backend->{sent_in_pipeline} // [], [],
    "$label: nothing is sent on the connection in pipeline mode";
  is_deeply $pool->{release_log} // [], [],
    "$label: the connection is not handed back while it is in pipeline mode";
  my $borrower = $pool->acquire;
  if ($borrower->is_ready) {
    my $conn = $borrower->get;
    ok !$conn->{in_pipeline},
      "$label: an acquire in that window never gets a connection in pipeline mode";
  }
  else {
    pass "$label: an acquire in that window waits instead of getting it";
  }
  ok !$txn->is_ready, "$label: the transaction waits for the pipeline's sync";

  # The sync is answered.
  $backend->{sync_future}->done;

  my (undef, $error) = outcome($txn);
  like $error, qr/block (?:gave up|failed)/,
    "$label: the transaction fails with the error that ended the block";
  is_deeply $backend->{sent_in_pipeline} // [], [],
    "$label: still nothing was sent in pipeline mode";
  is_deeply $backend->{captured},
    [ 'BEGIN', 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT', 'ROLLBACK' ],
    "$label: the bracket ends, then ROLLBACK, on the connection out of pipeline mode";
  ok !$_->{in_pipeline}, "$label: the connection went back out of pipeline mode"
    for @{ $pool->{release_log} // [] };
  is scalar @{ $pool->{release_log} // [] }, 1,
    "$label: the connection went back to the pool once";
  is_deeply $pool->{closed} // [], [],
    "$label: it was released, not retired -- it is fine";
}

# A pipeline whose sync is answered by the time the block dies: ROLLBACK goes
# out at once, as it always did.
{
  my $backend = new_backend();
  $backend->{sync_future}->done;
  my (undef, $error) = outcome($backend->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->pipeline(sub { return 1 });
    die "block gave up\n";
  }));
  like $error, qr/block gave up/, 'sync already answered: fails with the block error';
  is_deeply $backend->{captured},
    [ 'BEGIN', 'PIPELINE_ENTER', 'PIPELINE_SYNC', 'PIPELINE_EXIT', 'ROLLBACK' ],
    'sync already answered: ROLLBACK after the exit, as before';
}

# The pipeline's exit dies once the sync is answered: the connection stays in
# pipeline mode, so no ROLLBACK is waited for on it (karr k232) -- it is
# retired, never released, and the transaction fails with the block's error.
{
  my $backend = new_backend();
  $backend->{die_exit} = 1;
  my $pool = $backend->pool;
  my $txn = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    $ctx->pipeline(sub { return 1 });
    die "block gave up\n";
  });
  ok !$txn->is_ready, 'exit dies: the transaction waits for the sync';
  $backend->{sync_future}->done;
  my (undef, $error) = outcome($txn);
  like $error, qr/block gave up/, 'exit dies: fails with the error that ended the block';
  is_deeply $pool->{release_log} // [], [], 'exit dies: the connection is not released';
  is_deeply $pool->{closed} // [], [ 1 ], 'exit dies: it is retired, closed once';
}

done_testing;
