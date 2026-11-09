package DBIO::PostgreSQL::EV::TransactionContext;
# ABSTRACT: Pinned connection context for an async PostgreSQL transaction

use strict;
use warnings;

our $VERSION = '0.900004';

use base 'DBIO::Storage::Async::TransactionContext';


sub txn_pg { $_[0]->txn_conn }

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIO::PostgreSQL::EV::TransactionContext - Pinned connection context for an async PostgreSQL transaction

=head1 VERSION

version 0.900004

=head1 DESCRIPTION

The pinned-connection context L<DBIO::PostgreSQL::EV::Storage> hands to a
C<txn_do_async> coderef -- see L<DBIO::PostgreSQL::EV::Storage/_txn_context_class>.

Everything it does is B<inherited> from
L<DBIO::Storage::Async::TransactionContext>, the generic context core ships
since ADR 0030 §4: C<storage>, C<txn_conn>, C<pool>, C<in_txn>, the
non-releasing C<_query_async>, the five C<*_async> CRUD methods pinned through
core's C<_run_crud_pinned> (L<DBIO::Storage::Async/_run_crud>) and their
blocking C<< ->get >> siblings, the C<sql_maker> / C<debug> / C<pipeline> /
C<txn_do_async> delegations, and C<_context_active> / C<_invalidate> (ADR
0045), which context-bound L<DBIO::ResultSet> / L<DBIO::Row> /
L<DBIO::ResultSetColumn> C<*_async> ops consult before routing onto the
context.

The blocking siblings wait through L<DBIO::PostgreSQL::EV::Future/await>, and
the coderef that calls them runs inside the C<BEGIN>'s callback on the pinned
connection. Every one of them sends its statement on that connection, and a
wait for it there would make L<EV::Pg> hand the result to the C<BEGIN>'s
callback and spin, so each is refused: it dies with I<"Blocking wait refused:
...">, which fails the coderef. Use the C<*_async> methods in the coderef and
chain with C<then>.

A blocking call on the B<storage> in the coderef -- C<< $storage->select >>
where C<< $ctx->select_async >> was meant -- does not run on the transaction's
connection: it takes another one from the pool, and the transaction keeps its
own until the coderef has returned. With C<< pool_size => 1 >>, or with every
connection held by a callback the call is nested in, no connection can come
back while it waits, and it is refused the same way: it dies with I<"Blocking
wait refused: ...">, is never sent, and the transaction is rolled back
(L<DBIO::PostgreSQL::EV::Future/await>).

The pinned connection runs its statements one at a time, in the order they
were issued (L<DBIO::PostgreSQL::EV::Storage/_query_async_pinned>). A
coderef that dies -- or is refused a blocking wait -- while one of its
statements is still running therefore rolls back cleanly: core's C<ROLLBACK>
goes out once that statement has its result, and the connection goes back to
the pool IDLE. Several C<*_async> calls on the context may be issued without
waiting for each other; they run one after the other.

Every statement the context hands out counts, awaited or not: core waits for
all of them before C<COMMIT>, and when one failed it sends C<ROLLBACK> instead
and the transaction fails with that statement's error -- also when the coderef
caught the failure (L<DBIO::Storage::Async/txn_do_async>). A
statement the context never saw -- one in a C<pipeline> batch whose coderef
dropped its error, or one sent on L</txn_pg> past the context -- still aborts
the transaction on the server, and PostgreSQL answers the C<COMMIT> with
C<ROLLBACK>. The transport reports that
(L<DBIO::PostgreSQL::EV::Storage/_txn_commit_rolled_back>), and the transaction
fails with I<"COMMIT was answered with ROLLBACK"> instead of resolving as if it
had committed. From the moment C<COMMIT> or C<ROLLBACK> is sent the
context refuses every further statement: it would run outside the
transaction.

This class adds exactly one thing: the L</txn_pg> compatibility alias below.
The pinning policy this context implements is recorded in ADR 0002; the
duplicated-context half of that ADR is superseded by core ADR 0030 §4.

The pinned connection is passed to C<new> under the core constructor key
C<txn_conn>, which L<DBIO::PostgreSQL::EV::Storage/_txn_conn_accessor> names and
core's C<txn_do_async> builds the context with. The pre-k32 key C<pg> is gone:
the constructor dies without C<txn_conn>.

=head1 ATTRIBUTES

=head2 txn_pg

  my $pg = $ctx->txn_pg;

Compatibility alias for the inherited
L<DBIO::Storage::Async::TransactionContext/txn_conn>: the pinned L<EV::Pg>
connection handle for the duration of this transaction. It is the name this
driver's own context carried before it became a subclass of the core one, kept
because it says B<which> kind of handle is pinned -- and because it is load
bearing: C<t/21-deploy-async-live.t> reaches for it to drive
C<_execute_ddl_async> on the pinned connection. C<txn_conn> is the name core's
own code reaches for -- C<deploy_async>'s transactional branch among them -- so
both answer the same handle.

=head1 AUTHOR

DBIO Authors

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2026 DBIO Authors

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
