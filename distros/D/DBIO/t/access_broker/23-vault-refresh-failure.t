# ABSTRACT: A Vault broker whose vault fails at refresh, or answers no credentials
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
use DBIO::Storage::Async;
use DBIO::Storage::PoolBase;
use DBIO::AccessBroker::Vault;
use DBIO::Test::Future ();

# OFFLINE (karr k270). 02-vault.t covers a vault that fails, or answers
# nothing, when the broker is BUILT. 18-dbi-vault-rotation.t covers the
# rotation that works. Nothing covered the two in between:
#
#   - a vault that answered at construction and fails when the lease is due;
#   - a vault that answers something that holds no credentials. The broker's
#     guard was "unless $creds": an empty hash is true, so it passed, the
#     broker answered [ $dsn, undef, undef, ... ], and that went to
#     DBI->connect -- which fills an undef user and password from DBI_USER and
#     DBI_PASS. A plain string died in a hash dereference whose message QUOTED
#     THE STRING, which from a vault is as likely as not the secret.
#
# What this file claims:
#   1. A failed refresh: the vault's own error reaches whoever asked the
#      broker, on every ask -- each ask reads the vault again, none is answered
#      from the credentials of before.
#   2. A storage asking for a connection then gets that error and opens none:
#      DBI->connect is not called, not with the old credentials and not at
#      all. The same at connect_info, through a HostBound view, and for a pool
#      connection of an async backend. Detached from the broker afterwards,
#      the sync storage connects from nothing of it.
#   3. Once the vault answers again, the next connection uses the new
#      credentials.
#   4. IST, not a claim: the broker object keeps the credentials of the last
#      good read while the refresh fails -- connect_info_for, which does not
#      refresh, still answers them -- and the lease is not renewed. Whether it
#      should forget them is a decision; no storage reads them (claim 2).
#   5. A secret that holds no credentials -- an empty hash, a hash with
#      neither a username nor a password (the vault's response envelope with
#      the credentials one level down, say), or no hash at all -- croaks,
#      naming cred_path and, for no hash, its shape; never a value. At
#      construction and at refresh; at refresh the credentials of before are
#      left whole, not half replaced, and no connection is opened.
#   6. Secrets that are credentials are taken (control): extra keys beside the
#      two, a hash-based object, an empty password.
#
# THE SUBSTITUTIONS: time() is this file's $NOW; the vault is a stub answering
# from a script and counting its reads; DBI->connect records its arguments and
# returns a stand-in handle; the async pool records the conninfo of each
# connection instead of opening it. No database, no vault, no network.

delete @ENV{qw( DBI_DSN DBI_DRIVER DBI_USER DBI_PASS )};

# One code per read, the last one repeating; each is called with the number of
# the read.
{
  package T::StubVault;
  sub new { my ($class, @script) = @_; bless { script => \@script, reads => 0, paths => [] }, $class }
  sub read_secret {
    my ($self, $path) = @_;
    push @{ $self->{paths} }, $path;
    my $i = $self->{reads}++;
    $i = $#{ $self->{script} } if $i > $#{ $self->{script} };
    return $self->{script}[$i]->($self->{reads});
  }
  sub reads { $_[0]{reads} }
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

{
  package T::RecordingPool;
  use base 'DBIO::Storage::PoolBase';
  our @BUILT;
  sub _create_connection { my ($self, $conninfo) = @_; push @BUILT, $conninfo; bless { conninfo => $conninfo }, 'T::Conn' }
  sub _transform_conninfo { $_[1] }
}

# An async transport taking the DBI form: each pool connection is built from
# the [ $dsn, $user, $password ] of the broker's answer at that moment.
{
  package T::Backend;
  use base 'DBIO::Storage::Async';
  sub future_class { 'DBIO::Test::Future' }
  sub disconnect   { delete $_[0]{pool}; 1 }
  sub _async_broker_conninfo {
    my ($self, $mode) = @_;
    my $answer = $self->_current_async_connect_info($mode);
    return [ @{$answer}[0 .. 2] ];
  }
  sub pool {
    my $self = shift;
    $self->{pool} ||= T::RecordingPool->new(
      size              => 5,
      future_class      => $self->future_class,
      conninfo_provider => $self->_conninfo_provider,
    );
  }
}

my ($TTL, $MARGIN) = (3600, 900);
my $DUE  = $TTL - $MARGIN;   # seconds after a fetch at which the lease is due
my $DSN  = 'dbi:Fake:dbname=app;host=db.example';
my $PATH = 'database/creds/app';

my $SECRET = qr/k270-(?:user|pw)/;   # every credential in this file

sub good  { my $n = shift; return { username => "k270-user-$n", password => "k270-pw-$n" } }
sub creds { my $n = shift; return [ $DSN, "k270-user-$n", "k270-pw-$n" ] }
sub down  { die "k270 vault sealed\n" }
my $DOWN = qr/^k270 vault sealed/;

sub vault_broker {
  my $vault = T::StubVault->new(@_);
  my $broker = DBIO::AccessBroker::Vault->new(
    vault          => $vault,
    dsn            => $DSN,
    cred_path      => $PATH,
    ttl            => $TTL,
    refresh_margin => $MARGIN,
  );
  return ($broker, $vault);
}

# every DBI->connect $code makes, as [ $dsn, $user, $password ]
sub connects_of (&) {
  my $code = shift;
  local @CONNECTS;
  $code->();
  return [ map { [ @$_[0 .. 2] ] } @CONNECTS ];
}

# the conninfo of every pool connection $code builds
sub built_by (&) {
  my $code = shift;
  local @T::RecordingPool::BUILT;
  $code->();
  return [ @T::RecordingPool::BUILT ];
}

sub failure_of { my ($f) = @_; return $f->is_failed ? "$f->{values}[0]" : '' }

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
  my ($broker) = vault_broker(\&good);
  is $broker->_expires_at, $NOW + $TTL, "the broker's clock is this test's clock"
    or BAIL_OUT 'time() is not overridden in DBIO::AccessBroker::Vault; nothing below would mean anything';
}

