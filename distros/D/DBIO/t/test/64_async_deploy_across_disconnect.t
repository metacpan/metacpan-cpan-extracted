# ABSTRACT: k331 (1): a multi-run deploy_async across a disconnect, which pool and which context
use strict;
use warnings;

use Test::More;
use Scalar::Util qw(weaken);

use DBIO::Test;
use DBIO::Test::Future ();
use DBIO::SQLMaker;
use DBIO::Storage::DBI;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k331 finding 1. Scenarios 1 and 2 assert the decided behaviour (a
# disconnect between two runs, or between the statements of one transactional
# run, fails the deploy); the "IST-STAND" assertions of scenario 3 still
# record what the code does and were not decided.
#
# deploy_async on a transactional engine cuts the DDL into RUNS (transaction-
# safe statements bracketed in one txn_do_async, a statement the owner declares
# non-transactional on its own pooled connection). The runs are chained by
# _run_ddl_runs_async (lib/DBIO/Storage/Async.pm l.4200): each run asks
# $self->pool, or txn_do_async does, AS IT BEGINS. dbio-async k46 (t/test/49)
# fixed the pool a run ENDS on; it did not make the runs of one deploy share
# the pool the deploy began on:
#
#   * a disconnect between two runs of one deploy: run N+1 builds a NEW pool
#     on the disconnected storage and goes on there; the deploy resolves and
#     the storage is left with a pool nobody asked it to build;
#   * the statements of a transactional run go out through _query_async_pinned
#     on the connection ($ctx->txn_conn), NOT through the context
#     (_run_ddl_stmts_async, l.4366): they are not among the statements the
#     context tracks and the context's refusal after a disconnect does not
#     apply to them. A statement issued through the context afterwards is
#     refused.
#
# What the fixture assumes of the transport: the pool's shutdown does not fail
# the statement in flight and does not refuse later statements on a closed
# connection (the shape of t/test/49's pool). The real transports differ and
# make the first scenario unreachable from outside: dbio-async fails a
# statement in flight at shutdown and refuses statements on a closed pinned
# connection (dbio-async t/30-disconnect-statement-in-flight.t ~l.600-690), and
# EV::Pg's shutdown calls the queued callback with "connection finished"
# (dbio-postgresql-ev t/75-completion-same-pool-mock.t header). A disconnect
# made INSIDE a statement's delivery reaches it on EV (same header).

{
  package T64::Conn;
  sub new { bless { id => $_[1], pool_id => $_[2] }, $_[0] }
}

{
  package T64::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection   { my $self = shift; T64::Conn->new(++$self->{_next_id}, $self->{pool_id}) }
  sub _shutdown_connection { push @{ $_[0]->{closed} }, $_[1]->{id} }
}

{
  package T64::Owner;
  use base 'DBIO::Storage::DBI';
  BEGIN { $INC{'T64/Owner.pm'} = 1 }
  sub _use_transactional_ddl { 1 }
  sub _ddl_statement_is_transactional { $_[1] =~ /^ALTER/ ? 0 : 1 }
}

{
  package T64::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'DBIO::Test::Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }
  sub _install_ddl     { $_[0]->{ddl} }

  sub pool {
    my ($self) = @_;
    return $self->{pool} ||= do {
      my $pool = T64::Pool->new(
        storage => $self, conninfo => 'fake', size => 1,
        future_class => $self->future_class, on_error => sub { },
      );
      $pool->{pool_id} = ++$self->{pool_seq};
      push @{ $self->{pools} }, $pool;
      $pool;
    };
  }

  # {hold}{$sql}: not answered until answer_held.
  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{wire} }, "$sql\@P$conn->{pool_id}";
    my $f = $self->future_class->new;
    if ($self->{hold}{$sql}) {
      push @{ $self->{held} }, $f;
      return $f;
    }
    return $f->done;
  }
}

sub backend {
  my (%o) = @_;
  # The owner is a real (mock) storage, so the context's owner check is the
  # real one -- as in t/test/49.
  my $schema  = DBIO::Test->init_schema(storage_type => '+T64::Owner');
  my $backend = T64::Backend->new($schema);
  my $owner   = $schema->storage;
  $backend->{_test_schema_guard} = $schema;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token)
    if $owner->can('_async_context_owner_token');
  # An embedded backend is the owner's cached one; the owner re-adopts the
  # token a disconnect rotates only for the backend it caches.
  weaken($owner->{_async_storage_obj} = $backend);
  $backend->{wire} = [];
  $backend->{$_} = $o{$_} for keys %o;
  return $backend;
}

sub answer_held {
  my ($backend) = @_;
  $_->done while $_ = shift @{ $backend->{held} || [] };
}

