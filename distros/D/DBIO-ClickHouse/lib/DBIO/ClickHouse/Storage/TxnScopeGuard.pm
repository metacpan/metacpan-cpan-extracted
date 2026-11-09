package DBIO::ClickHouse::Storage::TxnScopeGuard;
# ABSTRACT: Scope guard for a storage that has nothing to roll back

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Storage::TxnScopeGuard';

use DBIO::Carp;
use DBIO::Util qw(is_windows);
use namespace::clean;


sub DESTROY {
  my $self = shift;

  return if $self->{inactivated};
  $self->{inactivated} = 1;

  # Same fork check core performs. When it fires it resets transaction_depth
  # itself, which is why the early return below may skip the unwind.
  $self->{storage}->_verify_pid unless is_windows;
  return unless $self->{dbh};

  # Unwind core's depth bookkeeping by hand. txn_rollback does this too, but
  # it throws afterwards; a guard leaving scope is not a caller claiming work
  # was undone. Left alone the depth would stick, and every later statement
  # would believe it runs inside a transaction.
  my $depth = $self->{storage}->transaction_depth;
  $self->{storage}->transaction_depth($depth - 1) if $depth;

  # local() restores $@ when this scope exits, so an exception unwinding
  # through here reaches its handler exactly as it was thrown -- including the
  # case where carp() itself runs an eval.
  local $@;

  carp(
    'A transaction scope guard left scope without an explicit commit and '
  . 'NOTHING WAS ROLLED BACK: ClickHouse has no transactions, so every '
  . 'statement completed inside that scope is permanent. Check your data for '
  . 'consistency'
  );

  return;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::ClickHouse::Storage::TxnScopeGuard - Scope guard for a storage that has nothing to roll back

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The scope guard L<DBIO::ClickHouse::Storage/txn_scope_guard> hands out. It is
L<DBIO::Storage::TxnScopeGuard> with one method replaced: L</DESTROY> B<carps>
instead of rolling back, because on ClickHouse there is nothing to roll back
(C<docs/adr/0003-no-transactions-policy.md>).

You do not instantiate this yourself. Core takes a guard on your behalf in
C<delete_all>, C<update_all>, multi-create, cascade delete and non-void
C<populate>; this class is what those get.

Construction, L<DBIO::Storage::TxnScopeGuard/commit> and
L<DBIO::Storage::TxnScopeGuard/rollback> are inherited unchanged, which is the
point -- they already land on the right answer:

=over 4

=item * C<new> calls C<txn_begin>, a no-op that keeps core's
C<transaction_depth> bookkeeping (L<DBIO::ClickHouse::Storage/_exec_txn_begin>).

=item * C<< $guard->commit >> calls C<txn_commit>, likewise a no-op.

=item * C<< $guard->rollback >> calls
L<DBIO::ClickHouse::Storage/txn_rollback> and therefore B<throws>. That is a
caller stating that work was undone, and it is as untrue when written on a
guard as it is when written on the schema.

=back

=head1 METHODS

=head2 DESTROY

Unwinds C<transaction_depth> by one and C<carp>s that nothing was rolled back.
Never throws, and never touches the in-flight exception.

Core's implementation would call C<txn_rollback> here, which on this storage
throws -- inside a C<DESTROY>, during someone else's stack unwind. Its
C<catch> block then rewrites the exception that was already travelling: a
L<DBIO::Exception> is B<mutated in place> to
C<"Transaction aborted: <original> Rollback failed: <our refusal>">, once per
guard on the stack. A C<delete_all> inside a caller's own guard nests three
deep, so the real error arrives behind three C<"Transaction aborted:"> prefixes
and a repeated paragraph about a rollback that was never possible in the first
place.

That decoration is noise on a driver where it is never news. Every rollback on
this storage fails, always, for the same reason -- it is a property of
ClickHouse, not of this call -- and it is already stated by the one-time
C<txn_begin> warning, by C<< $guard->rollback >>, and in the documentation.
Paying for it with a damaged exception on every failed bulk operation is a bad
trade, so this guard drops the refusal and keeps the error.

The C<carp> is deliberately not C<carp_once>: each unwind is a separate
incident with its own partial write, the same reason
L<DBIO::ClickHouse::Storage/txn_do> warns on every failure rather than once.

=head1 SEE ALSO

=over 4

=item * L<DBIO::ClickHouse::Storage/TRANSACTIONS> - the whole policy

=item * L<DBIO::Storage::TxnScopeGuard> - the base class

=back

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
