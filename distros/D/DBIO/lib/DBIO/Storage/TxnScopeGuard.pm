package DBIO::Storage::TxnScopeGuard;
# ABSTRACT: Scope-based transaction handling

use strict;
use warnings;

our $VERSION = '0.900005';

use Try::Tiny;
use Scalar::Util qw(weaken blessed refaddr);
use DBIO;
use DBIO::Util qw(is_exception is_windows);
use DBIO::Carp;
use namespace::clean;

sub new {
  my ($class, $storage) = @_;

  my $guard = {
    inactivated => 0,
    storage => $storage,
  };

  # we are starting with an already set $@ - in order for things to work we need to
  # be able to recognize it upon destruction - store its weakref
  # recording it before doing the txn_begin stuff
  #
  # FIXME FRAGILE - any eval that fails but *does not* rethrow between here
  # and the unwind will trample over $@ and invalidate the entire mechanism
  # There got to be a saner way of doing this...
  if (is_exception $@) {
    weaken(
      $guard->{existing_exception_ref} = (ref($@) eq '') ? \$@ : $@
    );
  }

  $storage->txn_begin;

  weaken( $guard->{dbh} = $storage->_dbh );

  bless $guard, ref $class || $class;

  $guard;
}

sub commit {
  my $self = shift;

  $self->{storage}->throw_exception("Refusing to execute multiple commit/rollbacks on scope guard $self")
    if $self->{inactivated};

  # A commit that fails ends the transaction: txn_commit resets the storage's
  # transaction state, tries the rollback itself and rethrows the commit's
  # error (karr k372). Nothing is left for the guard to roll back.
  $self->{inactivated} = 1;
  $self->{storage}->txn_commit;
}

sub rollback {
  my $self = shift;

  $self->{storage}->throw_exception("Refusing to execute multiple commit/rollbacks on scope guard $self")
    if $self->{inactivated};

  $self->{inactivated} = 1;
  $self->{storage}->txn_rollback;
}

sub DESTROY {
  my $self = shift;

  if ($self->{_destroy_invoked}++) {
    carp 'Preventing *MULTIPLE* DESTROY() invocations on DBIO::Storage::TxnScopeGuard';
    return;
  }

  return if $self->{inactivated};
  $self->{inactivated} = 1;

  # if our dbh is not ours anymore, the $dbh weakref will go undef
  $self->{storage}->_verify_pid unless is_windows;
  return unless $self->{dbh};

  my $exception = $@ if (
    is_exception $@
      and
    (
      ! defined $self->{existing_exception_ref}
        or
      refaddr( ref($@) eq '' ? \$@ : $@ ) != refaddr($self->{existing_exception_ref})
    )
  );

  {
    local $@;

    carp 'A DBIO::Storage::TxnScopeGuard went out of scope without explicit commit or error. Rolling back.'
      unless defined $exception;

    my $rollback_exception;
    # do minimal connectivity check due to weird shit like
    # https://rt.cpan.org/Public/Bug/Display.html?id=62370
    try { $self->{storage}->_seems_connected && $self->{storage}->txn_rollback }
    catch { $rollback_exception = shift };

    if ( $rollback_exception and (
      ! defined blessed $rollback_exception
          or
      ! $rollback_exception->isa('DBIO::Storage::NESTED_ROLLBACK_EXCEPTION')
    ) ) {
      # append our text - THIS IS A TEMPORARY FIXUP!
      # a real stackable exception object is in the works
      # DBIO::Exception::Server is what the synchronous HandleError throws for
      # a refused statement (ADR 0062); it has the same {msg} and is ours
      if (ref $exception eq 'DBIO::Exception'
        or ref $exception eq 'DBIO::Exception::Server'
      ) {
        $exception->{msg} = "Transaction aborted: $exception->{msg} "
          ."Rollback failed: ${rollback_exception}";
      }
      else {
        # Nothing else takes the news along. The inside of a foreign object,
        # or of a DBIO::Exception subclass, is not ours to write into, and
        # what gets assigned to $@ below is replaced by the exception in
        # flight once the stack has unwound. The warning always arrives.
        carp (join ' ',
          "********************* ROLLBACK FAILED!!! ********************",
          "\nA rollback operation failed after the guard went out of scope.",
          'This is potentially a disastrous situation, check your data for',
          "consistency: $rollback_exception"
          . ( $exception
            ? "\nThe guard went out of scope while this exception was in flight: $exception"
            : ''
          )
        );

        $exception = "Transaction aborted: ${exception} "
          ."Rollback failed: ${rollback_exception}"
          if $exception;
      }
    }
  }

  $@ = $exception;
}

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Storage::TxnScopeGuard - Scope-based transaction handling

=head1 VERSION

version 0.900005

=head1 SYNOPSIS

 sub foo {
   my ($self, $schema) = @_;

   my $guard = $schema->txn_scope_guard;

   # Multiple database operations here

   $guard->commit;
 }

See F<t/storage/txn_scope_guard.t> for a runnable example: BEGIN on
creation, COMMIT on C<< ->commit >>, and the implicit ROLLBACK when a
guard leaves scope without an explicit commit.

=head1 DESCRIPTION

An object that behaves much like L<Scope::Guard>, but hardcoded to do the
right thing with transactions in DBIO.

=head1 METHODS

=head2 new

Creating an instance of this class will start a new transaction (by
implicitly calling L<DBIO::Storage/txn_begin>. Expects a
L<DBIO::Storage> object as its only argument.

=head2 commit

Commit the transaction, and stop guarding the scope. If this method is not
called and this object goes out of scope (e.g. an exception is thrown) then
the transaction is rolled back, via L<DBIO::Storage/txn_rollback>

If the commit itself fails, the guard is spent all the same and the commit's
error is thrown: the storage has already reset its transaction state (depth 0),
tried a rollback and, when that failed as well, discarded the handle (see
L<DBIO::Storage/txn_commit>). A following statement does not run inside the
failed transaction.

=head2 rollback

Roll back the transaction, and stop guarding the scope. You can use this to
avoid the warning when the scope guard goes out of scope, for deliberate
rollbacks.

=head1 WHEN THE ROLLBACK FAILS

The rollback a guard issues on going out of scope can fail in turn, and then
the transaction may still be open on the connection. Where that is reported
depends on the exception in flight at that point, which to the guard is an
exception in C<$@> that was not there when the guard was created:

=over 4

=item *

Exactly a L<DBIO::Exception>, not a subclass of it: its message becomes
C<Transaction aborted: $message Rollback failed: $rollback_error>. The caller
catches the same object, and nothing is warned.

=item *

Any other exception - a string, an object of another class, a subclass of
L<DBIO::Exception>: the guard cannot write into it, so it warns
C<ROLLBACK FAILED> with the rollback error and the text of that exception.
An exception that is unwinding the stack reaches the caller as it was thrown.

=item *

No exception: the guard warns C<ROLLBACK FAILED> with the rollback error.

=back

The C<DBIO::Storage::NESTED_ROLLBACK_EXCEPTION> a rollback raises inside an
enclosing transaction without savepoints (see L<DBIO::Storage/txn_rollback>)
is not a failure and is not reported: the enclosing transaction rolls back.

=head1 SEE ALSO

L<DBIO::Schema/txn_scope_guard>.

L<Scope::Guard> by chocolateboy (inspiration for this module)

=head1 AUTHOR

DBIO & DBIx::Class Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors
Portions Copyright (C) 2005-2025 DBIx::Class Authors
Based on DBIx::Class, heavily modified.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
