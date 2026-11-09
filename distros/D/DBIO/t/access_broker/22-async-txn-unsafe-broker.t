# ABSTRACT: An async backend refuses a transaction through a broker that is not transaction-safe
use strict;
use warnings;

use Test::More;
use Test::Exception;
use Scalar::Util qw(blessed);

use DBIO::Test;
use DBIO::Test::Storage;
use DBIO::Test::Future ();
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use DBIO::AccessBroker;
use DBIO::AccessBroker::Static;
use DBIO::AccessBroker::Vault;

# OFFLINE (karr k270). DBIO::AccessBroker's TRANSACTION SAFETY: "Starting a
# transaction through a broker marked as unsafe will throw by default", with
# DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS=1 to proceed under a warning. The sync
# storage keeps that in txn_begin (_assert_transaction_safe_access_broker;
# 02-vault.t), and with it the async modes that run the sync transaction
# underneath -- 'immediate' in-process (claim 7), and dbio-forked, which runs
# txn_do on the sync storage in its child (read there, not run here). A real
# DBIO::Storage::Async backend (future_io, ev) never asked: txn_do_async took a
# pool connection and sent BEGIN whatever the broker was. Nothing ran the path
# with a rotating broker, in core or in a transport dist.
#
# What this file claims, on a DBIO::Storage::Async backend:
#   1. txn_do_async through an unsafe broker -- a rotating one, the real Vault
#      broker, a HostBound view over one, one that declares itself unsafe for
#      a reason of its own -- returns a FAILED FUTURE (it does not throw): a
#      DBIO::Exception naming the broker class and the reason, no value of its
#      answer. The coderef does not run, no connection is taken from the pool
#      or built, and nothing goes to the wire.
#   2. With DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS set, the transaction runs --
#      BEGIN, the coderef, COMMIT -- and each transaction start warns, naming
#      the broker class and the reason. A false value of the variable is no
#      override.
#   3. A safe broker (Static, a custom one that does not rotate) and a backend
#      without a broker run transactions, without a warning (control).
#   4. The blocking wrapper txn_do throws the refusal.
#   5. deploy_async on an engine with transactional DDL runs its DDL in a
#      transaction, so it is refused the same way; on an engine without, no
#      transaction is started and the DDL runs.
#   6. pipeline() is refused like txn_do_async (karr k273): a failed Future
#      before the pool is touched; the override lets it run under a warning;
#      safe brokers pipeline as before.
#   7. Through the storage a schema holds, connected { async => $mode }: its
#      txn_do_async reaches the backend and comes back refused; and the same
#      refusal in 'immediate' mode -- one answer in every async mode.
#
# THE SUBSTITUTIONS: a real DBIO::Storage::PoolBase whose connections are
# recorded instead of opened; a transport that records every statement instead
# of sending it and answers at once; a stub vault; a fake driver storage
# (DBIO::Test::Storage) for claim 7.

# --- the wire, the pool -----------------------------------------------------

our (@WIRE, @BUILT, @ACQUIRED);

{
  package T::Conn;
  sub new { bless { id => $_[1] }, $_[0] }
}

{
  package T::Pool;
  use base 'DBIO::Storage::PoolBase';
  sub _create_connection { my ($self, $conninfo) = @_; push @main::BUILT, $conninfo; T::Conn->new(scalar @main::BUILT) }
  sub _transform_conninfo { $_[1] }
  sub acquire { my $self = shift; push @main::ACQUIRED, 1; return $self->SUPER::acquire(@_) }
}

{
  package T::DDL;
  sub install_ddl { "CREATE TABLE artist (id int);\nCREATE TABLE cd (id int);" }
}

