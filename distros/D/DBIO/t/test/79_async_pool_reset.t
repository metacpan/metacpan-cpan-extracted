use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k398. A pooled connection kept the session state its borrower left on it
# (SET ROLE, set_config, search_path, temp tables, advisory locks) and the next
# borrower, a different request, ran in it. The rule now: a connection is reset
# at the end of each borrow, before anyone else gets it.
#
#   * release stays the synchronous return of ownership. The pool takes the
#     connection into `resetting`, asks the storage's _reset_pool_connection,
#     keeps its slot taken and gives it to nobody until the Future is done;
#   * a second release of it is a no-op;
#   * a seam that fails, dies, answers no Future, or does not answer within
#     reset_timeout (default 10) retires the connection;
#   * the default seam of DBIO::Storage::Async fails: a transport without a
#     reset of its own gets a fresh connection for every borrow;
#   * shutdown, a fork and a retirement void a running reset, and shutdown sends
#     no disconnect statement beside it;
#   * the reset is at the borrow's boundary: a transaction's pinned statements
#     do not reset, its end does.
#
# Needs Future.pm: timers and resets are cancelled.

unless (eval { require Future; 1 }) {
  plan skip_all => 'Future not installed';
}

{
  package K398::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K398::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection   { K398::Conn->new(++$_[0]->{_next_id}) }
  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]->{id} }
}

{
  package K398::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }

  sub pool {
    my $self = shift;
    return $self->{pool} ||= K398::Pool->new(
      conninfo => 'fake', size => 1, storage => $self, future_class => 'Future',
    );
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{log} }, $sql;
    return Future->done;
  }

  sub _delay {
    my ($self, $seconds) = @_;
    my $timer = Future->new;
    push @{ $self->{delays} }, { seconds => $seconds, timer => $timer };
    return $timer;
  }

  sub _teardown_pool_connection {
    my ($self, $conn) = @_;
    push @{ $self->{log} }, "disconnect:$conn->{id}";
  }
}

# A transport with a reset of its own: every reset is a Future the test settles.
{
  package K398::Resetting;
  use base 'K398::Backend';
  sub _reset_pool_connection {
    my ($self, $conn) = @_;
    my $f = Future->new;
    push @{ $self->{log} }, "reset:$conn->{id}";
    push @{ $self->{resets} }, { conn => $conn, future => $f };
    return $f;
  }
}

sub new_backend {
  my (%args) = @_;
  my $class   = delete $args{class} || 'K398::Resetting';
  my $options = delete $args{options};
  my $schema  = DBIO::Test->init_schema;
  my $backend = $class->new($schema);
  my $owner   = $schema->storage;
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $backend->{_test_schema_guard} = $schema;
  $backend->{log}    = [];
  $backend->{delays} = [];
  $backend->{resets} = [];
  $backend->{_async_options} = $options || {};
  return $backend;
}

sub borrowed {
  my ($backend) = @_;
  my $pool = $backend->pool;
  my $conn = $pool->acquire->get;
  return ($pool, $conn, $pool->_lease($conn));
}

# --- release asks the seam; the connection is idle only after its answer ---------------
{
  my $backend = new_backend();
  my ($pool, $conn, $lease) = borrowed($backend);

  $pool->release($conn, $lease);
  is_deeply $backend->{log}, [ 'reset:1' ], 'release: the seam was asked';
  is $pool->available, 0, 'release: the connection is not idle while it resets';
  is $pool->size, 1, 'release: and its slot stays taken';

  my $waiter = $pool->acquire;
  ok !$waiter->is_ready, 'release: a caller waits for the reset to end';

  $backend->{resets}[0]{future}->done;
  ok $waiter->is_ready && !$waiter->is_failed, 'release: the waiter gets the connection after the reset';
  is $waiter->get->{id}, 1, 'release: the very connection, reset';
  is $pool->available, 0, 'release: handed on, not idle';
}
{
  my $backend = new_backend();
  my ($pool, $conn, $lease) = borrowed($backend);
  $pool->release($conn, $lease);
  $backend->{resets}[0]{future}->done;
  is $pool->available, 1, 'no waiter: the connection is idle after the reset';
  is scalar @{ $backend->{resets} }, 1, 'and was reset once';
}

