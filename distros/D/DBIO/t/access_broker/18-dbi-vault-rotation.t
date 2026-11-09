# ABSTRACT: A sync storage rotates its credentials through a Vault broker when the lease is due
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
use DBIO::AccessBroker::Vault;

# OFFLINE (karr k270). Rotation is what an AccessBroker is for: a storage asks
# its broker for every new connection, and a broker whose lease is due fetches
# new credentials before it answers (DBIO::AccessBroker's
# current_connect_info_for_storage: needs_refresh, refresh, answer). Core had
# no test that ran this through a storage: 02-vault.t rotates by calling
# refresh by hand, 05-dbi-reconnect.t uses a broker without a lease. The path
# ran only in driver dists, in files that skip without dbio-async.
#
# What this file claims, with a real DBIO::AccessBroker::Vault attached to a
# real DBIO::Storage::DBI:
#   1. inside the lease, connect_info and every connection use the credentials
#      fetched at construction, and the vault is not read again;
#   2. the lease is due once the clock is past ttl - refresh_margin, not
#      before: the second before and the very second do not read the vault,
#      the second after does;
#   3. a connection opened with the lease due reads the vault exactly once and
#      goes to DBI->connect with the new user and password; the connections
#      after it use them without another read, until that lease is due too;
#   4. the rotated-out password reaches no DBI->connect after the rotation and
#      is not kept in the storage;
#   5. the same through a HostBound view: the lease is the wrapped broker's,
#      the host is the view's;
#   6. connect_info itself rotates when the lease is already due.
#
# THE SUBSTITUTIONS: time() is this file's $NOW; the vault is a stub answering
# numbered credentials and counting its reads; DBI->connect records its
# arguments and returns a stand-in handle. No database, no vault, no network.

delete @ENV{qw( DBI_DSN DBI_DRIVER )};

# Answers the credentials of read 1, 2, 3, ... and records the paths read.
{
  package T::StubVault;
  sub new { bless { reads => [] }, shift }
  sub read_secret {
    my ($self, $path) = @_;
    push @{ $self->{reads} }, $path;
    my $n = @{ $self->{reads} };
    return { username => "k270-user-$n", password => "k270-pw-$n" };
  }
  sub reads { scalar @{ $_[0]{reads} } }
}

{
  package T::Handle;
  sub new   { bless { Active => 1, AutoCommit => 1, RaiseError => 1 }, shift }
  sub FETCH { $_[0]->{ $_[1] } }
}

our @CONNECTS;
{
  no warnings 'redefine';
  *DBI::connect = sub { shift; push @CONNECTS, [ @_ ]; T::Handle->new };
}

my ($TTL, $MARGIN) = (3600, 900);
my $DUE = $TTL - $MARGIN;   # seconds after a fetch at which the lease is due
my $DSN = 'dbi:Fake:dbname=app;host=db.example';

sub vault_broker {
  my $vault = T::StubVault->new;
  my $broker = DBIO::AccessBroker::Vault->new(
    vault          => $vault,
    dsn            => $DSN,
    cred_path      => 'database/creds/app',
    ttl            => $TTL,
    refresh_margin => $MARGIN,
    dbi_attrs      => { PrintWarn => 0 },
  );
  return ($broker, $vault);
}

# one connection; the [ $dsn, $user, $password ] DBI->connect got
sub connect_once {
  my $storage = shift;
  local @CONNECTS;
  $storage->_connect;
  die 'expected exactly one DBI->connect, got ' . @CONNECTS unless @CONNECTS == 1;
  return [ @{ $CONNECTS[0] }[0 .. 2] ];
}