{
  package T::Backend;
  use base 'DBIO::Storage::Async';

  sub future_class { 'DBIO::Test::Future' }
  sub _ddl_class   { 'T::DDL' }

  sub _async_broker_conninfo {
    my ($self, $mode) = @_;
    my ($conninfo) = $self->_normalize_async_connect_info($self->_current_async_connect_info($mode));
    return $conninfo;
  }

  sub pool {
    my $self = shift;
    $self->{pool} ||= T::Pool->new(
      size         => 2,
      future_class => $self->future_class,
      ($self->_conninfo_provider
        ? (conninfo_provider => $self->_conninfo_provider)
        : (conninfo          => $self->{_conninfo})),
    );
  }

  sub _query_async_pinned {
    my ($self, $conn, $sql, $bind) = @_;
    push @main::WIRE, $sql;
    return $self->future_class->done;
  }

  sub _pipeline_enter { push @main::WIRE, '<pipeline enter>'; 1 }
  sub _pipeline_sync  { push @main::WIRE, '<pipeline sync>'; $_[0]->future_class->done }
  sub _pipeline_exit  { push @main::WIRE, '<pipeline exit>'; 1 }
}

# An owner that only answers the transactional-DDL probe (claim 5).
{
  package T::DDLOwner;
  sub new { bless { txn => $_[1] }, $_[0] }
  sub _use_transactional_ddl { $_[0]{txn} }
}

# --- the brokers ------------------------------------------------------------

my $VALUE = qr/k270-(?:user|secret)/;   # every credential in this file

{
  package T::Broker;   # safe: it does not rotate
  use base 'DBIO::AccessBroker';
  sub new { bless {}, shift }
  sub connect_info_for { { dbname => 'app', user => 'k270-user', password => 'k270-secret' } }
}
{
  package T::RotatingBroker;
  our @ISA = ('T::Broker');
  sub has_rotating_credentials { 1 }
}
{
  package T::UnsafeBroker;   # no rotation, unsafe for a reason of its own
  our @ISA = ('T::Broker');
  sub is_transaction_safe { 0 }
}
{
  package T::StubVault;
  sub new { bless {}, shift }
  sub read_secret { { username => 'k270-user', password => 'k270-secret' } }
}

sub vault_broker {
  return DBIO::AccessBroker::Vault->new(
    vault     => T::StubVault->new,
    dsn       => 'dbi:Fake:dbname=app',
    cred_path => 'database/creds/app',
  );
}

my $ROTATION = 'credential rotation';
my $OWN      = 'broker-specific transaction safety constraints';

# label => [ broker, the class the refusal names, the reason it names ]
my %UNSAFE = (
  'a rotating broker' =>
    [ sub { T::RotatingBroker->new }, 'T::RotatingBroker', $ROTATION ],
  'the Vault broker' =>
    [ \&vault_broker, 'DBIO::AccessBroker::Vault', $ROTATION ],
  'a HostBound view over a rotating broker' =>
    [ sub { T::RotatingBroker->new->for_host('replica.example') }, 'DBIO::AccessBroker::HostBound', $ROTATION ],
  'a HostBound view over the Vault broker' =>
    [ sub { vault_broker()->for_host('replica.example') }, 'DBIO::AccessBroker::HostBound', $ROTATION ],
  'a broker unsafe for a reason of its own' =>
    [ sub { T::UnsafeBroker->new }, 'T::UnsafeBroker', $OWN ],
);

sub refusal {
  my ($class, $reason) = @_;
  return qr/Refusing to start a transaction with unsafe AccessBroker \Q$class\E: \Q$reason\E can break transactional consistency/;
}

sub override_warning {
  my ($class, $reason) = @_;
  return qr/Starting a transaction with unsafe AccessBroker \Q$class\E via override: \Q$reason\E/;
}

sub backend_with {
  my ($broker) = @_;
  my $backend = T::Backend->new(undef);
  $backend->connect_info([ $broker ]);
  return $backend;
}

# What a Future failed with, as it was stored -- get would rethrow it wrapped.
sub failure_of {
  my ($f) = @_;
  return undef unless $f->is_failed;
  return $f->isa('DBIO::Test::Future') ? $f->{values}[0] : $f->{error};
}

# Run $code with the wire, the pool and the warnings recorded.
sub recorded (&) {
  my ($code) = @_;
  local (@WIRE, @BUILT, @ACQUIRED);
  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, "$_[0]" };
  my @result = $code->();
  return {
    result   => \@result,
    wire     => [ @WIRE ],
    built    => scalar @BUILT,
    acquired => scalar @ACQUIRED,
    warnings => \@warnings,
  };
}

