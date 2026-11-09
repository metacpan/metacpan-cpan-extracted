use strict;
use warnings;
use Test::More;
use Test::Exception;

use Scalar::Util ();

# karr core k209 -- LOAD-ORDER regression for the async context classes.
#
# DBIO::Storage::Async::TransactionContext and ::PipelineContext resolve the
# effective async-context owner through the fully-qualified helper
# DBIO::Storage::Async::_effective_owner_of (ADR 0051 backward-compat addendum).
# Neither context file loads DBIO::Storage::Async: Async.pm use-s both context
# classes at compile time (its lines 13-14), so a compile-time
# `use DBIO::Storage::Async` in the context files would close a circular use.
#
# In core's own suite Async.pm is effectively always already loaded (you build
# an Async storage first, which pulls it), so the gap was hidden -- and
# t/test/32_async_standalone_owner.t even `use`s it at the top, masking it
# outright. But two real load orders never pull Async.pm before a context runs:
#
#   * dbio-async loads the context classes standalone --
#     DBIO::Async::TransactionContext does `use base
#     'DBIO::Storage::Async::TransactionContext'` and nothing else -- so
#     `perl -Ilib t/05-transaction-context.t` there never touched Async.pm; and
#   * a bare mock backend (the driver test shape: dbio-async's MockStorage5,
#     dbio-postgresql-ev's MockStorage27) plays the backend/owner role for a
#     context WITHOUT subclassing DBIO::Storage::Async.
#
# On either path the helper was an undefined subroutine and the first ownership
# check died: "Undefined subroutine &DBIO::Storage::Async::_effective_owner_of".
#
# This test reproduces that exact load order: it loads ONLY the two context
# classes and MUST NOT `use DBIO::Storage::Async` -- doing so would re-mask the
# regression, exactly as it is masked in t/test/32. The fix makes each context
# lazily `require DBIO::Storage::Async` on first ownership check, so the helper
# is defined by the time it is called without closing the compile-time cycle.
#
# House rule 11 -- the ownership assertions the check performs must survive the
# fix, so this test uses a FAITHFUL token comparison (the shape core's real
# DBIO::Storage::DBI::_assert_async_context_owner and dbio-async's MockStorage5
# use), never an unconditional accept, and proves all three properties per
# context class: same generation ACCEPTED, a superseded generation REFUSED,
# a tokenless context FAILS CLOSED.

# Load ONLY the context classes. Deliberately NOT DBIO::Storage::Async.
use DBIO::Storage::Async::TransactionContext;
use DBIO::Storage::Async::PipelineContext;

# --- A bare mock backend: its own owner, faithful per-generation token. -------
# NOT a DBIO::Storage::Async subclass, so loading/constructing it never pulls
# Async.pm -- this is the standalone/EV-first shape that exposed the bug.
{
  package K209::OwnerMock;
  sub new { bless { token => \(my $o), asserted => 0, refused => 0 }, shift }
  sub _context_owner_token { $_[0]{token} }
  sub _owner_storage       { $_[0] }               # single ownership domain
  sub storage              { $_[0] }
  sub pool                 { undef }
  sub _rotate_token        { $_[0]{token} = \(my $o); return }   # new generation

  # The exact token comparison core's DBIO::Storage::DBI runs: context-shaped
  # objects without matching token evidence fail closed.
  sub _assert_async_context_owner {
    my ($self, $ctx) = @_;
    unless (Scalar::Util::blessed($ctx) && $ctx->can('_context_owner_token')) {
      $self->{refused}++;
      die "async context ownership cannot be proven\n";
    }
    my $ours   = $self->_context_owner_token;
    my $theirs = $ctx->_context_owner_token;
    unless ($ours && $theirs
        && Scalar::Util::refaddr($ours) == Scalar::Util::refaddr($theirs)) {
      $self->{refused}++;
      die "async context does not belong to this storage generation\n";
    }
    $self->{asserted}++;
    return $ctx;
  }
}

# A backend that yields NO token: a context built over it snapshots undef, so
# the owner's faithful comparison has no positive ownership evidence to accept.
{
  package K209::TokenlessMock;
  our @ISA = ('K209::OwnerMock');
  sub _context_owner_token { undef }
}

my %ctx_class = (
  'DBIO::Storage::Async::TransactionContext' => 'txn_conn',
  'DBIO::Storage::Async::PipelineContext'    => 'pipeline_conn',
);

sub make_ctx {
  my ($class, $backend) = @_;
  return $class->new(storage => $backend, $ctx_class{$class} => 'CONN');
}

# ---------------------------------------------------------------------------
# Precondition: the context classes did NOT drag in DBIO::Storage::Async. If a
# future transitive use starts pulling it in, this test stops being a load-order
# tripwire -- fail loudly rather than silently pass a masked run.
# ---------------------------------------------------------------------------
ok !$INC{'DBIO/Storage/Async.pm'},
  'precondition: loading the context classes did NOT load DBIO::Storage::Async (the standalone/EV-first load order)';

# ---------------------------------------------------------------------------
# 1. Same generation ACCEPTED -- the pre-fix crash site.
#    Pre-fix: dies "Undefined subroutine &..._effective_owner_of".
#    Post-fix: the lazy require loads Async.pm and the check PROVES ownership.
# ---------------------------------------------------------------------------
for my $class (sort keys %ctx_class) {
  my $owner = K209::OwnerMock->new;
  my $ctx   = make_ctx($class, $owner);

  lives_ok { $ctx->_assert_context_active }
    "$class: standalone ownership check runs (no pre-loaded DBIO::Storage::Async) and accepts a same-generation context (k209)";
  is $owner->{asserted}, 1,
    "$class: ownership was PROVEN against the owner token, not skipped or waved through";
  is $owner->{refused}, 0,
    "$class: a legitimate same-generation context was not refused";
}

# The very first ownership check above must have lazily loaded Async.pm via the
# in-body require -- that is the fix. (Before it ran, the precondition proved it
# was absent.)
ok $INC{'DBIO/Storage/Async.pm'},
  'the ownership check lazily require-d DBIO::Storage::Async, defining _effective_owner_of without closing the compile-time use-cycle';

# ---------------------------------------------------------------------------
# 2. Superseded generation REFUSED -- the "same backend object can own a
#    different pool generation after disconnect" case the snapshot comment in
#    both context classes exists for. The context snapshots the token at
#    construction; rotating the backend's token afterwards must make the check
#    refuse it, through the owner's token comparison.
# ---------------------------------------------------------------------------
for my $class (sort keys %ctx_class) {
  my $owner = K209::OwnerMock->new;
  my $ctx   = make_ctx($class, $owner);   # snapshots the current generation
  $owner->_rotate_token;                  # backend now owns a NEW generation

  throws_ok { $ctx->_assert_context_active }
    qr/does not belong to this storage generation/,
    "$class: a context from a superseded generation is REFUSED (foreign context)";
  ok $owner->{refused},
    "$class: the refusal went through the owner's token comparison, not a bare accept";
}

# ---------------------------------------------------------------------------
# 3. Tokenless context FAILS CLOSED -- no positive ownership evidence must never
#    be waved through.
# ---------------------------------------------------------------------------
for my $class (sort keys %ctx_class) {
  my $owner = K209::TokenlessMock->new;
  my $ctx   = make_ctx($class, $owner);   # snapshots undef

  throws_ok { $ctx->_assert_context_active }
    qr/does not belong to this storage generation|ownership cannot be proven/,
    "$class: a tokenless context fails closed";
  ok $owner->{refused},
    "$class: the tokenless context was actively refused, not silently passed";
}

done_testing;
