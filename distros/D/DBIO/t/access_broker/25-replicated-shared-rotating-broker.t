# ABSTRACT: One rotating broker serves a master and its replicants through HostBound views
use strict;
use warnings;

# The clock of this test. It has to be in place before DBIO::AccessBroker::Vault
# is compiled, so that the broker's time() is this one.
our $NOW;
BEGIN {
  $NOW = 1_800_000_000;
  *CORE::GLOBAL::time = sub () { $NOW };
}

use Test::More;
use Test::Exception;
use Scalar::Util qw(blessed reftype refaddr);

use DBI;
use DBIO::Storage::DBI;
use DBIO::Replicated::Storage;
use DBIO::AccessBroker::Vault;
use DBIO::AccessBroker::Static;

# OFFLINE (karr k270). One credential, many servers: a single broker -- one
# Vault lease -- and a DBIO::AccessBroker::HostBound view of it per server, the
# master's given to DBIO::Replicated as its connect info and one per replicant.
# That is the case ADR 0013 and CONTEXT.md are written around.
# 06-replicated-passthrough.t looks at the views on their own and runs
# Replicated with a separate broker per backend; nothing ran one rotating
# broker through a master and its replicants.
#
# What this file claims, with a real DBIO::Replicated::Storage over real
# DBIO::Storage::DBI backends and a real DBIO::AccessBroker::Vault:
#   1. each backend keeps the view it was given, all over the one broker, and
#      nothing reads the vault while they are set up;
#   2. each backend opens its connection on its own host -- its view's -- with
#      the credentials of the one lease;
#   3. the lease due, the backends reconnect with ONE read of the vault for
#      all of them: the first to connect rotates, the others get what it
#      fetched; the rotated-out password reaches no connection after that and
#      is kept in no backend;
#   4. a rotation caused by a replicant alone reaches the master at its next
#      connection, without another read;
#   5. a transaction through the replicated storage goes to the master, whose
#      view is not transaction-safe because its broker rotates: txn_begin and
#      txn_do are refused before anything reaches the handle. With
#      DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS it warns and begins;
#   6. the refusal is the rotation's, not the views': the same topology over a
#      broker that does not rotate (Static, whose connection parameters each
#      backend turns into its own DSN) begins its transaction on the master.
#
# Pinned as it is: DBIO::Replicated binds no host itself. The caller builds the
# views; a broker handed over without one connects that backend where the
# broker's own answer says -- for a replicant, the master's host. (The POD of
# DBIO::AccessBroker::HostBound says Replicated asks the broker for a view per
# backend through for_host; nothing in lib calls for_host.)
#
# THE SUBSTITUTIONS: time() is this file's $NOW; the vault is a stub answering
# numbered credentials and counting its reads; the backends are a
# DBIO::Storage::DBI subclass registered for the DBD name 'FakeRepl';
# DBI->connect records its arguments and returns a stand-in handle. No
# database, no vault, no network.

delete @ENV{qw( DBI_DSN DBI_DRIVER DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS )};

{
  package T::StubVault;
  sub new { bless { reads => 0 }, shift }
  sub read_secret {
    my ($self) = @_;
    my $n = ++$self->{reads};
    return { username => "k270-user-$n", password => "k270-pw-$n" };
  }
  sub reads { $_[0]{reads} }
}

{
  package T::BackendStorage;
  use base 'DBIO::Storage::DBI';
  DBIO::Storage::DBI->register_driver(FakeRepl => __PACKAGE__);
}

