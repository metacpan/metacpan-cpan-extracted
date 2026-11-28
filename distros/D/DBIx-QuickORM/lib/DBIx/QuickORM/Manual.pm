package DBIx::QuickORM::Manual;
use strict;
use warnings;

our $VERSION = '0.000031';

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual - The DBIx::QuickORM manual.

=head1 DESCRIPTION

This is the documentation hub. Several subsystems and capabilities of the
ORM deserve their own manual page, as piecing them together from individual
module docs would be tedious.

There is also a quickstart guide for anyone who wants the quickest possible
introduction to using the ORM and many of its advanced features, all building
off a simple initial example.

=head1 FOR NEWCOMERS

This is the documentation most useful to people who are new to the ORM: the
quickstart guide, and a map for readers coming from DBIx::Class.

=head2 QUICKSTART

L<DBIx::QuickORM::Manual::Quickstart> - The quickstart introduces the
fundamentals with a simple example, then expands into advanced capabilities
from there.

=head2 DBIC

L<DBIx::QuickORM::Manual::DBIC> - Coming from DBIx::Class: Schema,
ResultSet, Row, relationships, prefetch, inflation, and transactions mapped
to the ORM, with each task side by side.

=head1 DATABASE FUNCTIONALITY

Database capabilities the ORM exposes: joins, aggregates, background queries,
transactions, foreign keys, and what differs between databases.

=head2 AGGREGATES

L<DBIx::QuickORM::Manual::Aggregates> - C<group_by>, C<having>, computed
columns and their specs, types and keys on aggregate rows.

=head2 BACKGROUND

L<DBIx::QuickORM::Manual::Background> - C<async>, C<aside>, and C<forked>
queries, one query shared by a handle's reading methods versus a new one per
C<iter>, transactions, forking, and which databases support what.

=head2 DIALECTS

L<DBIx::QuickORM::Manual::Dialects> - What differs between PostgreSQL,
MySQL, MariaDB, SQLite, and DuckDB, and what it means for your code.

=head2 FOREIGNKEYS

L<DBIx::QuickORM::Manual::ForeignKeys> - C<follow_fk>: direction, C<link>,
single and multi handles, NULL keys, and following from aggregate and join
rows. Also C<insert_fk> and C<insert_many_fk> for inserting linked rows.

=head2 JOINS

L<DBIx::QuickORM::Manual::Joins> - Inner and left joins, aliases, self
joins, joining from a joined table, and the flat join rows.

=head2 TRANSACTIONS

L<DBIx::QuickORM::Manual::Transactions> - Block and object forms,
savepoints, C<retry>, the rows you hold across a transaction, and writing a
row read before it began.

=head1 ORM CONCEPTS

Things the ORM provides and manages itself, which are not a direct map to a
database feature.

=head2 BULKINSERT

L<DBIx::QuickORM::Manual::BulkInsert> - C<insert_many> and C<insert_many_fk>:
the rows it returns, just the count, all-or-nothing batches, and MySQL
without C<RETURNING>.

=head2 CACHING

L<DBIx::QuickORM::Manual::Caching> - The one canonical copy of each row: why
writes need it, C<enforce_canon>, reads from the canonical copy,
C<retain_cache>, C<clear_cache>, and when to care.

=head2 ERRORS

L<DBIx::QuickORM::Manual::Errors> - Database errors and their kinds, the
ORM's own errors, and retrying after deadlocks, serialization failures, and
lock timeouts.

=head2 KEYS

L<DBIx::QuickORM::Manual::Keys> - Primary key forms, typed keys that match
in any form, the C<format> hint, and generated keys.

=head2 VALUES

L<DBIx::QuickORM::Manual::Values> - Deflation, inflation, and the C<raw>,
C<inflated>, C<binary>, and C<sql> markers: when and why.

=head1 CUSTOMIZING THE ORM

How to plug your own code into the ORM: ORM classes, row classes, and types.

=head2 CLASSES

L<DBIx::QuickORM::Manual::Classes> - The C<orm>, C<table>, and C<row>
blocks: an ORM defined as classes, with C<override>, omitted and default
fields, typed fields with hints, a renamed keyword, C<no>, and precedence.

=head2 ROWCLASSES

L<DBIx::QuickORM::Manual::RowClasses> - Row classes for one table, every
table (or each table by name), or one query. Also plain hashrefs, rows not in
the database, consuming the role, and what the ORM needs of a row class.

=head2 TYPES

L<DBIx::QuickORM::Manual::Types> - Writing a type: C<inflate> and
C<deflate>, claims for C<autotype>, canonical keys, cached values, and
registering it, with a Money and a Tags type.

=cut

1;

__END__

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

=head1 MAINTAINERS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 AUTHORS

=over 4

=item Chad Granum E<lt>exodist7@gmail.comE<gt>

=back

=head1 COPYRIGHT

Copyright Chad Granum E<lt>exodist7@gmail.comE<gt>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See L<https://dev.perl.org/licenses/>

=cut