delete $ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS};

# ---------------------------------------------------------------------------
# 1. Refused, as a failed Future, before anything is touched.
# ---------------------------------------------------------------------------
for my $label (sort keys %UNSAFE) {
  my ($make, $class, $reason) = @{ $UNSAFE{$label} };
  my $backend = backend_with($make->());

  my $ran = 0;
  my $seen = recorded { eval { $backend->txn_do_async(sub { $ran++; 'committed' }) } };
  my $f = $seen->{result}[0];

  ok blessed($f) && $f->can('is_failed'), "$label: txn_do_async returns a Future, it does not throw"
    or diag "threw: $@";
  SKIP: {
    skip "$label: no Future to look at", 4 unless blessed($f);
    ok $f->is_failed, "$label: the Future is failed";
    my $error = failure_of($f) // '';
    isa_ok $error, 'DBIO::Exception', "$label: its failure";
    like "$error", refusal($class, $reason), "$label: ... names the broker class and the reason";
    unlike "$error", $VALUE, "$label: ... and no value of the broker's answer";
  }
  is $ran, 0, "$label: the coderef does not run";
  is $seen->{acquired}, 0, "$label: no connection is taken from the pool";
  is $seen->{built}, 0, "$label: none is built";
  is_deeply $seen->{wire}, [], "$label: nothing goes to the wire";
  is_deeply $seen->{warnings}, [], "$label: no warning";
}

# ---------------------------------------------------------------------------
# 2. The override.
# ---------------------------------------------------------------------------
for my $label (sort keys %UNSAFE) {
  my ($make, $class, $reason) = @{ $UNSAFE{$label} };
  my $backend = backend_with($make->());

  {
    local $ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS} = 1;

    my $ran = 0;
    my $seen = recorded { $backend->txn_do_async(sub { $ran++; 'committed' }) };
    my $f = $seen->{result}[0];
    ok !$f->is_failed, "$label, override: the transaction runs" or diag failure_of($f);
    is scalar $f->get, 'committed', "$label, override: ... and resolves with the coderef's value";
    is $ran, 1, "$label, override: the coderef ran once";
    is_deeply $seen->{wire}, [ 'BEGIN', 'COMMIT' ], "$label, override: BEGIN and COMMIT went out";
    is scalar @{ $seen->{warnings} }, 1, "$label, override: one warning";
    like $seen->{warnings}[0], override_warning($class, $reason),
      "$label, override: ... naming the broker class and the reason";

    my $again = recorded { $backend->txn_do_async(sub { 'again' }) };
    is scalar @{ $again->{warnings} }, 1, "$label, override: the next transaction warns again";
  }

  {
    local $ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS} = 0;
    my $seen = recorded { $backend->txn_do_async(sub { 'committed' }) };
    like failure_of($seen->{result}[0]) // '', refusal($class, $reason),
      "$label, the variable set to 0: refused";
    is_deeply $seen->{wire}, [], "$label, the variable set to 0: nothing goes to the wire";
  }
}

# A refusal leaves the backend as it was: the same one runs the transaction
# once the override is given.
{
  my $backend = backend_with(T::RotatingBroker->new);
  ok $backend->txn_do_async(sub { 1 })->is_failed, 'refused once';
  local $ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS} = 1;
  my $seen = recorded { $backend->txn_do_async(sub { 'committed' }) };
  is scalar $seen->{result}[0]->get, 'committed', '... the same backend runs it under the override';
  is $seen->{built}, 1, '... on a connection built then, from the broker';
}

# ---------------------------------------------------------------------------
# 3. Safe brokers, and no broker (control).
# ---------------------------------------------------------------------------
my %SAFE = (
  'the Static broker' => sub {
    backend_with(DBIO::AccessBroker::Static->new(dbname => 'app', username => 'k270-user', password => 'k270-secret'));
  },
  'a broker that does not rotate' => sub { backend_with(T::Broker->new) },
  'a HostBound view over the Static broker' => sub {
    backend_with(DBIO::AccessBroker::Static->new(dbname => 'app', username => 'k270-user', password => 'k270-secret')
      ->for_host('replica.example'));
  },
  'no broker' => sub {
    my $backend = T::Backend->new(undef);
    $backend->connect_info([ { dbname => 'app', user => 'static' }, {} ]);
    return $backend;
  },
);