{
  package T::Handle;
  sub new        { bless { Active => 1, AutoCommit => 1, RaiseError => 1, log => [] }, shift }
  sub FETCH      { $_[0]->{ $_[1] } }
  sub ping       { $_[0]{Active} ? 1 : 0 }
  sub disconnect { push @{ $_[0]{log} }, 'disconnect'; $_[0]{Active} = 0; 1 }
  sub begin_work { push @{ $_[0]{log} }, 'begin_work'; $_[0]{AutoCommit} = 0; 1 }
  sub commit     { push @{ $_[0]{log} }, 'commit';     $_[0]{AutoCommit} = 1; 1 }
  sub rollback   { push @{ $_[0]{log} }, 'rollback';   $_[0]{AutoCommit} = 1; 1 }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

my ($TTL, $MARGIN) = (3600, 900);
my $DUE = $TTL - $MARGIN;   # seconds after a fetch at which the lease is due

my %HOST = (
  master    => 'primary.example',
  replica_1 => 'replica-1.example',
  replica_2 => 'replica-2.example',
);

sub vault_broker {
  my $vault = T::StubVault->new;
  my $broker = DBIO::AccessBroker::Vault->new(
    vault          => $vault,
    dsn            => 'dbi:FakeRepl:dbname=app;host=vault-default.example',
    cred_path      => 'database/creds/app',
    ttl            => $TTL,
    refresh_margin => $MARGIN,
  );
  return ($broker, $vault);
}

# A replicated storage whose master and two replicants are views of $broker.
# Returns it with its backend storages by name and the views by name.
sub replicated_over {
  my ($broker) = @_;
  my %view = (
    master    => $broker->for_host($HOST{master}),
    replica_1 => $broker->for_host($HOST{replica_1}),
    replica_2 => $broker->for_host({ host => $HOST{replica_2}, port => 6432 }),
  );

  my $rstorage = DBIO::Replicated::Storage->new(undef, { backend_storage_class => 'T::BackendStorage' });
  $rstorage->connect_info([ $view{master} ]);
  my @replicants = $rstorage->connect_replicants([ $view{replica_1} ], [ $view{replica_2} ]);

  my %backend = (
    master    => $rstorage->master->storage,
    replica_1 => $replicants[0]->storage,
    replica_2 => $replicants[1]->storage,
  );
  return ($rstorage, \%backend, \%view);
}

my @NAMES = qw( master replica_1 replica_2 );

sub dsn_of {
  my ($name) = @_;
  return "dbi:FakeRepl:dbname=app;host=$HOST{$name}" if $name ne 'replica_2';
  return "dbi:FakeRepl:port=6432;dbname=app;host=$HOST{$name}";
}

sub creds { my ($name, $n) = @_; [ dsn_of($name), "k270-user-$n", "k270-pw-$n" ] }

# What DBI->connect was called with since the last look: [ dsn, user, pw ] each.
sub connects { my @seen = map { [ @$_[0 .. 2] ] } @CONNECTS; @CONNECTS = (); return \@seen }

# see 16-dbi-broker-detached.t: a value matching $re anywhere in the structure,
# broker objects not looked into
sub holds {
  my ($x, $re, $seen) = @_;
  $seen ||= {};
  return 0 unless defined $x;
  return $x =~ $re ? 1 : 0 unless ref $x;
  return 0 if blessed($x) && $x->isa('DBIO::AccessBroker');
  return 0 if $seen->{ refaddr $x }++;
  my $type = reftype $x;
  my @inside = $type eq 'HASH'                      ? %$x
             : $type eq 'ARRAY'                     ? @$x
             : $type eq 'SCALAR' || $type eq 'REF'  ? $$x
             :                                        ();
  return scalar grep { holds($_, $re, $seen) } @inside;
}

# ---------------------------------------------------------------------------
# The clock is this file's.
# ---------------------------------------------------------------------------
{
  my ($broker) = vault_broker();
  is $broker->_expires_at, $NOW + $TTL, "the broker's clock is this test's clock"
    or BAIL_OUT 'time() is not overridden in DBIO::AccessBroker::Vault; nothing below would mean anything';
}

# ---------------------------------------------------------------------------
# 1 - 4. One lease, three servers.
# ---------------------------------------------------------------------------
{
  my $start = $NOW;
  local @CONNECTS;
  my ($broker, $vault) = vault_broker();
  my ($rstorage, $backend, $view) = replicated_over($broker);

  is_deeply [ map { refaddr $backend->{$_}->access_broker } @NAMES ], [ map { refaddr $view->{$_} } @NAMES ],
    'each backend keeps the view it was given as its broker';
  is_deeply [ map { refaddr $backend->{$_}->access_broker->underlying_broker } @NAMES ], [ (refaddr $broker) x 3 ],
    '... each a view of the one broker';
  is scalar keys %{ $rstorage->replicants }, 2, '... and the pool holds the two replicants';
  is $vault->reads, 1, 'setting them up reads the vault no more than building the broker did';
  is_deeply connects(), [], '... and opens no connection';

  $backend->{$_}->dbh for @NAMES;
  is_deeply connects(), [ map { creds($_, 1) } @NAMES ],
    'each backend opens its connection on the host of its view, with the credentials of the one lease';
  is $vault->reads, 1, '... without a read of the vault';
  is $rstorage->dbh, $backend->{master}->_dbh, "the replicated storage's dbh is the master's handle";
  is_deeply connects(), [], '... no further connection';

  # the lease due: every backend reconnects
  local $NOW = $start + $DUE + 1;
  my $rotated_at = $NOW;
  $rstorage->disconnect;
  is_deeply [ map { $backend->{$_}->_dbh } @NAMES ], [ undef, undef, undef ],
    'disconnect on the replicated storage closes every backend';

  # the replicants come out of the pool in no particular order
  $rstorage->ensure_connected;
  is_deeply [ sort { $a->[0] cmp $b->[0] } @{ connects() } ],
    [ sort { $a->[0] cmp $b->[0] } map { creds($_, 2) } @NAMES ],
    'the lease due: every backend reconnects on its own host with the new credentials';
  is $vault->reads, 2, '... after ONE read of the vault for all of them';
  ok !holds([ map { $backend->{$_} } @NAMES ], qr/k270-pw-1/), '... and no backend keeps the rotated-out password';
  ok holds([ creds(master => 1) ], qr/k270-pw-1/), '... (the scanner finds one where there is one)';

  $backend->{replica_1}->disconnect;
  $backend->{replica_1}->dbh;
  is_deeply connects(), [ creds(replica_1 => 2) ], 'a replicant reconnecting inside the new lease uses its credentials';
  is $vault->reads, 2, '... without a read';

  # the next lease due: a replicant alone reconnects
  $NOW = $rotated_at + $DUE + 1;
  $backend->{replica_2}->disconnect;
  $backend->{replica_2}->dbh;
  is_deeply connects(), [ creds(replica_2 => 3) ], 'the next lease due and one replicant reconnecting: it rotates';
  is $vault->reads, 3, '... with one read';

  ok $backend->{master}->connected, 'the master, still connected, is not touched by that';
  is_deeply connects(), [], '... no connection is opened for it';

  $backend->{master}->disconnect;
  $rstorage->dbh;
  is_deeply connects(), [ creds(master => 3) ],
    "the master's next connection uses the credentials the replicant's rotation fetched";
  is $vault->reads, 3, '... without another read';
}

# ---------------------------------------------------------------------------
# 5. A transaction through the replicated storage.
# ---------------------------------------------------------------------------
{
  local @CONNECTS;
  my ($broker, $vault) = vault_broker();
  my ($rstorage, $backend) = replicated_over($broker);
  my $master_dbh = $rstorage->dbh;
  connects();

  my $REFUSED = qr/Refusing to start a transaction with unsafe AccessBroker DBIO::AccessBroker::HostBound: credential rotation/;

  throws_ok { $rstorage->txn_begin } $REFUSED,
    'txn_begin through the replicated storage is refused: the master\'s view is of a rotating broker';
  unlike "$@", qr/k270-/, '... quoting no credential';
  throws_ok { $rstorage->txn_do(sub { 1 }) } $REFUSED, '... and so is txn_do';
  throws_ok { $backend->{master}->txn_begin } $REFUSED, '... and txn_begin on the master backend itself';
  is_deeply $master_dbh->{log}, [], "... nothing reached the master's handle";
  is $rstorage->transaction_depth, 0, '... and no transaction is counted';

  {
    local $ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS} = 1;
    my @warnings;
    local $SIG{__WARN__} = sub { push @warnings, "@_" };

    lives_ok { $rstorage->txn_begin } 'with DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS, txn_begin goes through';
    is scalar(grep { /Starting a transaction with unsafe AccessBroker DBIO::AccessBroker::HostBound via override: credential rotation/ } @warnings), 1,
      '... with one warning naming the broker and why';
    is_deeply $master_dbh->{log}, [ 'begin_work' ], "... and begins on the master's handle";
    $rstorage->txn_rollback if $rstorage->transaction_depth;
    is_deeply $master_dbh->{log}, [ 'begin_work', 'rollback' ], '... which the rollback ends';
  }
  is_deeply connects(), [], 'none of it opened a connection';
}

