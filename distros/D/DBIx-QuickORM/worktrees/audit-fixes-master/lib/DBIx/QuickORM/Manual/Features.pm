package DBIx::QuickORM::Manual::Features;
use strict;
use warnings;

our $VERSION = '0.000028';

1;

__END__

=head1 NAME

DBIx::QuickORM::Manual::Features - A brief index of DBIx::QuickORM features.

=head1 DESCRIPTION

A one-line-per-feature index of what L<DBIx::QuickORM> can do, with a link to
the documentation for each. Start at L<DBIx::QuickORM::Manual::QuickStart> if
you are new; this page is for finding the feature you want quickly.

=head1 GETTING CONNECTED

=over 4

=item Quick interface

Connect to a database and work with its rows as objects with no DSL, using
C<< DBIx::QuickORM->quick(...) >>. See L<DBIx::QuickORM::Manual::QuickStart>.

=item Connection lifecycle

A memoized connection per ORM, in-place reconnect, and fork safety. See
L<DBIx::QuickORM::Manual::Connections>.

=item Credentials or connect callback

Configure a connection from a DSN/credentials or your own connect callback.
See L<DBIx::QuickORM::Manual::Connections> and L<DBIx::QuickORM/db>.

=back

=head1 DEFINING AN ORM (THE DSL)

=over 4

=item Schemas, tables, columns

Compose a schema with the DSL. See L<DBIx::QuickORM::Manual::Schema> and the
DSL reference in L<DBIx::QuickORM>.

=item Automatic schema (introspection)

Populate the schema from the live database with C<autofill>; the database is
canonical. See L<DBIx::QuickORM::Manual::Schema>.

=item Automatic row classes

Generate per-table row classes with C<autorow>. See
L<DBIx::QuickORM::Manual::Schema>.

=item Tables in their own files / custom row methods

See L<DBIx::QuickORM::Manual::Schema>.

=item Variants

Define MySQL/PostgreSQL/etc. variants of the same schema or database with
C<alt>. See L<DBIx::QuickORM::Manual::Recipes>.

=item Multiple databases and servers

Compose several databases, servers, and ORMs together. See
L<DBIx::QuickORM::Manual::Schema>.

=item Plugins

Extend the builder. See L<DBIx::QuickORM/plugin> and L<DBIx::QuickORM::Plugin>.

=back

=head1 WORKING WITH ROWS

=over 4

=item Querying

Fetch, create, update, and delete rows with handles (where/order/limit/
iterators). See L<DBIx::QuickORM::Manual::Querying>.

=item Handle as a subquery source

Use a query handle as the source of another query; it is spliced in as a
derived table, aliased with C<subquery_alias>. See
L<DBIx::QuickORM::Handle/subquery_alias>.

=item Compare and set

Update a row only while a set of guard values still match, for safe concurrent
writes. See C<cas> in L<DBIx::QuickORM::Manual::Querying>.

=item Relations

Define links (foreign keys) and follow them between rows, plus joins. See
L<DBIx::QuickORM::Manual::Relations>.

=item Transactions

Transactions, nested transactions / savepoints, callbacks, and auto-retry.
See L<DBIx::QuickORM::Manual::Transactions>.

=item Async, aside, and forked queries

Run queries asynchronously, on a side connection, or in a forked child. See
L<DBIx::QuickORM::Manual::Async>.

=item Caching / row identity

One in-memory copy of each row per connection. See
L<DBIx::QuickORM::Manual::Caching>.

=back

=head1 DATA TYPES

=over 4

=item Inflate/deflate types

Built-in JSON, UUID, and DateTime types, automatic application with
C<autotype>, and writing your own. See L<DBIx::QuickORM::Manual::Types>.

=item Affinities

How column values are treated (string/numeric/binary/boolean). See
L<DBIx::QuickORM::Manual::Concepts>.

=item Literal SQL sources

Query against a raw SQL fragment. See L<DBIx::QuickORM::LiteralSource>.

=back

=head1 DATABASE SUPPORT

=over 4

=item Dialects

SQLite, PostgreSQL, DuckDB, and MySQL (including MariaDB, Percona, and
Community). See L<DBIx::QuickORM::Manual::Concepts>.

=back

=head1 SOURCE

The source code repository for DBIx-QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM/>.

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