# ---------------------------------------------------------------------------
# 1, 3, 4. The broker: a refresh that fails.
# ---------------------------------------------------------------------------
{
  my $start = $NOW;
  my ($broker, $vault) = vault_broker(\&good, \&down, \&down, \&down, \&good);
  is $vault->reads, 1, 'the broker reads the vault once when it is built';

  local $NOW = $start + $DUE + 1;
  ok $broker->needs_refresh, 'the lease is due';

  throws_ok { $broker->current_connect_info_for_storage(undef) } $DOWN,
    "the vault fails at refresh: asking the broker throws the vault's error";
  is $vault->reads, 2, '... after one read';
  unlike "$@", $SECRET, '... which names no credential';

  # 4. IST
  is_deeply [ @{ $broker->connect_info_for }[0 .. 2] ], creds(1),
    'IST the broker keeps the credentials of the last good read (connect_info_for does not refresh)';
  is $broker->_expires_at, $start + $TTL, 'IST ... and the lease is not renewed by the failed read';
  ok $broker->needs_refresh, '... so it is still due';

  throws_ok { $broker->current_connect_info_for_storage(undef) } $DOWN,
    'asked again: the same error, not the credentials of before';
  is $vault->reads, 3, '... after another read: every ask goes to the vault';
  throws_ok { $broker->current_connect_info_for } $DOWN,
    '... and current_connect_info_for refreshes the same way';
  is $vault->reads, 4, '... with a read of its own';

  # 3. The fifth read answers.
  my $rotated_at = $NOW;
  is_deeply [ @{ $broker->current_connect_info_for_storage(undef) }[0 .. 2] ], creds(5),
    'the vault answers again: the broker answers the new credentials';
  is $broker->_expires_at, $rotated_at + $TTL, '... the lease runs from that read';
  ok !$broker->needs_refresh, '... and is no longer due';
  is_deeply $vault->{paths}, [ ($PATH) x 5 ], 'every read was of the credential path';
}

# ---------------------------------------------------------------------------
# 2, 3. A sync storage.
# ---------------------------------------------------------------------------
for my $via (qw( direct view )) {
  my $t = $via eq 'view' ? 'through a HostBound view, ' : '';
  my $start = $NOW;
  my ($broker, $vault) = vault_broker(\&good, \&down, \&down, sub { good(4) });
  my $attached = $via eq 'view' ? $broker->for_host({ host => 'replica.example', port => 6432 }) : $broker;
  my $dsn = $via eq 'view' ? 'dbi:Fake:port=6432;dbname=app;host=replica.example' : $DSN;

  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ $attached ]);
  is_deeply connects_of { $storage->_connect }, [ [ $dsn, 'k270-user-1', 'k270-pw-1' ] ],
    "${t}inside the lease: a connection with the first credentials";

  local $NOW = $start + $DUE + 1;
  my $opened = connects_of {
    throws_ok { $storage->_connect } $DOWN, "${t}the vault fails at refresh: the connection throws the vault's error";
  };
  is_deeply $opened, [], "${t}... and DBI->connect is not called -- not with the old credentials, not at all";
  is $vault->reads, 2, "${t}... the vault was read once";

  $opened = connects_of {
    throws_ok { $storage->_connect } $DOWN, "${t}the next connection throws it again";
  };
  is_deeply $opened, [], "${t}... DBI->connect is not called";
  is $vault->reads, 3, "${t}... the vault was read again";

  is_deeply connects_of { $storage->_connect }, [ [ $dsn, 'k270-user-4', 'k270-pw-4' ] ],
    "${t}the vault answers again: the connection uses the new credentials";
  ok !holds($storage, qr/k270-pw-1/), "${t}... and the storage keeps nothing of the old ones";
}