# ---------------------------------------------------------------------------
# 6. The same topology over a broker that does not rotate.
# ---------------------------------------------------------------------------
{
  local @CONNECTS;
  my $broker = DBIO::AccessBroker::Static->new(
    dbname => 'app', host => 'static-default.example', username => 'k270-static', password => 'k270-static-pw',
  );
  my ($rstorage, $backend) = replicated_over($broker);

  $backend->{$_}->dbh for @NAMES;
  is_deeply connects(), [
    [ "dbi:FakeRepl:dbname=app;host=$HOST{master}",              'k270-static', 'k270-static-pw' ],
    [ "dbi:FakeRepl:dbname=app;host=$HOST{replica_1}",           'k270-static', 'k270-static-pw' ],
    [ "dbi:FakeRepl:dbname=app;host=$HOST{replica_2};port=6432", 'k270-static', 'k270-static-pw' ],
  ], 'views of a Static broker: each backend builds its own DSN from the parameters, on the host of its view';

  my $master_dbh = $backend->{master}->_dbh;
  lives_ok { $rstorage->txn_begin } 'txn_begin through the replicated storage is allowed: the broker does not rotate';
  is_deeply $master_dbh->{log}, [ 'begin_work' ], "... and begins on the master's handle";
  is_deeply [ map { $backend->{$_}->_dbh->{log} } qw( replica_1 replica_2 ) ], [ [], [] ],
    '... on no replicant';
  $rstorage->txn_rollback if $rstorage->transaction_depth;
}

