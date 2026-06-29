package DBIx::QuickORM::Manual;
use strict;
use warnings;

our $VERSION = '0.000025';

1;

__END__

=head1 NAME

DBIx::QuickORM::Manual - Documentation hub for L<DBIx::QuickORM>.

=head1 DESCRIPTION

This is the documentation hub for L<DBIx::QuickORM>. It links the tutorials,
guides, and reference docs. If you are new, start with
L<DBIx::QuickORM::Manual::QuickStart>.

=head1 GETTING STARTED

=over 4

=item L<DBIx::QuickORM::Manual::QuickStart>

Connect to a database, get rows as objects, insert, follow relations, and run
a transaction in just a few lines using the C<quick()> interface. Start here.

=item L<DBIx::QuickORM::Manual::Concepts>

The key concepts (dialects, schema, affinity, and more) that make the rest of
the system easier to work with.

=item L<DBIx::QuickORM::Manual::Features>

A brief index of every feature with links to where each is documented.

=item L<DBIx::QuickORM::Manual::DBIxClass>

Coming from L<DBIx::Class>? This maps its concepts (ResultSet, Result,
relationships, ...) to their DBIx::QuickORM equivalents.

=back

=head1 GUIDES

=over 4

=item L<DBIx::QuickORM::Manual::Schema>

Use the DSL to compose schemas, tables, columns, and whole ORMs - including
defining tables in their own files and advanced composition.

=item L<DBIx::QuickORM::Manual::Aliasing>

Give a database, table, or column a different name in the ORM than it has in
the database.

=item L<DBIx::QuickORM::Manual::Querying>

Fetch, create, update, and delete rows with handles: where clauses, ordering,
limiting, iterators, and more.

=item L<DBIx::QuickORM::Manual::Relations>

Define links (foreign keys) and follow them between rows, plus joins.

=item L<DBIx::QuickORM::Manual::Transactions>

Transactions, nested transactions and savepoints, callbacks, and automatic
retry.

=item L<DBIx::QuickORM::Manual::Async>

Asynchronous, aside, and forked queries, and other multi-connection work.

=item L<DBIx::QuickORM::Manual::Types>

Inflating and deflating column values (JSON, UUID, ...) and writing your own
type classes.

=item L<DBIx::QuickORM::Manual::Caching>

How the per-connection row cache keeps one copy of each row in memory.

=item L<DBIx::QuickORM::Manual::Connections>

The connection lifecycle: reconnecting, fork safety, and the ORM's connection.

=item L<DBIx::QuickORM::Manual::SQLBuilder>

Replace the SQL builder: the builder contract, the statement/bind structure,
how the SQL::Abstract builder works, and how to write your own.

=item L<DBIx::QuickORM::Manual::Recipes>

A hub of focused recipes for specific tasks.

=back

=head1 KEY MODULE DOCS

=over 4

=item L<DBIx::QuickORM>

Exports the DSL for defining an ORM, and documents each DSL function.

=item L<DBIx::QuickORM::Connection>

A connection to the database; where transactions are controlled and handles
are made.

=item L<DBIx::QuickORM::Handle>

The primary interface for fetching, creating, and modifying rows.

=back

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM/>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist@cpan.orgE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