# --- a second release while it resets is a no-op ---------------------------------------
{
  my $backend = new_backend();
  my ($pool, $conn, $lease) = borrowed($backend);
  $pool->release($conn, $lease);
  $pool->release($conn, $lease);
  $pool->release($conn);
  is scalar @{ $backend->{resets} }, 1, 'double release: the seam is asked once, with or without the lease';
  $backend->{resets}[0]{future}->done;
  is $pool->available, 1, 'double release: the connection is idle once';
  is scalar @{ $pool->{_idle} }, 1, 'double release: and listed once';
}

# --- failure of the seam retires -------------------------------------------------------
{
  my $backend = new_backend();
  my ($pool, $conn, $lease) = borrowed($backend);
  $pool->release($conn, $lease);
  my $waiter = $pool->acquire;
  $backend->{resets}[0]{future}->fail('reset refused');
  is_deeply $pool->{closed}, [ 1 ], 'seam fails: the connection was retired';
  ok $waiter->is_ready && !$waiter->is_failed, 'seam fails: the waiter got a replacement';
  is $waiter->get->{id}, 2, 'seam fails: a fresh connection';
}
{
  package K398::Dying;
  use base 'K398::Backend';
  sub _reset_pool_connection { die "no reset today\n" }
}
{
  my $backend = new_backend(class => 'K398::Dying');
  my ($pool, $conn, $lease) = borrowed($backend);
  eval { $pool->release($conn, $lease); 1 };
  is $@, '', 'seam dies: release does not throw';
  is_deeply $pool->{closed}, [ 1 ], 'seam dies: the connection was retired';
  is $pool->size, 0, 'seam dies: its slot is free';
}
{
  package K398::NoFuture;
  use base 'K398::Backend';
  sub _reset_pool_connection { return 'done' }
}
{
  my $backend = new_backend(class => 'K398::NoFuture');
  my ($pool, $conn, $lease) = borrowed($backend);
  $pool->release($conn, $lease);
  is_deeply $pool->{closed}, [ 1 ], 'seam answers no Future: the connection was retired';
}

# --- the default seam retires -----------------------------------------------------------
{
  my $backend = new_backend(class => 'K398::Backend');
  my ($pool, $conn, $lease) = borrowed($backend);
  $pool->release($conn, $lease);
  is_deeply $pool->{closed}, [ 1 ], 'default: a transport without a reset retires the connection';
  is $pool->available, 0, 'default: nothing idle';
  my $next = $pool->acquire;
  is $next->get->{id}, 2, 'default: the next borrower gets a fresh connection';
}

# --- the reset is bounded --------------------------------------------------------------------
{
  my $backend = new_backend();
  my ($pool, $conn, $lease) = borrowed($backend);
  $pool->release($conn, $lease);
  is scalar @{ $backend->{delays} }, 1, 'timeout: a timer is made';
  is $backend->{delays}[0]{seconds}, 10, 'timeout: of 10 seconds by default';

  my $waiter = $pool->acquire;
  $backend->{delays}[0]{timer}->done;
  is_deeply $pool->{closed}, [ 1 ], 'timeout: the connection was retired';
  ok $backend->{resets}[0]{future}->is_cancelled, 'timeout: the reset was cancelled';
  is $waiter->get->{id}, 2, 'timeout: the waiter got a fresh connection';
  is $pool->available, 0, 'timeout: no idle connection';
}
{
  my $backend = new_backend(options => { reset_timeout => 3 });
  my ($pool, $conn, $lease) = borrowed($backend);
  $pool->release($conn, $lease);
  is $backend->{delays}[0]{seconds}, 3, 'option: reset_timeout sets the bound';

  $backend->{resets}[0]{future}->done;
  ok $backend->{delays}[0]{timer}->is_cancelled, 'in time: the timer was stopped';
  is $pool->available, 1, 'in time: the connection is idle';
}
{
  my $backend = new_backend(options => { reset_timeout => 0 });
  my ($pool, $conn, $lease) = borrowed($backend);
  $pool->release($conn, $lease);
  is scalar @{ $backend->{delays} }, 0, 'reset_timeout 0: no timer';
}
{
  my $backend = new_backend(options => { reset_timeout => 'soon' });
  eval { $backend->pool; 1 };
  like $@, qr/Connect option 'reset_timeout' takes/, 'an invalid reset_timeout is refused';
  unlike $@, qr/soon/, 'and the message names no value';
  ok scalar(grep { $_ eq 'reset_timeout' } DBIO::Storage::Async->declared_async_option_names),
    'reset_timeout is a declared async option';
}

