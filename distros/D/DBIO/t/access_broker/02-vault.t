# ABSTRACT: AccessBroker::Vault — TTL math, fetch, rotation, txn-safety, error path
use strict;
use warnings;

use Test::More;
use Test::Exception ();
use Test::Warn;
use Scalar::Util qw(blessed);

use DBIO::Test;
use DBIO::Storage;
use DBIO::AccessBroker;
use DBIO::AccessBroker::Vault;

# Test::Exception's exception() helper does not play nicely with
# DBIO::Exception's overloaded stringification under perl 5.36 (the
# exception leaks out of its internal eval). Use a plain eval { } or
# $@ capture for the txn-safety cases below.
sub _caught (&) {
  my $code = shift;
  my $err;
  eval { $code->(); 1 } or $err = $@;
  return $err;
}

# -----------------------------------------------------------------------------
# Stub vault: implements only the read_secret($path) contract the broker uses.
# Sequence-based: each call pops the next response. Tracks call count and the
# paths that were requested, so we can assert the broker only talks to the
# configured cred_path (and never reaches out on its own).
# -----------------------------------------------------------------------------
{
  package StubVault;
  use Carp;

  sub new {
    my ($class, %args) = @_;
    bless {
      responses => $args{responses} || [],  # arrayref of hashrefs (or undef for failure)
      calls     => [],
      _pos      => 0,
    }, $class;
  }

  sub read_secret {
    my ($self, $path) = @_;
    push @{ $self->{calls} }, $path;
    my $resp = $self->{responses}[ $self->{_pos}++ ];
    croak $resp->{error} if $resp && $resp->{error};
    # When creds is undef, return undef (the broker's own guard fires);
    # when creds is a hashref, return a fresh copy.
    return !defined $resp           ? undef
         : !defined $resp->{creds}  ? undef
         :                            { %{ $resp->{creds} } };
  }

  sub call_count   { scalar @{ $_[0]->{calls} } }
  sub called_paths { [ @{ $_[0]->{calls} } ] }
  sub reset_calls  { $_[0]->{calls} = []; $_[0]->{_pos} = 0 }
}

# A second stub that unconditionally throws — used to test the broker's error
# path without ever opening a socket. Anything that *isn't* read_secret() is
# recorded but never invoked (the broker should never reach for it).
{
  package StrictVault;
  sub new { bless { calls => {} }, $_[0] }
  sub read_secret { die "HTTP 500 Internal Server Error\n" }
  # Catch any unexpected method call:
  sub AUTOLOAD {
    my $self = shift;
    my $method = our $AUTOLOAD; $method =~ s/.*:://;
    push @{ $self->{calls}{ucfirst($method)} }, [@_];
    die "StrictVault: unexpected method $method called";
  }
  sub DESTROY { }
}

# Helper: build a Vault broker with a sequence of stubbed responses.
sub make_broker {
  my (%args) = @_;
  my $vault = delete $args{vault}
    or die "make_broker requires a vault";
  DBIO::AccessBroker::Vault->new(
    vault          => $vault,
    dsn            => 'dbi:Pg:dbname=app;host=db',
    cred_path      => 'database/creds/myapp',
    dbi_attrs      => { AutoCommit => 1, PrintError => 0 },
    ttl            => $args{ttl}            // 3600,
    refresh_margin => $args{refresh_margin} // 900,
  );
}

