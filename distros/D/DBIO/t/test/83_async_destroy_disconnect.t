use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use Scalar::Util ();

# karr k406. The chain of a running pool reset holds the async storage while it
# runs. A schema freed in that moment closes its async connections in DESTROY
# of its sync storage, the way disconnect does, without the event loop:
#
#   * the embedded async storage is disconnected: its pool shuts down, the
#     connection in its reset is closed and the reset is cancelled;
#   * a schema without an async mode builds no async storage in DESTROY;
#   * a failing teardown is reported as a warning and DESTROY ends: the sync
#     handle is released regardless;
#   * a forked child tears down nothing of the parent's.

unless (eval { require Future; 1 }) {
  plan skip_all => 'Future not installed';
}

{
  package K406::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K406::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection   { K406::Conn->new(++$_[0]->{_next_id}) }
  sub _shutdown_connection { push @{ $_[0]{closed} }, $_[1]->{id} }
}

{
  package K406::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }

  sub pool {
    my $self = shift;
    return $self->{pool} ||= K406::Pool->new(
      conninfo => 'fake', size => 1, storage => $self, future_class => 'Future',
    );
  }

  sub _delay { Future->new }

  sub _teardown_pool_connection {}

  sub _reset_pool_connection {
    my ($self, $conn) = @_;
    my $f = Future->new;
    # The chain of a running reset holds the storage it began on.
    $f->on_cancel(sub { $self });
    push @{ $self->{resets} }, $f;
    return $f;
  }
}

{
  package K406::BrokenDisconnect;
  use base 'K406::Backend';
  sub disconnect { die "teardown refused\n" }
}

{
  package K406::Dbh;
  our $released = 0;
  sub DESTROY { $released++ }
}

# A schema whose embedded async storage has a connection in its reset. Returns
# the schema and what to look at after it is gone.
sub schema_in_reset {
  my ($class) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $owner   = $schema->storage;
  my $backend = $class->new($schema);
  $backend->_owner_storage($owner);
  $owner->_async_context_owner_token($backend->_context_owner_token);
  $owner->{_async_storage_obj} = $backend;
  $backend->{resets} = [];

  my $pool = $backend->pool;
  my $conn = $pool->acquire->get;
  $pool->release($conn, $pool->_lease($conn));
  die 'the connection is not in its reset' unless @{ $backend->{resets} } == 1;

  return ($schema, $pool, $backend->{resets}[0]);
}

# --- (a) freed in the reset: the connection is closed, the reset cancelled ----------
{
  my ($pool, $reset);
  {
    my $schema;
    ($schema, $pool, $reset) = schema_in_reset('K406::Backend');
    is $pool->{closed}, undef, 'in the reset: nothing closed yet';
    ok !$reset->is_ready, 'in the reset: the reset runs';
  }
  is_deeply $pool->{closed}, [ 1 ], 'freed schema: the connection in its reset was closed without the loop';
  ok $reset->is_cancelled, 'freed schema: its reset was cancelled';
  is $pool->size, 0, 'freed schema: no connection stays open';
}

# --- (b) a schema without an async mode stays as it is --------------------------------
{
  my @w;
  local $SIG{__WARN__} = sub { push @w, @_ };
  my $storage_ref;
  {
    my $schema = DBIO::Test->init_schema;
    $storage_ref = $schema->storage;
    Scalar::Util::weaken($storage_ref);
    ok !exists $schema->storage->{_async_storage_obj}, 'sync: no async storage before';
  }
  ok !defined $storage_ref, 'sync: the storage is freed';
  is_deeply \@w, [], 'sync: DESTROY warns nothing';

  my $schema  = DBIO::Test->init_schema;
  my $storage = $schema->storage;
  $storage->DESTROY;
  ok !exists $storage->{_async_storage_obj}, 'sync: DESTROY builds no async storage';
}

# --- (c) a failing teardown is reported and DESTROY ends -------------------------------
{
  my @w;
  {
    local $SIG{__WARN__} = sub { push @w, @_ };
    my $schema  = DBIO::Test->init_schema;
    my $owner   = $schema->storage;
    my $backend = K406::BrokenDisconnect->new($schema);
    $backend->_owner_storage($owner);
    $owner->{_async_storage_obj} = $backend;
    $owner->_dbh(bless {}, 'K406::Dbh');
    undef $backend;
    undef $owner;
  }
  ok scalar(grep { /teardown refused/ } @w), 'failing teardown: reported as a warning';
  is $K406::Dbh::released, 1, 'failing teardown: DESTROY ran on, the sync handle was released';
}

# --- (d) a child does not tear down what its parent holds ------------------------------
{
  my ($schema, $pool, $reset) = schema_in_reset('K406::Backend');
  $schema->storage->_conn_pid($$ + 1);   # connected by another process
  undef $schema;
  is $pool->{closed}, undef, "child: the parent's connection is not closed by DESTROY";
  ok !$reset->is_cancelled, 'child: its reset is left alone';
}

done_testing;
