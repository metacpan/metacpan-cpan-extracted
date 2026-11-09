package DBIO::MySQL::EV::TransactionContext;
# ABSTRACT: Pinned connection context for an async MySQL/MariaDB transaction

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Storage::Async::TransactionContext';


sub txn_mdb { $_[0]->txn_conn }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::MySQL::EV::TransactionContext - Pinned connection context for an async MySQL/MariaDB transaction

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The pinned-connection context L<DBIO::MySQL::EV::Storage> hands to a
C<txn_do_async> coderef -- see L<DBIO::MySQL::EV::Storage/_txn_context_class>.

Everything it does is B<inherited> from
L<DBIO::Storage::Async::TransactionContext>, the generic context core ships
since ADR 0030 §4: C<storage>, C<txn_conn>, C<pool>, C<in_txn>, the
non-releasing C<_query_async>, the five C<*_async> CRUD methods pinned through
L<DBIO::MySQL::EV::Storage/_run_crud_pinned> and their blocking C<< ->get >>
siblings, the C<sql_maker> / C<debug> delegations, C<pipeline> (runs on the
pinned C<txn_conn> in core -- here it returns a failed Future, because
this transport has no pipeline seam, ADR 0009), C<txn_do_async> (refuses a
nested transaction), and C<_context_active> / C<_invalidate>
(ADR 0045), which
context-bound L<DBIO::ResultSet> / L<DBIO::Row> / L<DBIO::ResultSetColumn>
C<*_async> ops consult before routing onto the context.

The blocking siblings wait through L<DBIO::MySQL::EV::Future/await>. The
coderef that calls them runs from the idle watcher that settles the C<BEGIN>'s
Future, outside every callback of the pinned connection, so a statement it sends
-- with or without bind values -- goes out at once and a blocking call waiting
for it returns: C<< $ctx->select >> without a C<WHERE> works in the coderef,
inside the transaction (until then such a call was refused).

A blocking call on the B<storage> in the coderef -- C<< $storage->select >>
where C<< $ctx->select_async >> was meant -- does not run on this context's
connection but on another one from the pool. When the callbacks it runs inside
hold every connection of the pool, it is refused the same way and does not run
(L<DBIO::MySQL::EV::Future/await>).

This class adds exactly one thing: the L</txn_mdb> compatibility alias below.
The pinning policy this context implements is recorded in ADR 0002; the
duplicated-context half of that ADR is superseded by core ADR 0030 §4.

The pinned connection is passed to C<new> under the core constructor key
C<txn_conn>, which L<DBIO::MySQL::EV::Storage/_txn_conn_accessor> names and
core's C<txn_do_async> builds the context with. The pre-k31 key C<mdb> is gone:
the constructor dies without C<txn_conn>.

=head1 ATTRIBUTES

=head2 txn_mdb

  my $mdb = $ctx->txn_mdb;

Compatibility alias for the inherited
L<DBIO::Storage::Async::TransactionContext/txn_conn>: the pinned
L<EV::MariaDB> connection handle for the duration of this transaction. It is
the name this driver's own context carried before it became a subclass of the
core one, kept because it says B<which> kind of handle is pinned. C<txn_conn>
is the name core's own code reaches for -- C<deploy_async>'s transactional
branch among them -- so both answer the same handle.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
