use strict;
use warnings;
use Test::More;

BEGIN {
  eval { require Future; 1 } or plan skip_all => 'Future.pm not installed';
}

use DBIO::Test;
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;

# karr k407. A Future that waits on the pool and goes to a caller holds itself
# until it is ready. With Future.pm the sequence derived from the pool's
# acquire is held by the acquire Future only weakly, so a caller that lets go
# of it -- pipeline() or deploy_async() in void context, a DDL run nobody
# keeps -- would free it while the pool is busy: the body never ran and the
# answer came with "lost a sequence Future".
#
# The claims, with a pool of one connection that is taken:
#
#   * pipeline(), the pooled branch of deploy_async() and a pooled DDL run,
#     dropped by the caller, still run once the connection is released;
#   * the connection goes back to the pool afterwards: the next acquire is
#     served;
#   * nothing is warned on the way.
#
# A caller that keeps the Future sees no difference (control). The transport
# uses Future.pm, not DBIO::Test::Future, which holds its chain from the head.

{
  package K407::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package K407::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection   { K407::Conn->new(++$_[0]->{_next_id}) }
  sub _shutdown_connection { return }
}

{
  package K407::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { '' }

  sub pool {
    return $_[0]->{pool} ||= K407::Pool->new(
      conninfo     => 'fake',
      size         => 1,
      future_class => 'Future',
    );
  }

  sub _install_ddl           { 'CREATE TABLE k407 (id integer)' }
  sub _use_transactional_ddl { 0 }
  sub _warn_non_txn_ddl_once { return }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @{ $self->{captured} }, $sql;
    return Future->done;
  }

  sub _pipeline_enter { push @{ $_[0]->{captured} }, 'PIPELINE_ENTER'; 1 }
  sub _pipeline_sync  { push @{ $_[0]->{captured} }, 'PIPELINE_SYNC'; Future->done }
  sub _pipeline_exit  { push @{ $_[0]->{captured} }, 'PIPELINE_EXIT'; 1 }
}

sub new_backend {
  my $schema  = DBIO::Test->init_schema;
  my $backend = K407::Backend->new($schema);
  $backend->_owner_storage($schema->storage);
  $backend->{_test_schema_guard} = $schema;
  $backend->{captured} = [];
  return $backend;
}

# Start with the only connection taken, drop what is returned (or keep it),
# then give the connection back. Returns what was warned and the kept Future.
sub run_with_busy_pool {
  my ($backend, $start, $keep) = @_;
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, @_ };

  my $conn   = $backend->pool->acquire->get;
  my $result = $start->($backend);
  my $kept   = $keep ? $result : undef;
  undef $result;
  ok !@{ $backend->{captured} }, 'nothing runs while the connection is taken';

  $backend->pool->release($conn);
  return (\@warnings, $kept);
}

sub connection_back {
  my ($backend, $label) = @_;
  my $next = $backend->pool->acquire;
  ok $next->is_ready && !$next->is_failed, "$label: the next acquire is served";
  $backend->pool->release($next->get) if $next->is_ready && !$next->is_failed;
}

my %start = (
  pipeline => sub {
    my $backend = shift;
    return $backend->pipeline(sub { return 'batch' });
  },
  deploy_async => sub {
    my $backend = shift;
    return $backend->deploy_async(undef, {});
  },
  _start_ddl_run_async => sub {
    my $backend = shift;
    return $backend->_start_ddl_run_async(
      [ 0, 'CREATE TABLE k407 (id integer)' ], $backend->pool,
    );
  },
);

my %ran = (
  pipeline             => qr/PIPELINE_ENTER/,
  deploy_async         => qr/CREATE TABLE k407/,
  _start_ddl_run_async => qr/CREATE TABLE k407/,
);

for my $name (sort keys %start) {
  {
    my $backend = new_backend();
    my ($warnings) = run_with_busy_pool($backend, $start{$name}, 0);
    like join("\n", @{ $backend->{captured} }), $ran{$name},
      "$name dropped: the body runs once the connection is back";
    is_deeply $warnings, [], "$name dropped: nothing is warned";
    connection_back($backend, "$name dropped");
  }
  {
    my $backend = new_backend();
    my ($warnings, $kept) = run_with_busy_pool($backend, $start{$name}, 1);
    ok $kept->is_ready && !$kept->is_failed, "$name kept: the Future is done";
    like join("\n", @{ $backend->{captured} }), $ran{$name}, "$name kept: the body runs";
    is_deeply $warnings, [], "$name kept: nothing is warned";
    connection_back($backend, "$name kept");
  }
}

done_testing;
