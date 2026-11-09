use strict;
use warnings;
use Test::More;

use Future;
use Future::IO;
use Scalar::Util 'refaddr';
use DBIO::SQLMaker;          # the mock's sql_maker_class
use DBIO::Async::Storage;
use DBIO::Async::Pool;
use DBIO::Async::TransactionContext;

# OFFLINE test for karr k34: a synchronous statement on a transaction context
# -- $ctx->select, which is select_async(...)->get (ADR 0001) -- issued from
# inside a Future callback of the same connection must complete.
#
# WHY IT MATTERS. Core runs a transaction's block from the callback of BEGIN's
# Future (txn_do_async: BEGIN->then(block)), and txn_do is txn_do_async->get.
# So EVERY synchronous statement a block issues on its context is issued from
# inside the settle of the statement before it on that connection. The k33
# queue (t/24) counted the connection busy until that statement's callbacks
# had returned: the block's statement waited behind a queue that would only
# advance once the block returned, and its ->get waited for the statement.
# Nothing was on the wire, so the built-in Future::IO impl died "Cowardly
# refusing to sit idle and do nothing" and every other loop hung. This worked
# before k33 -- the connection is in fact idle at that point: the statement
# before has settled and nothing else waits for the connection.
#
# The same holds for a synchronous statement in the ->then of an earlier
# statement the block issued itself (section 3). When statements issued
# earlier still wait for the connection, the synchronous one waits behind
# them, and that case still cannot complete -- section 4, a TODO.
#
# WHAT IS REAL. The whole transport -- _query_async_pinned and its queue,
# _await_query_result, the Future::IO watcher seam on a real pipe, the real
# DBIO::Async::Pool -- and core's real txn_do / txn_do_async, whose COMMIT
# waits for every statement of the context (core k236), and the context's
# real synchronous wrappers. Section 0 pins that.
#
# THE MOCK SERVER keeps ONE statement slot per connection, as a DBD does, and
# refuses a second statement while the slot is taken -- so a fix that simply
# stopped queueing would fail loudly here rather than pass.

{
  package RecPool26;
  use base 'DBIO::Async::Pool';

  sub release {
    my ($self, $conn) = @_;
    push @{ $self->{release_log} }, $conn->{id};
    return $self->SUPER::release($conn);
  }
}

{
  package Sync26;
  use base 'DBIO::Async::Storage';
  use lib 't/lib';
  use AsyncResetStub;
  use Future;
  use Scalar::Util ();

  sub sql_maker_class     { 'DBIO::SQLMaker' }
  sub _transform_sql      { $_[1] }
  sub _post_insert_sql    { '' }
  sub _normalize_conninfo { $_[1] }
  sub _conn_ready         { 1 }
  sub _conn_fileno        { fileno $_[1]{r} }

  # What a transaction context's CRUD needs from its owning storage (as in
  # t/24): this mock is its own owner, and proves ownership as core does.
  sub _owner_storage { $_[0] }
  sub _assert_async_context_owner {
    my ($self, $ctx) = @_;
    die "async context does not belong to this storage generation\n"
      unless Scalar::Util::refaddr($self->_context_owner_token)
          == Scalar::Util::refaddr($ctx->_context_owner_token);
    return $ctx;
  }
  sub _select_args { my ($self, @args) = @_; return ('select', @args) }

  sub _create_pool_connection {
    my $self = shift;
    pipe(my $r, my $w) or die "pipe: $!";
    $w->autoflush(1);
    return { id => ++$self->{_next_id}, r => $r, w => $w };
  }

  sub _shutdown_pool_connection {
    my ($self, $conn) = @_;
    push @{ $self->{shutdown} }, $conn->{id};
    close $conn->{r};
    close $conn->{w};
  }

  sub pool {
    my $self = shift;
    return $self->{pool} ||= RecPool26->new(
      storage  => $self,
      conninfo => $self->{_conninfo},
      size     => $self->{_pool_size},
      on_error => sub { push @{ $self->{pool_errors} }, $_[0] },
    );
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    my $label = $sql =~ /\bFROM (\w+)/ ? $1 : $sql;
    push @{ $self->{wire} }, $label;
    push @{ $self->{log} }, "submit:$label";
    die "another statement is still in flight on this connection "
      . "($conn->{in_flight})\n"
      if defined $conn->{in_flight};
    $conn->{in_flight} = $label;
    syswrite $conn->{w}, 'R';
    return;
  }

  sub _collect_result {
    my ($self, $conn) = @_;
    sysread $conn->{r}, my $byte, 1;
    my $label = delete $conn->{in_flight};
    return Future->done([ 'row-for', $label ]);
  }
}

