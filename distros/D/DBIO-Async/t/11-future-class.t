use strict;
use warnings;
use Test::More;
use Future;

use DBIO::Async::Storage;

# OFFLINE test for karr k13 point 2: the Future::IO watcher seam must mint its
# Futures through $self->future_class, never through a literal Future->.
#
# WHAT THIS PROVES: a subclass that names its own Future implementation gets
# THAT class out of _await_conn_ready (both branches) and _await_query_result,
# rather than a mix of its class and plain Future. Mixed classes are not
# cosmetic: a caller combining these Futures with its own
# ->needs_all/->wait_all, or relying on its subclass's failure semantics,
# silently loses them on whichever leg was a plain Future.
#
# WHICH ASSERTION SAMPLES WHICH LITERAL:
#  * the immediate-ready branch is a bare `Future->done($conn)` -- the class is
#    decided there, so the success assertion samples it directly.
#  * the two `Future->call(sub {...})` sites decide the class only when the
#    block DIES: on success Future::call returns whatever the block returned
#    (verified against Future 0.52), so the class rides in from _await_readable
#    and the ->then chain. Each of those branches is therefore asserted twice --
#    the success case covers the branch end-to-end (no plain Future may leak out
#    of it), the failure case is the one that samples the swapped ->call itself.
#
# Against the pre-fix code four of these thirteen assertions are red: both
# failure cases, the immediate-ready branch, and the wait branch's success case
# (it resolves through the recursion, which lands in the immediate branch).
# _await_query_result's success case is green either way -- which is exactly
# why the failure cases are here.

{
  package FCFuture;
  use base 'Future';
}

{
  package FCMock;
  use base 'DBIO::Async::Storage';

  sub future_class { 'FCFuture' }

  # A subclass with its own Future implementation also owns the loop seam --
  # Future::IO always hands back a plain Future -- so the mock overrides
  # _await_readable, exactly as such a driver would.
  sub _await_readable {
    my ($self, $conn) = @_;
    die "readable failed\n" if $self->{fail_readable};
    return FCFuture->done;
  }

  # $conn->{cold} counts how many times this answers "not ready" before it
  # answers "ready", so one mock drives both branches.
  sub _conn_ready {
    my ($self, $conn) = @_;
    $self->{ready_checks}++;
    return $conn->{cold}-- > 0 ? 0 : 1;
  }

  sub _submit_query {
    my ($self, $conn, $sql, $bind) = @_;
    die "submit failed\n" if $self->{fail_submit};
    push @{ $self->{wire} }, $sql;
    return;
  }

  sub _collect_result { FCFuture->done([1]) }

  sub _normalize_conninfo       { $_[1] }
  sub _create_pool_connection   { {} }
  sub _shutdown_pool_connection { }
}

sub new_storage { FCMock->new(undef) }

# --- 1. _await_conn_ready, immediate branch ---

{
  my $storage = new_storage;
  my $conn    = { cold => 0 };

  my $f = $storage->_await_conn_ready($conn);
  isa_ok $f, 'FCFuture',
    '_await_conn_ready on an already-ready connection returns future_class';
  is $f->get, $conn, '... resolving to the connection';
  is $storage->{ready_checks}, 1, '... without ever waiting on the fd';
}

# --- 2. _await_conn_ready, wait branch ---
# Cold connection: the seam waits on _await_readable and re-checks readiness.

{
  my $storage = new_storage;
  my $conn    = { cold => 1 };

  my $f = $storage->_await_conn_ready($conn);
  isa_ok $f, 'FCFuture',
    '_await_conn_ready wait branch returns future_class (no plain Future leaks)';
  is $f->get, $conn, '... resolving to the connection';
  is $storage->{ready_checks}, 2, '... and it really went through the wait branch';
}

# --- 3. _await_conn_ready, wait branch, failure ---
# The assertion that samples the Future->call literal: the block dies, so the
# class of the failed Future is the one ->call was invoked on.

{
  my $storage = new_storage;
  $storage->{fail_readable} = 1;

  my $f = $storage->_await_conn_ready({ cold => 1 });
  isa_ok $f, 'FCFuture',
    '_await_conn_ready wait branch fails in future_class, not plain Future';
  is scalar($f->failure), "readable failed\n", '... carrying the failure';
}

# --- 4. _await_query_result ---

{
  my $storage = new_storage;

  my $f = $storage->_await_query_result({ cold => 0 }, 'SELECT 1', []);
  isa_ok $f, 'FCFuture',
    '_await_query_result returns future_class (no plain Future leaks)';
  is_deeply scalar($f->get), [1], '... resolving to the collected result';
  is $storage->{wire}[0], 'SELECT 1', '... after dispatching the query';
}

# --- 5. _await_query_result, failure ---
# Samples the second Future->call literal.

{
  my $storage = new_storage;
  $storage->{fail_submit} = 1;

  my $f = $storage->_await_query_result({ cold => 0 }, 'SELECT 1', []);
  isa_ok $f, 'FCFuture',
    '_await_query_result fails in future_class, not plain Future';
  is scalar($f->failure), "submit failed\n", '... carrying the failure';
}

done_testing;