sub outcome {
  my ($f) = @_;
  return 'pending' unless $f->is_ready;
  return 'failed: ' . $f->{values}[0] if $f->is_failed;
  return 'done';
}

local $SIG{__WARN__} = sub {
  return if $_[0] =~ /^split DDL batch on T64::Backend /;
  warn $_[0];
};

# ---------------------------------------------------------------------------
# 1. Three runs: [CREATE a] [ALTER x, not transactional] [CREATE b]. The
#    disconnect lands while run 1's statement is in flight.
# ---------------------------------------------------------------------------
{
  my $backend = backend(
    ddl  => "CREATE TABLE a (id int);\nALTER TYPE mood ADD VALUE 'calm';\nCREATE TABLE b (id int);",
    hold => { 'CREATE TABLE a (id int)' => 1 },
  );
  my $pool1 = $backend->pool;
  my $f = $backend->deploy_async('schema');
  is_deeply $backend->{wire}, [ 'BEGIN@P1', 'CREATE TABLE a (id int)@P1' ],
    'three runs: run 1 is in flight on pool P1';
  is outcome($f), 'pending', '... the deploy waits';

  $backend->disconnect;
  ok !defined $backend->{pool}, '... disconnect: the storage is left without a pool';
  ok $pool1->{_shutdown}, '... and P1 is shut down';

  answer_held($backend);

  # SOLL k331 (1), maintainer decision 2026-10-10 (option A): the deploy holds
  # the pool it began on. Run 1 ends on P1 (COMMIT on its pinned connection);
  # run 2 finds P1 shut down at the run boundary and the deploy fails, naming
  # the disconnect. No new pool is built, nothing goes out on one, no resume.
  is_deeply $backend->{wire}, [
    'BEGIN@P1', 'CREATE TABLE a (id int)@P1', 'COMMIT@P1',
  ], 'run 1 ends on P1; no later run goes out anywhere';
  is scalar @{ $backend->{pools} }, 1, '... no second pool is built for the deploy';
  is outcome($f), 'failed: storage disconnected during deploy',
    '... the deploy fails, naming the disconnect';
  ok !defined $backend->{pool},
    '... and the disconnected storage is left without a pool';
}

# ---------------------------------------------------------------------------
# 2. One transactional run of two statements; the disconnect lands between
#    its first statement and its second. The context is not asked.
# ---------------------------------------------------------------------------
{
  my $backend = backend(
    ddl  => "CREATE TABLE a (id int);\nCREATE TABLE b (id int);",
    hold => { 'CREATE TABLE a (id int)' => 1 },
  );
  my $pool1 = $backend->pool;
  my $f = $backend->deploy_async('schema');
  $backend->disconnect;
  answer_held($backend);

  # SOLL k331 (1), maintainer decision 2026-10-13: the pool is asked between
  # the statements of one transactional run too. Found shut down, the deploy
  # fails naming the disconnect and the run is rolled back: no second
  # statement, no COMMIT. The statement in flight at the disconnect is not
  # touched (it was answered here by the fixture).
  is_deeply $backend->{wire}, [
    'BEGIN@P1', 'CREATE TABLE a (id int)@P1', 'ROLLBACK@P1',
  ], 'one transactional run: the rest of its DDL is not sent after the disconnect, the run is rolled back';
  is scalar @{ $backend->{pools} }, 1, '... no second pool is built';
  ok !defined $backend->{pool}, '... and the storage stays without a pool';
  is outcome($f), 'failed: storage disconnected during deploy',
    '... the deploy fails, naming the disconnect';
}

# ---------------------------------------------------------------------------
# 3. Control: the same disconnect, a statement issued THROUGH the context by a
#    txn_do_async block (what deploy_async does not do).
# ---------------------------------------------------------------------------
{
  my $backend = backend();
  my $pause   = DBIO::Test::Future->new;
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $pause->then(sub { return $ctx->_query_async('CREATE TABLE c (id int)', []) });
  });
  $backend->disconnect;
  $pause->done;

  # IST-STAND k331 (1): the context is generation-bound: after the disconnect
  # it refuses a statement ("does not belong to this storage generation"),
  # nothing of it reaches the wire, and the transaction is rolled back on P1.
  # This is the guard the deploy's DDL (scenario 2) does not pass through.
  # Maintainer-Entscheidung offen.
  like outcome($f), qr/^failed: .*does not belong to this storage generation/s,
    'IST-STAND (1): a statement issued through the context after the disconnect is refused, and fails the transaction';
  is_deeply $backend->{wire}, [ 'BEGIN@P1', 'ROLLBACK@P1' ],
    '... it never reaches the wire; the transaction is rolled back on P1';
}

done_testing;
