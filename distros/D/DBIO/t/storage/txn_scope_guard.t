use strict;
use warnings;

use Test::More;
use Scalar::Util qw(refaddr);

use DBIO::Test;
use DBIO::Exception::Server ();

# Backs the DBIO::Storage::TxnScopeGuard SYNOPSIS:
#
#   my $guard = $schema->txn_scope_guard;
#   # ... multiple database operations ...
#   $guard->commit;
#
# and the documented implicit-rollback-on-DESTROY path (a guard that goes out
# of scope *without* an explicit commit rolls the transaction back).
#
# Mock-only (CLAUDE.md). The guard's DESTROY deliberately no-ops when the
# storage has no live $dbh (`return unless $self->{dbh}`) -- its whole point is
# not to roll back a connection that isn't there. DBIO::Test::Storage carries a
# stand-in handle for exactly that reason, so the rollback path is
# reachable here without any local scaffolding; txn_begin/commit/rollback
# capture is the genuine mock machinery.

my $schema = DBIO::Test->init_schema(no_deploy => 1);
my $storage = $schema->storage;

sub ops { map { $_->{op} } $storage->captured_queries }

# Tripwire for the above: without a handle to weaken, every rollback assertion
# in this file would pass by doing nothing at all.
ok $storage->_dbh, 'the fake storage hands the guard a handle to weaken';

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
  # The handler stays for the whole subtest: how soon DESTROY runs after the
  # last reference is gone is up to perl (older perls run it a statement
  # later), the warning must be caught either way.
  local $SIG{__WARN__} = sub { push @warnings, "@_" };
  local $@;

  my $guard = $schema->txn_scope_guard;
  ok((grep { $_ eq 'txn_begin' } ops()), 'BEGIN was issued');

  # no commit -- drop the last reference
  undef $guard;

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

# A rollback that fails while an exception is in flight (karr k303).
#
# The exception on its way to the caller is the caller's: perl sets $@ again
# once the stack has unwound, so nothing the guard assigns to $@ in DESTROY
# arrives there. The news "the transaction is still open" travels with the
# exception only when the guard may write into it -- and it knows the inside of
# exactly one class, DBIO::Exception itself, not of a subclass and not of
# anybody else's object. For everything else the warning is the one channel
# left. Before k303 the guard used none: three of the four cases below ended
# with an open transaction that nobody had heard of.

{
  package K303::ForeignException;
  use overload '""' => sub { $_[0]{text} }, fallback => 1;
  sub new { bless { text => $_[1] }, $_[0] }

  package K303::DerivedException;
  our @ISA = ('DBIO::Exception');
}

my @in_flight = (
  # what flies, the exception, whether the guard may write into it
  [ 'a string',
    sub { "body died\n" }, 0 ],
  [ 'exactly a DBIO::Exception',
    sub { eval { DBIO::Exception->throw('body died') }; $@ }, 1 ],
  # what the synchronous HandleError throws for a refused statement (ADR 0062):
  # a core class with the {msg} of DBIO::Exception, so it carries the news too
  [ 'a DBIO::Exception::Server',
    sub { DBIO::Exception::Server->new(message => "body died\n", sqlstate => '40001') }, 1 ],
  [ 'a subclass of DBIO::Exception',
    sub { eval { K303::DerivedException->throw('body died') }; $@ }, 0 ],
  [ 'a foreign exception object',
    sub { K303::ForeignException->new('body died') }, 0 ],
);

# Sends a guard out of scope by $exception, on a storage of its own: a failed
# rollback leaves the storage inside its transaction. $rollback is what the
# guard's rollback meets -- 'ok', 'fails', or 'nested' (an enclosing transaction
# without savepoints, where a rollback raises NESTED_ROLLBACK_EXCEPTION).
sub leave_guard_by_exception {
  my ($exception, $rollback) = @_;

  my $schema  = DBIO::Test->init_schema(no_deploy => 1);
  my $storage = $schema->storage;

  no warnings 'redefine';
  local *DBIO::Test::Storage::_exec_txn_rollback = sub { die "ROLLBACK BROKE\n" }
    if $rollback eq 'fails';

  $storage->txn_begin if $rollback eq 'nested';

  my @warnings;
  local $SIG{__WARN__} = sub { push @warnings, "@_" };

  eval { my $guard = $schema->txn_scope_guard; die $exception };
  my $caught = $@;

  return ($caught, \@warnings, $storage);
}

# The caller's exception is the one it threw: the same object, or the same string.
sub is_the_callers_own {
  my ($caught, $exception, $name) = @_;

  return is $caught, $exception, $name unless ref $exception;

  is ref($caught) && refaddr($caught), refaddr($exception), $name;
}

for my $case (@in_flight) {
  my ($kind, $make, $guard_may_write_into_it) = @$case;

  subtest "the rollback fails while $kind is in flight" => sub {
    my $exception = $make->();
    my $text = "$exception";

    my ($caught, $warnings) = leave_guard_by_exception($exception, 'fails');

    is_the_callers_own $caught, $exception, 'the caller gets the exception it threw';

    if ($guard_may_write_into_it) {
      is "$caught", "Transaction aborted: $text Rollback failed: ROLLBACK BROKE\n",
        'which now says that the rollback failed, and why';
      is_deeply $warnings, [],
        'nothing is warned: the exception carries it to the caller';
    }
    else {
      is "$caught", $text, 'unchanged';

      my @failed = grep { /ROLLBACK FAILED/ } @$warnings;
      is scalar(@failed), 1, 'exactly one warning reports the failed rollback'
        or diag explain $warnings;
      like $failed[0], qr/ROLLBACK BROKE/, 'it carries the rollback error';
      like $failed[0], qr/body died/,
        'and the exception that was in flight, so that the two can be matched';
      is scalar(@$warnings), 1, 'nothing else is warned'
        or diag explain $warnings;
    }
  };

  subtest "the rollback succeeds while $kind is in flight" => sub {
    my $exception = $make->();
    my $text = "$exception";

    my ($caught, $warnings, $storage) = leave_guard_by_exception($exception, 'ok');

    ok((grep { $_->{op} eq 'txn_rollback' } $storage->captured_queries),
      'the guard rolled back');
    is_the_callers_own $caught, $exception, 'the caller gets the exception it threw';
    is "$caught", $text, 'unchanged';
    is_deeply $warnings, [], 'a rollback that worked is not reported as failed';
  };

  subtest "a nested rollback while $kind is in flight" => sub {
    my $exception = $make->();
    my $text = "$exception";

    my ($caught, $warnings, $storage) = leave_guard_by_exception($exception, 'nested');

    # Tripwire: txn_rollback sets this right before it throws
    # NESTED_ROLLBACK_EXCEPTION, so the guard's rollback did raise it.
    ok $storage->deferred_rollback,
      'the guard\'s rollback raised the nested-rollback exception';
    is_the_callers_own $caught, $exception, 'the caller gets the exception it threw';
    is "$caught", $text, 'unchanged';
    is_deeply $warnings, [],
      'no failed rollback is reported: the enclosing transaction rolls back';
  };
}

done_testing;