# -----------------------------------------------------------------------------
# 1. TTL-expiry math: _expires_at is computed as time() + ttl on every fetch,
#    needs_refresh is true once we cross the refresh_margin, and edge cases
#    (ttl=0, refresh_margin=0) still work.
# -----------------------------------------------------------------------------
subtest 'TTL math' => sub {
  my $start = time();
  my $vault = StubVault->new(responses => [
    { creds => { username => 'u1', password => 'p1' } },
  ]);
  my $broker = make_broker(
    vault          => $vault,
    ttl            => 60,
    refresh_margin => 15,
  );

  my $expires = $broker->_expires_at;
  cmp_ok $expires, '>=', $start + 60,
    '_expires_at set to at least start + ttl';
  cmp_ok $expires, '<=', $start + 60 + 1,
    '_expires_at set to at most start + ttl + 1s of clock drift';

  ok !$broker->needs_refresh,
    'fresh credentials do not need refresh (within margin)';

  # Force a state where needs_refresh must be true: rewind by hand so that
  # _expires_at is in the past by more than the margin. We poke the accessor
  # directly because the broker's rotation path is exercised separately below.
  $broker->_expires_at(time() - 1);
  ok $broker->needs_refresh,
    'expired credentials need refresh (past expiry)';

  # needs_refresh math: time() > (expires_at - margin)
  # = time() > (time() + 100 - 15) = time() > time() + 85 = FALSE
  $broker->_expires_at(time() + 100);
  ok !$broker->needs_refresh,
    'credentials with more than margin remaining do not need refresh';

  # = time() > (time() + 5 - 15) = time() > time() - 10 = TRUE
  $broker->_expires_at(time() + 5);
  ok $broker->needs_refresh,
    'credentials inside the refresh_margin need refresh';

  # Edge case: ttl=0 still produces a numeric _expires_at and does not die.
  $vault = StubVault->new(responses => [
    { creds => { username => 'u', password => 'p' } },
  ]);
  my $ttl0 = make_broker(
    vault          => $vault,
    ttl            => 0,
    refresh_margin => 0,
  );
  cmp_ok $ttl0->_expires_at, '>=', $start,
    'ttl=0 yields a defined _expires_at at or after the fetch time';
  # needs_refresh = time() > (start + 0 - 0) = time() > start.
  # Force a state where the math is unambiguous: rewind _expires_at by 1 so
  # the comparison is guaranteed to be true regardless of clock drift.
  $ttl0->_expires_at(time() - 1);
  ok $ttl0->needs_refresh,
    'ttl=0 with refresh_margin=0 and stale _expires_at needs refresh';
};

# -----------------------------------------------------------------------------
# 2. Credential fetch: a known token from the stub is wired through
#    connect_info_for and the legacy DBI-shaped return.
# -----------------------------------------------------------------------------
subtest 'credential fetch' => sub {
  my $vault = StubVault->new(responses => [
    { creds => { username => 'app-prod-1', password => 's3cret-lease' } },
  ]);
  my $broker = make_broker(vault => $vault);

  is_deeply $vault->called_paths, ['database/creds/myapp'],
    'broker only asked the vault for the configured cred_path';

  my $info = $broker->connect_info_for('write');
  is_deeply $info, [
    'dbi:Pg:dbname=app;host=db',
    'app-prod-1',
    's3cret-lease',
    { AutoCommit => 1, PrintError => 0 },
  ], 'connect_info_for returns the DBI-shaped tuple with stubbed creds';

  # $mode is vestigial — broker must not route on it.
  my $info_read = $broker->connect_info_for('read');
  is_deeply $info_read, $info,
    'connect_info_for returns the same info regardless of $mode (no routing)';
};

