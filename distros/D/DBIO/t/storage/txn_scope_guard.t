use strict;
use warnings;

use Test::More;

use DBIO::Test;

# Backs the DBIO::Storage::TxnScopeGuard SYNOPSIS:
#
#   my $guard = $schema->txn_scope_guard;
#   # ... multiple database operations ...
#   $guard->commit;
#
# and the documented implicit-rollback-on-DESTROY path (a guard that goes out
# of scope *without* an explicit commit rolls the transaction back).
#
# Mock-only (CLAUDE.md). One caveat has to be worked around faithfully: the
# guard's DESTROY deliberately no-ops when the storage has no live $dbh
# (`return unless $self->{dbh}`) -- its whole point is not to roll back a
# connection that isn't there. DBIO::Test::Storage's _dbh is undef, so to
# exercise the rollback path at all we give the fake storage a stand-in dbh
# (a real driver always has one here). Everything else -- txn_begin/commit/
# rollback capture -- is the genuine mock machinery.

{
  package DBIO::Test::Storage::WithFakeDbh;
  use base 'DBIO::Test::Storage';
  use mro 'c3';

  # A single, program-lifetime fake handle so the guard's weakened dbh ref
  # stays live for the guard's whole scope.
  my $FAKE_DBH = bless {}, 'DBIO::Test::Storage::WithFakeDbh::FakeDbh';
  sub _dbh { $FAKE_DBH }

  # txn_commit consults ->FETCH('AutoCommit') only at depth 0; harmless stub.
  sub DBIO::Test::Storage::WithFakeDbh::FakeDbh::FETCH { 1 }
}

my $schema = DBIO::Test->init_schema(no_deploy => 1);
bless $schema->storage, 'DBIO::Test::Storage::WithFakeDbh';
my $storage = $schema->storage;

sub ops { map { $_->{op} } $storage->captured_queries }

subtest 'txn_scope_guard issues BEGIN; explicit commit issues COMMIT' => sub {
  $storage->reset_captured;

  {
    my $guard = $schema->txn_scope_guard;
    isa_ok $guard, 'DBIO::Storage::TxnScopeGuard', 'txn_scope_guard';

    ok((grep { $_ eq 'txn_begin' } ops()), 'BEGIN was issued when the guard was created');
    ok(!(grep { $_ eq 'txn_commit' } ops()), 'no COMMIT before ->commit');

    $guard->commit;
    ok((grep { $_ eq 'txn_commit' } ops()), 'COMMIT was issued by ->commit');
    ok(!(grep { $_ eq 'txn_rollback' } ops()), 'no ROLLBACK on the committed path');
  }

  # Guard already committed -> DESTROY must be inert (no extra rollback).
  is scalar(grep { $_ eq 'txn_rollback' } ops()), 0,
    'a committed guard does not roll back when it leaves scope';
};

subtest 'dropping a guard without commit rolls back (implicit DESTROY)' => sub {
  $storage->reset_captured;

  my @warnings;
  {
    local $SIG{__WARN__} = sub { push @warnings, "@_" };
    local $@;

    my $guard = $schema->txn_scope_guard;
    ok((grep { $_ eq 'txn_begin' } ops()), 'BEGIN was issued');

    # no commit -- drop the last reference, DESTROY fires synchronously
    undef $guard;
  }

  ok((grep { $_ eq 'txn_rollback' } ops()),
    'ROLLBACK was issued when the guard went out of scope uncommitted');
  ok(!(grep { $_ eq 'txn_commit' } ops()), 'no COMMIT on the rolled-back path');
  ok((grep { /without explicit commit or error/i } @warnings),
    'the documented "went out of scope without explicit commit" warning was emitted');
};

subtest 'explicit ->rollback issues ROLLBACK and inactivates the guard' => sub {
  $storage->reset_captured;

  my $guard = $schema->txn_scope_guard;
  $guard->rollback;
  ok((grep { $_ eq 'txn_rollback' } ops()), 'ROLLBACK issued by ->rollback');

  # A second commit/rollback on an inactivated guard must be refused.
  eval { $guard->commit };
  like $@, qr/multiple commit\/rollbacks/i,
    'committing an already-inactivated guard throws';
};

done_testing;