sub new_storage {
  my $storage = Sync26->new(undef);
  $storage->{_next_id} = 0;
  $storage->{$_} = [] for qw(wire log shutdown pool_errors);
  $storage->connect_info([{ host => 'localhost', pool_size => 1 }]);
  return $storage;
}

# Run $code with a deadline: a regression on a loop other than the built-in
# one hangs instead of dying, and a hanging test proves nothing.
sub bounded {
  my ($code) = @_;
  my @result;
  my $ok = eval {
    local $SIG{ALRM} = sub { die "deadlock: timed out\n" };
    alarm 10;
    @result = $code->();
    alarm 0;
    1;
  };
  alarm 0;
  return $ok ? (1, @result) : (0, $@);
}

# A synchronous select on the context, logged once it returned.
sub sync_select {
  my ($storage, $ctx, $table) = @_;
  my $rows = $ctx->select($table, ['*'], {});
  push @{ $storage->{log} }, "returned:$table";
  return $rows;
}

sub async_select {
  my ($storage, $ctx, $table) = @_;
  my $f = $ctx->select_async($table, ['*'], {});
  $f->on_ready(sub { push @{ $storage->{log} }, "settled:$table" });
  return $f;
}

# ---------------------------------------------------------------------------
# 0. The mock overrides none of the transport's query path, and the context
#    class its synchronous wrapper -- the transport and core run.
# ---------------------------------------------------------------------------

for my $method (qw(_query_async _query_async_pinned _await_query_result
                   _await_readable txn_do txn_do_async)) {
  is refaddr(Sync26->can($method)), refaddr(DBIO::Async::Storage->can($method)),
    "the mock does NOT override $method";
}
is refaddr(DBIO::Async::TransactionContext->can('select')),
  refaddr(DBIO::Storage::Async::TransactionContext->can('select')),
  "the context's synchronous select is core's select_async->get";

# ---------------------------------------------------------------------------
# 1. The reported case: txn_do with synchronous statements on the context.
#    Asserts that each returns its own rows, that the transaction commits and
#    returns the block's value, that the wire saw one statement at a time in
#    order -- BEGIN, the two selects, COMMIT -- and that the connection went
#    back to the pool once, not retired, with no queue state on it.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my ($ctx_conn, $first, $second);

  my ($ok, @r) = bounded(sub {
    $storage->txn_do(sub {
      my ($ctx) = @_;
      $ctx_conn = $ctx->txn_conn;
      $first  = sync_select($storage, $ctx, 'first');
      $second = sync_select($storage, $ctx, 'second');
      return 'block-value';
    });
  });

  ok $ok, 'txn_do: synchronous statements in the block complete -- no deadlock'
    or diag $r[0];
  is $r[0], 'block-value', 'txn_do: ... and the transaction returns the block value';
  is_deeply $first,  [ 'row-for', 'first' ],  'txn_do: the first select returns its rows';
  is_deeply $second, [ 'row-for', 'second' ], 'txn_do: the second its own';
  is_deeply $storage->{wire}, [ 'BEGIN', 'first', 'second', 'COMMIT' ],
    'txn_do: one statement at a time, in order, and the transaction commits';
  is_deeply $storage->pool->{release_log}, [1], 'txn_do: the connection was handed back once';
  is_deeply $storage->{shutdown}, [], 'txn_do: ... and not retired';
  ok $ctx_conn && !exists $ctx_conn->{_dbio_async_queue},
    'txn_do: the connection carries no queue state back to the pool';
}

