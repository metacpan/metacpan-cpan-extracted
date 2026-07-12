use strict;
use warnings;
use Test::More;

use DBIO::Test;
use DBIO::Storage::Async;
use DBIO::Storage::DBI;
use DBIO::Test::Storage;

# karr #67 -- ADR 0030, second future_io refinement.
#
# t/test/16_async_future_io_convention.t (karr #65) locked in the SINGLE
# candidate rule: future_io's transport adapter is ref($storage) . '::Async',
# tried exactly once. That works for a driver storage class directly under
# DBIO::Storage::DBI, but an EXTENSION storage_type subclass (the
# DBIO::PostgreSQL::Age::Storage / DBIO::PostgreSQL::PostGIS::Storage pattern
# -- isa the driver's own storage, not DBIO::Storage::DBI directly) has no
# ::Async sibling of its own and loses future_io entirely, even for plain CRUD,
# while the 'ev' registry mode (which already walks the MRO) keeps working on
# the very same schema. This is a core resolution gap, not a driver bug.
#
# The decided fix (see karr #67, ADR 0030 refinement): the future_io
# convention walks mro::get_linear_isa(ref($self)), most-specific first,
# exactly like the registry resolver (_resolve_async_mode_class) already does
# for 'ev'/'forked' -- but STOPS strictly BEFORE the generic
# DBIO::Storage::DBI base (never probes DBIO::Storage::DBI::Async or
# anything above it -- that hole is exactly what karr #65 banned). A
# candidate that LOADS but is not a DBIO::Storage::Async croaks immediately,
# it never silently falls through to a parent's otherwise-valid adapter.
#
# This file is the RED test for that fix: cases 2 and 4b below fail today
# (still single-candidate) and must turn green once the walk lands. Cases 1,
# 3, and 5 are regression guards -- already green today, and must STAY green
# after the fix. Case 6 (the generic-base stop boundary) lives in its own
# file, t/test/18_async_future_io_mro_walk_base_guard.t, because it plants a
# package directly into the real DBIO::Storage::DBI namespace and that
# pollution must never coexist in the same process as the classes here.
#
# Mock only (DBIO::Test::Storage, no real DBD). No event loop is exercised --
# these tests only drive the pure CLASS resolution path in
# DBIO::Storage::DBI::_async_storage; the resolved adapter is never asked to
# actually run a query (that CRUD round-trip is already covered by t/test/16).

# ---------------------------------------------------------------------------
# Fake driver hierarchy (ticket's illustrative names, Karr67::-namespaced here
# to avoid polluting the global namespace, matching the Karr66::/AsyncConv::
# convention already used by the sibling async tests).
# ---------------------------------------------------------------------------

# Case 1 (baseline): TestDrv::Storage + its own TestDrv::Storage::Async.
{
  package Karr67::TestDrv::Storage;
  use base 'DBIO::Test::Storage';
  use mro 'c3';
}
{
  package Karr67::TestDrv::Storage::Async;
  use base 'DBIO::Storage::Async';
}

# Case 2: TestExt::Storage isa TestDrv::Storage, no ::Async of its own --
# must walk up and resolve TestDrv::Storage::Async.
{
  package Karr67::TestExt::Storage;
  use base 'Karr67::TestDrv::Storage';
  use mro 'c3';
}

# Case 3: TestExt2::Storage isa TestDrv::Storage, WITH its own ::Async
# (itself a valid DBIO::Storage::Async, subclassing the parent's adapter) --
# the own one must win, not the parent's.
{
  package Karr67::TestExt2::Storage;
  use base 'Karr67::TestDrv::Storage';
  use mro 'c3';
}
{
  package Karr67::TestExt2::Storage::Async;
  use base 'Karr67::TestDrv::Storage::Async';
}

# Case 4: a chain with NO adapter anywhere (two ancestor levels, neither with
# an ::Async sibling) -- must croak, and (after the fix) the message must
# evidence the walk by naming more than just the single most-specific
# candidate.
{
  package Karr67::TestNoAdapter::Base::Storage;
  use base 'DBIO::Test::Storage';
  use mro 'c3';
}
{
  package Karr67::TestNoAdapter::Storage;
  use base 'Karr67::TestNoAdapter::Base::Storage';
  use mro 'c3';
}

# Case 5: TestBroken::Storage isa TestDrv::Storage (whose adapter IS valid),
# but TestBroken::Storage::Async itself LOADS and is NOT a DBIO::Storage::Async
# -- must croak naming the broken class, never silently fall back to the
# parent's perfectly good adapter.
{
  package Karr67::TestBroken::Storage;
  use base 'Karr67::TestDrv::Storage';
  use mro 'c3';
}
{
  package Karr67::TestBroken::Storage::Async;
  # Deliberately NOT `use base 'DBIO::Storage::Async'` -- this is the
  # "loads but is the wrong type" case. A working new() is provided anyway
  # so that IF a buggy implementation ever got far enough to construct it,
  # the test would still fail for the resolution-guard reason and not for an
  # unrelated "no such method new" runtime error.
  sub new { bless {}, shift }
}