for my $label (sort keys %SAFE) {
  my $backend = $SAFE{$label}->();
  my $seen = recorded { $backend->txn_do_async(sub { 'committed' }) };
  my $f = $seen->{result}[0];
  ok !$f->is_failed, "$label: the transaction runs" or diag failure_of($f);
  is scalar $f->get, 'committed', "$label: ... and resolves with the coderef's value";
  is_deeply $seen->{wire}, [ 'BEGIN', 'COMMIT' ], "$label: BEGIN and COMMIT went out";
  is $seen->{acquired}, 1, "$label: on one connection from the pool";
  is_deeply $seen->{warnings}, [], "$label: without a warning";
}

# ---------------------------------------------------------------------------
# 4. The blocking wrapper.
# ---------------------------------------------------------------------------
{
  my $backend = backend_with(T::RotatingBroker->new);
  my $seen = recorded { eval { $backend->txn_do(sub { 'committed' }); 1 } ? '' : $@ };
  my $error = $seen->{result}[0];
  isa_ok $error, 'DBIO::Exception', 'txn_do through a rotating broker: what it throws';
  like "$error", refusal('T::RotatingBroker', $ROTATION), '... is the refusal';
  is_deeply $seen->{wire}, [], '... and nothing goes to the wire';
}

# ---------------------------------------------------------------------------
# 5. deploy_async.
# ---------------------------------------------------------------------------
{
  my $backend = backend_with(T::RotatingBroker->new);
  my $owner = T::DDLOwner->new(1);
  $backend->_owner_storage($owner);

  my $seen = recorded { $backend->deploy_async('schema') };
  my $f = $seen->{result}[0];
  ok $f->is_failed, 'deploy_async, transactional DDL, a rotating broker: the Future is failed';
  like "@{[ failure_of($f) // '' ]}", refusal('T::RotatingBroker', $ROTATION), '... with the refusal';
  is $seen->{acquired}, 0, '... no connection is taken from the pool';
  is_deeply $seen->{wire}, [], '... and no DDL goes to the wire';
}

{
  my $backend = backend_with(T::RotatingBroker->new);
  my $owner = T::DDLOwner->new(0);
  $backend->_owner_storage($owner);

  my $seen = recorded { $backend->deploy_async('schema') };
  my $f = $seen->{result}[0];
  ok !$f->is_failed, 'deploy_async, no transactional DDL, a rotating broker: it runs' or diag failure_of($f);
  is_deeply $seen->{wire}, [ 'CREATE TABLE artist (id int)', 'CREATE TABLE cd (id int)' ],
    '... the DDL goes out, and no BEGIN: there is no transaction to refuse';
  is scalar(grep { /unsafe AccessBroker/ } @{ $seen->{warnings} }), 0, '... without a warning about the broker';
}

# ---------------------------------------------------------------------------
# 6. pipeline() is refused like txn_do_async (karr k273, maintainer decision
#    2026-10-09): a batch is work that is meant to stand as a unit.
# ---------------------------------------------------------------------------
for my $label (sort keys %UNSAFE) {
  my ($make, $class, $reason) = @{ $UNSAFE{$label} };
  my $backend = backend_with($make->());

  my $ran = 0;
  my $seen = recorded { eval { $backend->pipeline(sub { $ran++; 'batched' }) } };
  my $f = $seen->{result}[0];
  ok blessed($f) && $f->can('is_failed') && $f->is_failed,
    "$label: pipeline returns a failed Future, it does not throw" or diag "threw: $@";
  like "@{[ blessed($f) ? failure_of($f) // '' : '' ]}", refusal($class, $reason),
    "$label: ... with the refusal txn_do_async gives";
  is $ran, 0, "$label: the coderef does not run";
  is $seen->{acquired}, 0, "$label: no connection is taken from the pool";
  is $seen->{built}, 0, "$label: none is built";
  is_deeply $seen->{wire}, [], "$label: nothing goes to the wire";
  is_deeply $seen->{warnings}, [], "$label: no warning";
}