# ---------------------------------------------------------------------------
# 2. The same through txn_do_async, the Future driven by the caller.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $rows;

  my ($ok, @r) = bounded(sub {
    $storage->txn_do_async(sub {
      my ($ctx) = @_;
      $rows = sync_select($storage, $ctx, 'only');
      return Future->done('async-value');
    })->get;
  });

  ok $ok, 'txn_do_async: a synchronous statement in the block completes'
    or diag $r[0];
  is $r[0], 'async-value', 'txn_do_async: ... and the transaction resolves';
  is_deeply $rows, [ 'row-for', 'only' ], 'txn_do_async: the select returns its rows';
  is_deeply $storage->{wire}, [ 'BEGIN', 'only', 'COMMIT' ],
    'txn_do_async: BEGIN, the select, COMMIT -- the transaction commits';
}

# ---------------------------------------------------------------------------
# 3. A synchronous statement from the ->then of an earlier asynchronous one,
#    nothing else waiting: the same mechanism one statement further on. The
#    earlier one's caller saw its result before the synchronous one went out.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my $rows;

  my ($ok, @r) = bounded(sub {
    $storage->txn_do_async(sub {
      my ($ctx) = @_;
      return async_select($storage, $ctx, 'first')->then(sub {
        $rows = sync_select($storage, $ctx, 'second');
        return Future->done('chained');
      });
    })->get;
  });

  ok $ok, 'in a ->then: the synchronous statement completes' or diag $r[0];
  is $r[0], 'chained', 'in a ->then: ... and the transaction resolves';
  is_deeply $rows, [ 'row-for', 'second' ], 'in a ->then: it returns its own rows';
  is_deeply $storage->{log}, [
    'submit:BEGIN',
    'submit:first',  'settled:first',
    'submit:second', 'returned:second',
    'submit:COMMIT',
  ], 'in a ->then: one at a time -- the first settled before the second went '
   . 'out -- and COMMIT last';
}

# ---------------------------------------------------------------------------
# 4. KNOWN LIMIT, kept as TODO: a synchronous statement from the ->then of the
#    first of two asynchronous statements, while the second still waits for
#    the connection. Issue order puts the synchronous one behind the second,
#    and the second goes out only once the first's callbacks have returned --
#    one of which is blocked in ->get. It cannot complete (the built-in
#    Future::IO impl dies, other loops hang); the POD tells the caller to
#    chain instead. NOT a k33 regression: before k33 the second and the first
#    went onto the wire together (the k94 bug), and the mock refuses that.
#    What completing it would take -- dispatching the waiting statements from
#    the loop once a callback blocks -- is noted on karr k34 for a decision.
# ---------------------------------------------------------------------------

{
  my $storage = new_storage();
  my ($rows, $second);

  my ($ok, @r) = bounded(sub {
    $storage->txn_do_async(sub {
      my ($ctx) = @_;
      my $first = async_select($storage, $ctx, 'first');
      my $chained = $first->then(sub {
        $rows = sync_select($storage, $ctx, 'third');
        return Future->done;
      });
      $second = async_select($storage, $ctx, 'second');
      return Future->needs_all($chained, $second)->then(sub { Future->done('all') });
    })->get;
  });

  TODO: {
    local $TODO = 'a synchronous statement blocked in a callback cannot pass '
                . 'statements issued before it (karr k34)';
    ok $ok, 'behind a waiting statement: the synchronous statement completes'
      or diag $r[0];
    is $r[0], 'all', 'behind a waiting statement: ... and the transaction resolves';
    is_deeply $rows, [ 'row-for', 'third' ],
      'behind a waiting statement: it returns its own rows';
    ok $second && $second->is_done, 'behind a waiting statement: the waiting one resolves';
    is_deeply $storage->{wire}, [ 'BEGIN', 'first', 'second', 'third', 'COMMIT' ],
      'behind a waiting statement: issue order on the wire -- the waiting one '
      . 'first, then the synchronous one -- and COMMIT last';
  }
}

done_testing;