sub creds { my $n = shift; [ $DSN, "k270-user-$n", "k270-pw-$n" ] }

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
# 1 - 4. Inside the lease, at its edge, and past it.
# ---------------------------------------------------------------------------
{
  my $start = $NOW;
  my ($broker, $vault) = vault_broker();
  is $vault->reads, 1, 'the broker reads the vault once when it is built';

  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ $broker ]);
  is $vault->reads, 1, 'inside the lease, connect_info does not read the vault';

  is_deeply connect_once($storage), creds(1), '... a connection uses the credentials of the first read';
  is_deeply connect_once($storage), creds(1), '... and so does the next';
  is $vault->reads, 1, '... without another read';

  local $NOW = $start + $DUE - 1;
  is_deeply connect_once($storage), creds(1), 'one second before the lease is due: the same credentials';
  is $vault->reads, 1, '... and no read';

  $NOW = $start + $DUE;
  is_deeply connect_once($storage), creds(1), 'in the very second the margin begins: the same credentials';
  is $vault->reads, 1, '... and no read';

  $NOW = $start + $DUE + 1;
  my $rotated_at = $NOW;
  is_deeply connect_once($storage), creds(2),
    'the lease due: the connection goes to DBI->connect with the new user and password';
  is $vault->reads, 2, '... after exactly one read of the vault';
  is_deeply $vault->{reads}, [ ('database/creds/app') x 2 ], '... of the credential path';
  is $broker->_expires_at, $rotated_at + $TTL, '... and the new lease runs from the rotation';

  ok !holds($storage, qr/k270-pw-1/), 'the rotated-out password is not kept in the storage';
  ok holds([ creds(1) ], qr/k270-pw-1/), '... (the scanner finds one where there is one)';

  {
    local @CONNECTS;
    $storage->_connect for 1 .. 3;
    is_deeply [ map { [ @$_[0 .. 2] ] } @CONNECTS ], [ (creds(2)) x 3 ],
      'the connections after the rotation use the new credentials';
    is $vault->reads, 2, '... without another read';
    is_deeply [ map { $_->[3]{PrintWarn} } @CONNECTS ], [ 0, 0, 0 ],
      "... each with the broker's dbi_attrs";
  }

  $NOW = $rotated_at + $DUE;
  is_deeply connect_once($storage), creds(2), 'the new lease is not due before its own margin';
  is $vault->reads, 2, '... no read';

  $NOW = $rotated_at + $DUE + 1;
  is_deeply connect_once($storage), creds(3), 'the new lease due: rotated again';
  is $vault->reads, 3, '... after exactly one more read';

  $NOW = $rotated_at + 10 * $TTL;
  is_deeply connect_once($storage), creds(4), 'long past the lease: one rotation';
  is $vault->reads, 4, '... one read, however long the lease has been over';
}

# ---------------------------------------------------------------------------
# 5. Through a HostBound view.
# ---------------------------------------------------------------------------
{
  my $start = $NOW;
  my ($broker, $vault) = vault_broker();
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ $broker->for_host({ host => 'replica.example', port => 6432 }) ]);

  my $view_dsn = 'dbi:Fake:port=6432;dbname=app;host=replica.example';
  is_deeply connect_once($storage), [ $view_dsn, 'k270-user-1', 'k270-pw-1' ],
    "through a HostBound view, inside the lease: the first credentials, on the view's host";
  is $vault->reads, 1, '... and no read';

  local $NOW = $start + $DUE + 1;
  is_deeply connect_once($storage), [ $view_dsn, 'k270-user-2', 'k270-pw-2' ],
    "through a HostBound view, the lease due: the new credentials, on the view's host";
  is $vault->reads, 2, '... after exactly one read';
  is_deeply connect_once($storage), [ $view_dsn, 'k270-user-2', 'k270-pw-2' ],
    '... and the next connection uses them';
  is $vault->reads, 2, '... without another read';
}

# ---------------------------------------------------------------------------
# 6. The lease is due when the storage is configured.
# ---------------------------------------------------------------------------
{
  my $start = $NOW;
  my ($broker, $vault) = vault_broker();
  local $NOW = $start + $DUE + 1;

  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ $broker ]);
  is $vault->reads, 2, 'connect_info with the lease due reads the vault once';
  is_deeply connect_once($storage), creds(2), '... and the first connection uses the new credentials';
  is $vault->reads, 2, '... without another read';
  ok !holds($storage, qr/k270-pw-1/), '... the rotated-out password is not in the storage';
}

done_testing;
