use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Test::AsyncHarness;
use DBIO::Test::AsyncParity;
use DBIO::SQLMaker;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;
use DBIO::Storage::PoolBase;

unless (eval { require Future; 1 }) {
  plan skip_all => 'Future not installed';
}

# karr k400 (4). The cases 42 to 56 of DBIO::Test::AsyncParity::Cases make the
# fixes of the async scaffold (pipeline death k396, ROLLBACK k395, pool limits
# k397, session reset k398, masked connect errors k400) visible on a real
# transport. t/test/69_async_parity.t has a transport without pool, pipeline and
# cancel and so skips most of them. This file runs them against a transport that
# has all three: a real DBIO::Storage::Async over a real PoolBase and the real
# Future, whose "server" is a table of fake connections with session state.
#
# What is claimed: on a transport that behaves, each case passes; on one that
# does not (a pool that does not reset, a connect error that quotes the
# password) the case is red and says why.

{
  package Scaffold::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package Scaffold::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection   { Scaffold::Conn->new(++$_[0]->{_next_id}) }
  sub _shutdown_connection { }
}

{
  package Scaffold::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class     { 'Future' }
  sub sql_maker_class  { 'DBIO::SQLMaker' }
  sub _sql_maker_args  { (quote_char => '"', name_sep => '.') }
  sub _transform_sql   { $_[1] }
  sub _post_insert_sql { ' RETURNING *' }

  sub pool {
    my $self = shift;
    return $self->{pool} ||= Scaffold::Pool->new(
      conninfo => 'fake', size => 3, storage => $self, future_class => 'Future',
    );
  }

  # timers fire when the harness ticks its "loop"
  sub _delay {
    my ($self) = @_;
    my $timer = Future->new;
    push @{ $self->{timers} }, $timer;
    return $timer;
  }

  sub _reset_pool_connection {
    my ($self, $conn) = @_;
    delete $conn->{tmp};
    return Future->done;
  }

  sub _answer {
    my ($self, $conn, $sql, $bind) = @_;
    my @v = map { ref $_ eq 'ARRAY' ? $_->[-1] : $_ } @{ $bind || [] };
    return Future->fail("duplicate key value violates unique constraint\n")
      if $sql =~ /\AINSERT INTO "?artist"?/i and grep { defined $_ and $_ eq 'Caterwauler McCrae' } @v;
    return Future->done({ artistid => 1 }) if $sql =~ /\AINSERT/;
    if ($sql =~ /\ACREATE TEMPORARY TABLE/) { $conn->{tmp} = 1; return Future->done }
    if ($sql =~ /FROM parity_session_tmp/) {
      return $conn->{tmp} ? Future->done : Future->fail("relation \"parity_session_tmp\" does not exist\n");
    }
    return Future->done([ $sql =~ /\bWHERE\b/ ? 0 : 3 ]) if $sql =~ /COUNT/;
    return Future->done;
  }

  sub _query_async {
    my ($self, $sql, $bind) = @_;
    my $pool = $self->pool;
    return $pool->acquire->then(sub {
      my ($conn) = @_;
      my $answer = $self->_answer($conn, $sql, $bind);
      return $answer->then(
        sub { my @r = @_; $pool->release($conn); return Future->done(@r) },
        sub { my $e = shift; $pool->release($conn); return Future->fail($e) },
      );
    });
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    return Future->fail("ROLLBACK not confirmed\n") if $sql eq 'ROLLBACK' and $self->{rollback_fails};
    return $self->_answer($conn, $sql, $bind);
  }

  sub _pipeline_enter { 1 }
  sub _pipeline_sync  { Future->done }
  sub _pipeline_exit  { 1 }
}

{
  # a pool that gives a connection back with the session state of its last
  # borrower
  package Scaffold::Leaky;
  use base 'Scaffold::Backend';
  sub _reset_pool_connection { Future->done }
}

{
  # a connect that fails the way a client library does: asynchronously, with
  # the connection string it was given in the text
  package Scaffold::UnreachablePool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection {
    my ($self, $info) = @_;
    return $self->_create_ready_connection(conninfo => $info);
  }
  sub _new_connection {
    my ($self, %args) = @_;
    my $conn = bless {}, 'Scaffold::Conn';
    my $on_error = $args{on_error};
    push @{ $self->{pending_errors} }, sub {
      $on_error->("connection to server failed (conninfo: $args{conninfo})");
    };
    return $conn;
  }
  sub _shutdown_connection { }

  package Scaffold::Unreachable;
  use base 'Scaffold::Backend';
  our $SECRET;
  sub pool {
    my $self = shift;
    return $self->{pool} ||= Scaffold::UnreachablePool->new(
      conninfo => "host=nowhere user=app password=$SECRET", size => 1, future_class => 'Future',
    );
  }
  sub _tick { my $p = $_[0]->{pool}; ( shift @{ $p->{pending_errors} || [] } || sub { } )->() }
}

DBIO::Storage::DBI->register_async_mode( scaffold             => 'Scaffold::Backend' );
DBIO::Storage::DBI->register_async_mode( scaffold_leaky       => 'Scaffold::Leaky' );
DBIO::Storage::DBI->register_async_mode( scaffold_unreachable => 'Scaffold::Unreachable' );