# connect_info itself, with the lease already due
{
  my $start = $NOW;
  my ($broker, $vault) = vault_broker(\&good, \&down);
  local $NOW = $start + $DUE + 1;

  my $storage = DBIO::Storage::DBI->new(undef);
  my $opened = connects_of {
    throws_ok { $storage->connect_info([ $broker ]) } $DOWN,
      "connect_info with the lease due and the vault failing: throws the vault's error";
    throws_ok { $storage->_connect } $DOWN, '... and so does a connection after it';
  };
  is_deeply $opened, [], '... DBI->connect is not called';
  ok !holds($storage, $SECRET), '... and the storage holds no credential';
}

# detached after the failure
{
  my $start = $NOW;
  my ($broker, $vault) = vault_broker(\&good, \&down);
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ $broker ]);
  connects_of { $storage->_connect };

  local $NOW = $start + $DUE + 1;
  dies_ok { $storage->_connect } 'the vault fails at refresh';
  $storage->clear_access_broker;
  my $opened = connects_of {
    throws_ok { $storage->_connect } qr/You did not provide any connection_info/,
      '... the broker detached afterwards: a connection has nothing to be opened from';
  };
  is_deeply $opened, [], '... DBI->connect is not called with the credentials of before';
  ok !holds($storage, $SECRET), '... which are gone from the storage';
}

# ---------------------------------------------------------------------------
# 2, 3. An async backend.
# ---------------------------------------------------------------------------
{
  my $start = $NOW;
  my ($broker, $vault) = vault_broker(\&good, \&down, \&down, sub { good(4) });
  my $backend = T::Backend->new(undef);
  $backend->connect_info([ $broker ]);

  is_deeply built_by { $backend->pool->acquire }, [ creds(1) ],
    'async, inside the lease: a pool connection with the first credentials';

  local $NOW = $start + $DUE + 1;
  for my $attempt (1, 2) {
    my $f;
    my $built = built_by { $f = $backend->pool->acquire };
    like failure_of($f), $DOWN, "async, the vault fails at refresh (attempt $attempt): acquire fails with the vault's error";
    is_deeply $built, [], '... and no connection is built, not from the old credentials';
  }
  is $vault->reads, 3, '... the vault was read for each attempt';

  is_deeply built_by { $backend->pool->acquire }, [ creds(4) ],
    'async, the vault answers again: the pool connection uses the new credentials';
}

# ---------------------------------------------------------------------------
# 5. A secret that holds no credentials.
# ---------------------------------------------------------------------------
my $NONE = qr{^Vault returned no credentials for \Q$PATH\E};

# label => [ the secret, the error ]
my %NO_CREDENTIALS = (
  'undef' =>
    [ sub { undef }, $NONE ],
  'an empty hash' =>
    [ sub { {} }, $NONE ],
  'a hash with neither a username nor a password' =>
    [ sub { { lease_id => 'database/creds/app/abc', renewable => 1 } }, $NONE ],
  "the vault's response envelope, the credentials one level down" =>
    [ sub { { lease_duration => 3600, data => { username => 'k270-user-9', password => 'k270-pw-9' } } }, $NONE ],
  'a hash with both undef' =>
    [ sub { { username => undef, password => undef } }, $NONE ],
  'a plain scalar' =>
    [ sub { 'k270-pw-9' }, qr{^Vault returned credentials for \Q$PATH\E that are not a hash \(a plain scalar\)} ],
  'an ARRAY reference' =>
    [ sub { [ 'k270-user-9', 'k270-pw-9' ] }, qr{^Vault returned credentials for \Q$PATH\E that are not a hash \(an ARRAY reference\)} ],
  'a CODE reference' =>
    [ sub { sub { 'k270-pw-9' } }, qr{^Vault returned credentials for \Q$PATH\E that are not a hash \(a CODE reference\)} ],
  'an object that is no hash' =>
    [ sub { bless [ 'k270-user-9', 'k270-pw-9' ], 'T::Secret' }, qr{^Vault returned credentials for \Q$PATH\E that are not a hash \(an object of class T::Secret\)} ],
);