# --- shutdown during a reset ------------------------------------------------------------------
{
  my $backend = new_backend();
  my ($pool, $conn, $lease) = borrowed($backend);
  $pool->release($conn, $lease);
  $pool->shutdown;
  is_deeply $pool->{closed}, [ 1 ], 'shutdown: the resetting connection is closed once';
  is_deeply [ grep { /^disconnect/ } @{ $backend->{log} } ], [],
    'shutdown: no disconnect statement is sent beside the reset';
  ok $backend->{resets}[0]{future}->is_cancelled, 'shutdown: the reset was cancelled';
  ok $backend->{delays}[0]{timer}->is_cancelled, 'shutdown: and its timer';
  is $pool->available, 0, 'shutdown: nothing idle';
}
{
  my $backend = new_backend();
  my ($pool, $conn, $lease) = borrowed($backend);
  $pool->release($conn, $lease);
  my $resets = $backend->{resets}[0];
  $pool->shutdown;
  eval { $resets->{future}->done; 1 };
  is $@, '', 'shutdown: a late answer of the reset changes nothing';
  is $pool->available, 0, 'shutdown: and idles nothing';
}

# --- a fork voids the reset ---------------------------------------------------------------------
{
  my $backend = new_backend();
  my ($pool, $conn, $lease) = borrowed($backend);
  $pool->release($conn, $lease);
  $pool->{_owner_pid} = $$ + 1;
  $pool->_verify_pid;
  ok !$backend->{resets}[0]{future}->is_cancelled, 'fork: the parent\'s reset is left alone';
  $backend->{resets}[0]{future}->done;
  is $pool->available, 0, 'fork: its answer idles nothing in the child';
  is $pool->size, 0, 'fork: the child holds nothing of it';
}

# --- retiring the connection voids the reset --------------------------------------------------
{
  my $backend = new_backend();
  my ($pool, $conn, $lease) = borrowed($backend);
  $pool->release($conn, $lease);
  $pool->_retire_connection($conn);
  $backend->{resets}[0]{future}->done if !$backend->{resets}[0]{future}->is_ready;
  is_deeply $pool->{closed}, [ 1 ], 'retire: closed once';
  is $pool->available, 0, 'retire: a late answer idles nothing';
}

# --- reported dead during the reset ---------------------------------------------------------------
{
  my $backend = new_backend();
  my ($pool, $conn, $lease) = borrowed($backend);
  $pool->release($conn, $lease);
  $pool->_mark_connection_dead($conn);
  $backend->{resets}[0]{future}->done;
  is_deeply $pool->{closed}, [ 1 ], 'dead meanwhile: retired, not idled';
}

# --- the reset is at the borrow's boundary ----------------------------------------------------------
{
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub {
    my ($ctx) = @_;
    return $ctx->_query_async('SET ROLE tenant_42', [])->then(sub {
      return $ctx->_query_async('SELECT 1', []);
    });
  });
  ok $f->is_ready && !$f->is_failed, 'transaction: committed';
  is_deeply $backend->{log}, [ 'BEGIN', 'SET ROLE tenant_42', 'SELECT 1', 'COMMIT', 'reset:1' ],
    'transaction: pinned statements reset nothing; the reset follows COMMIT, once';
  my $pool = $backend->pool;
  is $pool->available, 0, 'transaction: the connection waits for its reset';
  $backend->{resets}[0]{future}->done;
  is $pool->available, 1, 'transaction: idle after it';
}
{
  my $backend = new_backend();
  my $f = $backend->txn_do_async(sub { Future->fail("coderef failed\n") });
  ok $f->is_failed, 'rolled back transaction: fails';
  is_deeply $backend->{log}, [ 'BEGIN', 'ROLLBACK', 'reset:1' ],
    'rolled back transaction: the reset follows ROLLBACK';
}

# --- a pool with no owning storage is not a session pool -----------------------------------------------
{
  my $pool = K398::Pool->new(conninfo => 'fake', size => 1, acquire_timeout => 0);
  my $conn = $pool->acquire->get;
  $pool->release($conn);
  is $pool->available, 1, 'standalone pool: released straight to idle';
}

done_testing;