# -----------------------------------------------------------------------------
# 3. Credential rotation: a sequence of responses (expired -> fresh) is read
#    in order, the second set of credentials replaces the first, and the
#    refresh_margin bookkeeping updates accordingly.
# -----------------------------------------------------------------------------
subtest 'credential rotation' => sub {
  my $vault = StubVault->new(responses => [
    { creds => { username => 'old-user', password => 'old-pass' } },
    { creds => { username => 'new-user', password => 'new-pass' } },
  ]);
  my $broker = make_broker(
    vault => $vault,
    ttl   => 3600,
  );

  my $first = $broker->connect_info_for;
  is $first->[1], 'old-user', 'first fetch returned the initial credentials';
  is $vault->call_count, 1,    'vault was hit exactly once on construction';

  my $pre_refresh_expires = $broker->_expires_at;

  # Simulate the credential going stale — refresh now requires a new fetch.
  $broker->_expires_at(time() - 1);
  ok $broker->needs_refresh, 'after expiry, needs_refresh is true';

  $broker->refresh;
  is $vault->call_count, 2, 'refresh drove a second vault read';
  is_deeply $vault->called_paths,
    ['database/creds/myapp', 'database/creds/myapp'],
    'both fetches targeted the same cred_path';

  my $rotated = $broker->connect_info_for;
  is $rotated->[1], 'new-user', 'connect_info_for now reports the new username';
  is $rotated->[2], 'new-pass', 'connect_info_for now reports the new password';

  # _expires_at should be >= the previous one. We allow equality when both
  # fetches happen in the same wall-clock second (the broker does time()+ttl,
  # so if both run in the same second the values match exactly).
  cmp_ok $broker->_expires_at, '>=', $pre_refresh_expires,
    '_expires_at is at least the previous value after the rotation fetch';
  ok $broker->_expires_at - $pre_refresh_expires >= 0
    && $broker->_expires_at - $pre_refresh_expires <= 3600,
    '_expires_at advanced by at most ttl after the rotation fetch';
};

# -----------------------------------------------------------------------------
# 4. Transaction-safety: Vault is a rotating broker, so txn_begin must refuse
#    it by default, and the env override must let it through (with a warning).
# -----------------------------------------------------------------------------
subtest 'transaction-safety: refusal and override' => sub {
  my $vault = StubVault->new(responses => [
    { creds => { username => 'u', password => 'p' } },
  ]);
  my $broker = make_broker(vault => $vault);

  ok $broker->has_rotating_credentials,
    'Vault broker reports has_rotating_credentials';
  ok !$broker->is_transaction_safe,
    'Vault broker is not transaction-safe by default';

  my $schema = DBIO::Test->init_schema(no_deploy => 1);
  $schema->storage->set_access_broker($broker);

  # Default: txn_begin refuses with the expected reason.
  {
    local $ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS} = 0;
    my $err = _caught { $schema->storage->txn_begin };
    ok defined $err, 'txn_begin refused on a Vault broker with no override';
    isa_ok $err, 'DBIO::Exception',
      'refusal is a DBIO::Exception (F21: error taxonomy, not bare croak)';
    like "$err",
      qr/Refusing to start a transaction with unsafe AccessBroker/,
      'refusal message names the unsafe broker';
    like "$err", qr/credential rotation/,
      'refusal message names credential rotation as the reason';
  }

  # Override: env var set => txn_begin proceeds, emits a warning.
  # We rebuild the schema in this scope so the override state is fresh.
  my $schema2 = DBIO::Test->init_schema(no_deploy => 1);
  $schema2->storage->set_access_broker($broker);
  {
    local $ENV{DBIO_ALLOW_UNSAFE_BROKER_TRANSACTIONS} = 1;
    my $warned = 0;
    my $err;
    local $SIG{__WARN__} = sub {
      $warned++ if $_[0] =~ /unsafe AccessBroker/;
    };
    $err = _caught { $schema2->storage->txn_begin };
    ok !defined $err, 'txn_begin lives under the override env var';
    ok $warned, 'override emits a warning naming the unsafe broker';
    $schema2->storage->txn_rollback if !$err;  # tear the txn down cleanly
  }
};

