package DBIO::Async::TransactionContext;
# ABSTRACT: Pinned-connection context for dbio-async (future_io) transactions

use strict;
use warnings;
use base 'DBIO::Storage::Async::TransactionContext';


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::Async::TransactionContext - Pinned-connection context for dbio-async (future_io) transactions

=head1 VERSION

version 0.900001

=head1 DESCRIPTION

The transaction context for the C<future_io> backend. A thin subclass of the
loop-agnostic L<DBIO::Storage::Async::TransactionContext> (ADR 0030 §4): all
behaviour -- pinning every CRUD operation to the single connection that
C<BEGIN>/C<COMMIT>/C<ROLLBACK> ran on, routed through the storage's shared
C<_run_crud_pinned> builder -- is inherited unchanged.

It exists as a named class because L<DBIO::Async::Storage/_txn_context_class>
resolves to it and drivers / tests refer to it by name.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