sub connected {
  my ($mode) = @_;
  my $schema = DBIO::Test->init_schema;
  $schema->storage->mock_persistent(qr/COUNT/i, [ [0] ]);
  $schema->storage->_async_mode($mode);
  delete $schema->storage->{_async_storage_obj};
  return $schema;
}

{
  package Scaffold::Harness;
  use base 'DBIO::Test::AsyncHarness';

  __PACKAGE__->harness_env_prefix('SCAFFOLD');
  __PACKAGE__->harness_async_mode('scaffold');
  __PACKAGE__->harness_required_modules([]);
  __PACKAGE__->harness_schema_class('DBIO::Test::Schema');

  sub live_available { 1 }

  sub new {
    my ($class, $mode) = @_;
    return bless { schema => main::connected($mode // 'scaffold'), schema_class => 'DBIO::Test::Schema', timeout => 5 }, $class;
  }

  # the "event loop": timers fire, a connect error comes in
  sub _tick_loop {
    my ($self) = @_;
    for my $schema (grep { defined } $self->{schema}, $self->{unreachable_schema}) {
      my $backend = $schema->storage->_async_storage;
      $_->done for grep { !$_->is_ready } @{ delete $backend->{timers} || [] };
      $backend->_tick if $backend->can('_tick');
    }
  }
}

{
  package Scaffold::Suite;
  use base 'DBIO::Test::AsyncParity';

  sub parity_seed  { }
  sub parity_reset { }

  sub parity_capabilities {
    my ($class, $harness) = @_;
    return ($class->SUPER::parity_capabilities($harness),
      'fault:rollback_fails', 'unreachable_connection');
  }

  sub parity_fault {
    my ($class, $schema, $harness, $name) = @_;
    return $class->SUPER::parity_fault($schema, $harness, $name) unless $name eq 'rollback_fails';
    my $backend = $schema->storage->_async_storage;
    $backend->{rollback_fails} = 1;
    return bless { backend => $backend }, 'Scaffold::Fault';
  }

  sub parity_unreachable {
    my ($class, $harness, $secret) = @_;
    $Scaffold::Unreachable::SECRET = $secret;
    my $schema = main::connected('scaffold_unreachable');
    $harness->{unreachable_schema} = $schema;
    return $schema;
  }

  package Scaffold::Fault;
  sub DESTROY { $_[0]{backend}{rollback_fails} = 0 }
}

my @NEW = qw(
  pipeline-commit pipeline-fail cancel-txn cancel-statement cancel-batch
  rollback-failed txn-statement-in-flight txn-statement-in-flight-fails
  pool-self-deadlock pool-max-waiters pool-acquire-timeout session-reset
  connect-error-masked
);

# the transport that behaves
{
  my $h = Scaffold::Harness->new;
  my @warned;
  my @r = do {
    local $SIG{__WARN__} = sub { push @warned, @_ };
    Scaffold::Suite->results(harness => $h, only => \@NEW);
  };
  unlike join('', @warned), qr/parity-secret/, 'the pool\'s warnings carry no password';
  is scalar(@r), scalar(@NEW), 'a result for every case of the scaffold';
  for my $r (@r) {
    is $r->{status}, 'pass', sprintf '%02d %s passes on a transport that behaves', $r->{no}, $r->{case}
      or diag $r->{message};
  }
}

# listen-notify and disconnect-in-txn are skipped here, by their capabilities
{
  my $h = Scaffold::Harness->new;
  my %r = map { $_->{case} => $_ } Scaffold::Suite->results(harness => $h, only => [ qw(listen-notify disconnect-in-txn) ]);
  is $r{'listen-notify'}{status}, 'skipped', 'listen-notify: skipped without listen and notify';
  is $r{'disconnect-in-txn'}{status}, 'skipped', 'disconnect-in-txn: skipped without its fault';
}

# a pool that does not reset
{
  my $h = Scaffold::Harness->new('scaffold_leaky');
  my ($r) = Scaffold::Suite->results(harness => $h, only => ['session-reset']);
  is $r->{status}, 'fail', 'session-reset: a pool that does not reset is red';
  like $r->{message}, qr/answered \['leaked'\], expected \['reset'\]/, 'and says the state leaked';
}

# a connect error that carries the password
{
  package Scaffold::Quoting;
  use base 'Scaffold::Suite';
  # what the pool did before the error was masked: the text as it came
  sub parity_unreachable {
    my ($class, $harness, $secret) = @_;
    my $schema = $class->SUPER::parity_unreachable($harness, $secret);
    no warnings 'redefine';
    *Scaffold::UnreachablePool::_mask_connect_error = sub { $_[1] };
    return $schema;
  }
}
{
  my $h = Scaffold::Harness->new;
  local $SIG{__WARN__} = sub { };
  my ($r) = Scaffold::Quoting->results(harness => $h, only => ['connect-error-masked']);
  is $r->{status}, 'fail', 'connect-error-masked: an error that quotes the password is red';
  like $r->{message}, qr/leaked/, 'and says it leaked';
}

done_testing;