for my $label (sort keys %NO_CREDENTIALS) {
  my ($secret, $error) = @{ $NO_CREDENTIALS{$label} };

  # at construction
  throws_ok { vault_broker($secret) } $error, "$label at construction: croaks, naming the credential path";
  unlike "$@", $SECRET, "$label at construction: naming no value";

  # at refresh
  my $start = $NOW;
  my ($broker, $vault) = vault_broker(\&good, $secret);
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ $broker ]);

  local $NOW = $start + $DUE + 1;
  my $opened = connects_of {
    throws_ok { $storage->_connect } $error, "$label at refresh: the connection croaks, naming the credential path";
  };
  unlike "$@", $SECRET, "$label at refresh: naming no value";
  is_deeply $opened, [], "$label at refresh: DBI->connect is not called";
  is $vault->reads, 2, "$label at refresh: the vault was read once";
  is_deeply [ @{ $broker->connect_info_for }[0 .. 2] ], creds(1),
    "$label at refresh: the credentials of before are left whole";
  is $broker->_expires_at, $start + $TTL, "$label at refresh: and the lease is not renewed";
}

# ---------------------------------------------------------------------------
# 6. Secrets that are credentials (control).
# ---------------------------------------------------------------------------
my %CREDENTIALS = (
  'a username and a password' =>
    [ sub { { username => 'k270-user-9', password => 'k270-pw-9' } }, [ 'k270-user-9', 'k270-pw-9' ] ],
  'extra keys beside the two' =>
    [ sub { { username => 'k270-user-9', password => 'k270-pw-9', lease_duration => 3600 } }, [ 'k270-user-9', 'k270-pw-9' ] ],
  'a hash-based object' =>
    [ sub { bless { username => 'k270-user-9', password => 'k270-pw-9' }, 'T::SecretHash' }, [ 'k270-user-9', 'k270-pw-9' ] ],
  'an empty password' =>
    [ sub { { username => 'k270-user-9', password => '' } }, [ 'k270-user-9', '' ] ],
);

for my $label (sort keys %CREDENTIALS) {
  my ($secret, $pair) = @{ $CREDENTIALS{$label} };
  my ($broker) = eval { vault_broker($secret) };
  ok $broker, "$label: taken" or diag $@;
  next unless $broker;
  my $storage = DBIO::Storage::DBI->new(undef);
  $storage->connect_info([ $broker ]);
  is_deeply connects_of { $storage->_connect }, [ [ $DSN, @$pair ] ], "$label: ... and connected with as given";
}

# ---------------------------------------------------------------------------
# 7. Exactly one of the two: refused (karr k272). A secret must hold BOTH
#    username and password, defined; an empty string is a value. The missing
#    key is named, never a value.
# ---------------------------------------------------------------------------
my %HALF = (
  'a username without a password' =>
    [ sub { { username => 'k270-user-9' } }, 'password' ],
  'a password without a username' =>
    [ sub { { password => 'k270-pw-9' } }, 'username' ],
  'a username with an undef password' =>
    [ sub { { username => 'k270-user-9', password => undef } }, 'password' ],
  'a password with an undef username' =>
    [ sub { { username => undef, password => 'k270-pw-9' } }, 'username' ],
);

for my $label (sort keys %HALF) {
  my ($secret, $missing) = @{ $HALF{$label} };

  # at construction
  {
    my ($broker) = eval { vault_broker($secret) };
    my $error = "$@";

    ok !$broker, "$label at construction: refused";
    like $error, qr{^Vault returned .* \Q$PATH\E}, "$label at construction: the error names the credential path";
    like $error, qr{\b\Q$missing\E\b}, "$label at construction: the error names the missing key ($missing)";
    unlike $error, $SECRET, "$label at construction: no value is named";
  }

  # at refresh
  {
    my $start = $NOW;
    my ($broker, $vault) = vault_broker(\&good, $secret);
    my $storage = DBIO::Storage::DBI->new(undef);
    $storage->connect_info([ $broker ]);

    local $NOW = $start + $DUE + 1;
    my $refused;
    my $opened = connects_of { $refused = !eval { $storage->_connect; 1 } };
    my $error = "$@";

    ok $refused, "$label at refresh: refused";
    like $error, qr{\b\Q$missing\E\b}, "$label at refresh: the error names the missing key ($missing)";
    unlike $error, $SECRET, "$label at refresh: no value is named";
    is_deeply $opened, [], "$label at refresh: no connection is opened with half a credential";
    is_deeply [ @{ $broker->connect_info_for }[0 .. 2] ], creds(1),
      "$label at refresh: the credentials of before are left whole";
  }
}

done_testing;