# Only the master's broker gates a transaction (CONTEXT.md): a rotating broker
# behind a replicant does not.
{
  local @CONNECTS;
  my ($rotating) = vault_broker();
  my $static = DBIO::AccessBroker::Static->new(
    dbname => 'app', username => 'k270-static', password => 'k270-static-pw',
  );
  my $rstorage = DBIO::Replicated::Storage->new(undef, { backend_storage_class => 'T::BackendStorage' });
  $rstorage->connect_info([ $static->for_host($HOST{master}) ]);
  my ($replicant) = $rstorage->connect_replicants([ $rotating->for_host($HOST{replica_1}) ]);

  ok !$replicant->storage->access_broker->is_transaction_safe,
    'a master on a broker that does not rotate, a replicant on one that does';
  lives_ok { $rstorage->txn_begin } "... txn_begin is allowed: the replicant's broker does not gate it";
  is_deeply $rstorage->master->storage->_dbh->{log}, [ 'begin_work' ], "... and begins on the master's handle";
  $rstorage->txn_rollback if $rstorage->transaction_depth;
}

# ---------------------------------------------------------------------------
# As it is: Replicated binds no host itself.
# ---------------------------------------------------------------------------
{
  local @CONNECTS;
  my ($broker) = vault_broker();
  my $rstorage = DBIO::Replicated::Storage->new(undef, { backend_storage_class => 'T::BackendStorage' });
  $rstorage->connect_info([ $broker->for_host($HOST{master}) ]);
  my ($replicant) = $rstorage->connect_replicants([ $broker ]);

  is refaddr($replicant->storage->access_broker), refaddr($broker),
    'as it is today: a replicant given the broker itself keeps it, with no view made for it';
  $replicant->storage->dbh;
  is_deeply connects(), [ [ 'dbi:FakeRepl:dbname=app;host=vault-default.example', 'k270-user-1', 'k270-pw-1' ] ],
    "as it is today: ... and connects where the broker's own answer says";
}

done_testing;