{
  my $backend = backend_with(T::RotatingBroker->new);
  local $ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS} = 1;
  my $ran = 0;
  my $seen = recorded { $backend->pipeline(sub { $ran++; 'batched' }) };
  my $f = $seen->{result}[0];
  ok !$f->is_failed, 'under the override pipeline runs' or diag failure_of($f);
  is $ran, 1, '... the coderef ran';
  is_deeply $seen->{wire}, [ '<pipeline enter>', '<pipeline sync>', '<pipeline exit>' ],
    '... bracketed as a pipeline';
  like $seen->{warnings}[0] // '', override_warning('T::RotatingBroker', $ROTATION),
    '... with the warning';
}

for my $label (sort keys %SAFE) {
  my $backend = $SAFE{$label}->();
  my $seen = recorded { $backend->pipeline(sub { 'batched' }) };
  ok !$seen->{result}[0]->is_failed, "$label: pipeline runs";
  is_deeply $seen->{warnings}, [], "$label: ... without a warning";
}

# ---------------------------------------------------------------------------
# 7. Through the storage a schema holds.
# ---------------------------------------------------------------------------
{
  package T::FakeDriver::Storage;
  use base 'DBIO::Test::Storage';
  DBIO::Storage::DBI->register_driver(K270TxnFake => __PACKAGE__);
}
T::FakeDriver::Storage->register_async_mode(k270loop => 'T::Backend');

{
  package T::DBIFormRotatingBroker;
  use base 'DBIO::AccessBroker';
  sub new { bless {}, shift }
  sub has_rotating_credentials { 1 }
  sub connect_info_for { [ 'dbi:K270TxnFake:dbname=app', 'k270-user', 'k270-secret', {} ] }
}

sub schema_storage {
  my (@connect_info) = @_;
  my $schema = DBIO::Test->init_schema(
    no_connect   => 1,
    storage_type => '+T::FakeDriver::Storage',
  );
  return ($schema->connection(@connect_info)->storage, $schema);
}

{
  my $broker = T::DBIFormRotatingBroker->new;
  my ($storage, $schema) = schema_storage($broker, { async => 'k270loop' });
  isa_ok $storage->async, 'T::Backend', 'a schema connected { async => ... } with a rotating broker: its backend';
  is $storage->async->access_broker, $broker, '... has the broker attached';

  my $ran = 0;
  my $seen = recorded { eval { $storage->txn_do_async(sub { $ran++; 'committed' }) } };
  my $f = $seen->{result}[0];
  ok blessed($f) && $f->is_failed, "the storage's txn_do_async: a failed Future" or diag "threw: $@";
  like "@{[ blessed($f) ? failure_of($f) // '' : '' ]}", refusal('T::DBIFormRotatingBroker', $ROTATION),
    '... with the refusal';
  is $ran, 0, '... the coderef does not run';
  is_deeply $seen->{wire}, [], '... and nothing goes to the wire';

  local $ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS} = 1;
  my $allowed = recorded { $storage->txn_do_async(sub { 'committed' }) };
  is scalar $allowed->{result}[0]->get, 'committed', 'under the override it runs';
  is_deeply $allowed->{wire}, [ 'BEGIN', 'COMMIT' ], '... on the backend: BEGIN and COMMIT';
  like $allowed->{warnings}[0] // '', override_warning('T::DBIFormRotatingBroker', $ROTATION), '... with the warning';
}

{
  my ($storage, $schema) = schema_storage(T::DBIFormRotatingBroker->new, { async => 'immediate' });
  my $ran = 0;
  my $f = eval { $storage->txn_do_async(sub { $ran++; 'committed' }) };
  ok blessed($f) && $f->is_failed, "'immediate' mode with a rotating broker: a failed Future" or diag "threw: $@";
  like "@{[ blessed($f) ? failure_of($f) // '' : '' ]}", refusal('T::DBIFormRotatingBroker', $ROTATION),
    '... with the same refusal';
  is $ran, 0, '... the coderef does not run';
}

done_testing;