# Build a driver storage of $class in future_io mode, bound to a live schema,
# exactly like t/test/16_async_future_io_convention.t's helper of the same
# purpose. Returns ($storage, $schema).
sub driver_storage {
  my ($class) = @_;
  my $schema  = DBIO::Test->init_schema;
  my $storage = $class->new($schema);
  $storage->_async_mode('future_io');   # Test::Storage defaults to 'immediate'
  delete $storage->{_async_storage_obj};
  $storage->_connect_info([ { host => 'localhost' } ]);
  return ($storage, $schema);
}

# ---------------------------------------------------------------------------
# 1. Baseline: exact-name convention resolution still works.
#    GREEN today, must STAY green after the fix (regression guard).
# ---------------------------------------------------------------------------
{
  my ($storage) = driver_storage('Karr67::TestDrv::Storage');
  my $async = $storage->async;
  isa_ok $async, 'Karr67::TestDrv::Storage::Async',
    'baseline: exact-name convention resolution still works (regression guard)';
}

# ---------------------------------------------------------------------------
# 2. A subclass WITHOUT its own ::Async must walk up to the parent's adapter.
#    RED today: only the exact-name candidate (Karr67::TestExt::Storage::Async,
#    which does not exist) is ever tried today, so this croaks. GREEN once the
#    MRO walk lands.
# ---------------------------------------------------------------------------
{
  my ($storage) = driver_storage('Karr67::TestExt::Storage');
  my $async = eval { $storage->async };
  my $err   = $@;

  ok !$err,
    'RED before the fix / GREEN after: walking up to the parent adapter does not croak'
    or diag "died with: $err";
  isa_ok $async, 'Karr67::TestDrv::Storage::Async',
    'RED before the fix / GREEN after: a subclass without its own ::Async '
    . 'resolves the nearest ancestor adapter';
}

# ---------------------------------------------------------------------------
# 3. A subclass WITH its own ::Async: its own wins, not the parent's.
#    GREEN today (today's single exact-name candidate already IS this class)
#    and must STAY green after the fix (precedence guard: nearest-first, not
#    parent-first).
# ---------------------------------------------------------------------------
{
  my ($storage) = driver_storage('Karr67::TestExt2::Storage');
  my $async = $storage->async;
  is ref($async), 'Karr67::TestExt2::Storage::Async',
    "GREEN today and after the fix: a subclass's own ::Async adapter wins over "
    . "the parent's, never the other way round";
  isa_ok $async, 'DBIO::Storage::Async', '... which is a proper async backend';
}

# ---------------------------------------------------------------------------
# 4. A chain with NO adapter anywhere: croaks either way, but the MESSAGE
#    only evidences the walk after the fix.
# ---------------------------------------------------------------------------
{
  my ($storage) = driver_storage('Karr67::TestNoAdapter::Storage');
  my $async = eval { $storage->async };
  my $err   = $@;

  ok !defined($async) && $err,
    'GREEN today and after the fix: no adapter anywhere in the chain croaks';
  like $err, qr/does not support future_io/,
    'GREEN today and after the fix: standard future_io croak wording';
  like $err, qr/\QKarr67::TestNoAdapter::Storage::Async\E/,
    'GREEN today and after the fix: message names the most-specific tried candidate';

  # RED before the fix / GREEN after: today exactly ONE candidate is ever
  # tried (ref($self) . '::Async'), so the message never reaches the next
  # rung of the chain. After the fix walks the MRO, the message must ALSO
  # name the parent-level candidate, evidencing that the walk actually
  # happened instead of giving up after a single try.
  like $err, qr/\QKarr67::TestNoAdapter::Base::Storage::Async\E/,
    'RED before the fix / GREEN after: message also names the parent-level '
    . 'candidate, evidencing the MRO walk';
}

# ---------------------------------------------------------------------------
# 5. An adapter that LOADS but is not a DBIO::Storage::Async must croak
#    naming the broken class -- never silently fall back to the parent's
#    otherwise-valid adapter.
#    GREEN today (there is no walk at all yet to fall back through) and must
#    STAY green after the fix (this is the guard against ever reintroducing
#    a silent skip-to-parent on a type mismatch).
# ---------------------------------------------------------------------------
{
  # Sanity check: the parent's adapter really is valid, so a resolution that
  # silently walked past the broken one would have somewhere to land.
  ok( Karr67::TestDrv::Storage::Async->isa('DBIO::Storage::Async'),
    "sanity: the parent's own adapter is a valid DBIO::Storage::Async "
    . '(it must never be silently substituted in)' );

  my ($storage) = driver_storage('Karr67::TestBroken::Storage');
  my $async = eval { $storage->async };
  my $err   = $@;

  ok !defined($async) && $err,
    'GREEN today and after the fix: a same-named adapter of the wrong type croaks';
  like $err, qr/does not support future_io/,
    'GREEN today and after the fix: standard future_io croak wording';
  like $err, qr/\QKarr67::TestBroken::Storage::Async\E/,
    'GREEN today and after the fix: message names the broken class';
  unlike $err, qr/\QKarr67::TestDrv::Storage::Async\E/,
    'GREEN today and after the fix: message must not silently substitute the '
    . "parent's adapter class name";
}

done_testing;