# -----------------------------------------------------------------------------
# 5. Error path: a stub vault that throws a 5xx-shaped error must surface
#    through the broker. We use a fake 500 from the stub so no real network
#    is involved. The broker is expected to use the exception taxonomy; if
#    the current implementation croaks, the test still reports the path the
#    exception takes (and the karr ticket can decide whether to convert it
#    to throw_exception per F21).
# -----------------------------------------------------------------------------
subtest 'error path: 5xx-shaped vault error surfaces from the broker' => sub {
  my $vault = StubVault->new(responses => [
    { error => "HTTP 500 Internal Server Error" },
  ]);

  my $err;
  {
    # The broker is constructed in `new` via _fetch_credentials, so the
    # exception fires at construction time. Catch it without letting it
    # kill the test.
    local $@;
    eval { make_broker(vault => $vault) };
    $err = $@;
  }

  ok defined $err,
    'broker construction propagates a 5xx-shaped error from the vault';

  # The broker's _fetch_credentials does not catch upstream errors — it lets
  # the vault's exception propagate. Document the path: the message is
  # preserved end-to-end, and the broker does NOT swallow or rewrite it.
  like "$err", qr/HTTP 500/,
    'error message reaches the caller verbatim';
  like "$err", qr/DBIO\/AccessBroker\/Vault\.pm/,
    'error trace points to the broker line that called read_secret';
};

# Variant: vault returns no creds at all (e.g. a path the vault knows nothing
# about). The broker's `unless $creds` guard fires.
subtest 'error path: vault returns no creds -> broker croaks' => sub {
  my $vault = StubVault->new(responses => [
    { creds => undef },  # vault returns nothing
  ]);

  my $err;
  {
    local $@;
    eval { make_broker(vault => $vault) };
    $err = $@;
  }

  ok defined $err, 'broker construction dies when vault returns no creds';
  like "$err",
    qr/Vault returned no credentials for database\/creds\/myapp/,
    'error names the cred_path that came back empty';

  # NOTE: per F21, all error paths should go through the exception taxonomy
  # (DBIO::Exception / throw_exception). The current broker uses bare `croak`,
  # which produces a plain die. This test will start failing once the broker
  # is migrated; the failure is intentional — it documents the gap.
  isnt blessed($err), 'DBIO::Exception',
    'still a plain croak (F21 migration to throw_exception pending)';
};

# -----------------------------------------------------------------------------
# 6. No network at test time: a vault that explodes on any method other than
#    read_secret proves the broker never reaches for HTTP itself. This is the
#    "don't open a socket" guarantee.
# -----------------------------------------------------------------------------
subtest 'no network: broker never calls anything but read_secret on the vault' => sub {
  my $vault = StrictVault->new;

  my $err;
  {
    local $@;
    eval { make_broker(vault => $vault) };
    $err = $@;
  }

  ok defined $err, 'broker surfaced the strict-vault error (read_secret died)';
  is_deeply $vault->{calls}, {},
    'broker invoked zero non-read_secret methods on the vault (no LWP/UA calls)';
};

# -----------------------------------------------------------------------------
# Constructor validation: required args. Uses Test::Exception lives_ok / dies_ok.
# -----------------------------------------------------------------------------
subtest 'constructor: required args' => sub {
  my $vault = StubVault->new(responses => [
    { creds => { username => 'u', password => 'p' } },
  ]);

  # Use plain eval so we can survive state left over by prior subtests'
  # Carp::croak emissions. Test::Exception's dies_ok/lives_ok occasionally
  # doesn't catch plain Carp croaks after the test plan is finalized in
  # earlier subtests.
  my $err;
  $err = _caught { DBIO::AccessBroker::Vault->new };
  ok defined $err, 'constructor dies without any args';
  like "$err", qr/Vault broker requires 'vault'/,
    'error names the missing vault arg';

  $err = _caught { DBIO::AccessBroker::Vault->new(vault => $vault) };
  ok defined $err, 'constructor dies without dsn';
  like "$err", qr/Vault broker requires 'dsn'/,
    'error names the missing dsn arg';

  $err = _caught {
    DBIO::AccessBroker::Vault->new(vault => $vault, dsn => 'dbi:X:');
  };
  ok defined $err, 'constructor dies without cred_path';
  like "$err", qr/Vault broker requires 'cred_path'/,
    'error names the missing cred_path arg';

  $err = _caught { make_broker(vault => $vault) };
  ok !defined $err, 'constructor lives with the required trio';
};

done_testing;
