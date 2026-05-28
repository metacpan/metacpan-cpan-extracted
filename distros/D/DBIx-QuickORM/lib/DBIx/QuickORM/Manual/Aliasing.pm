package DBIx::QuickORM::Manual::Aliasing;
use strict;
use warnings;

our $VERSION = '0.000021';

1;

__END__

=pod

=encoding UTF-8

=head1 NAME

DBIx::QuickORM::Manual::Aliasing - Using ORM names that differ from database names.

=head1 DESCRIPTION

Sometimes the name you want to use in your code is not the name the database
uses. The database might use a cryptic, abbreviated, reserved, or legacy name,
or the same logical thing might be named differently across database engines.
C<DBIx::QuickORM> lets a database, a table, and a column each carry two names:

=over 4

=item ORM name

The B<canonical, user-facing> name. It is what you write everywhere you use the
ORM: the schema DSL, query handles, where-clauses, C<order_by>, the data you
insert and update, and the keys on fetched rows. It is also the in-memory key
for row data.

=item database name (C<db_name>)

The name the B<database> uses. It is what appears in the generated SQL and in
the actual database. If you never set it, it defaults to the ORM name, so the
two are identical and there is nothing to think about.

=back

You set the database name with the C<db_name> DSL function inside the relevant
block. The ORM uses the ORM name everywhere you touch it and translates to the
database name only at the SQL boundary; results coming back from the database
are translated back to ORM names automatically.

This is part of the L<DBIx::QuickORM::Manual>.

=head1 WHAT CAN BE ALIASED

=head2 DATABASES

A database can be known by one name in the ORM and another on the server. This
is handy when the same application uses differently-named databases on
different servers or engines.

    db theapp => sub {       # name used in the ORM
        db_name 'myapp';     # actual database name on the server
        ...
    };

C<< db('theapp') >> resolves the ORM database; the connection is made against
C<myapp>.

=head2 TABLES

A table can use one name in the schema and another in the database.

    table people => sub {    # name used in the ORM
        db_name 'populace';  # actual table name in the database
        ...
    };

C<< $con->handle('people') >> queries the C<populace> table; every C<SELECT>,
C<INSERT>, C<UPDATE>, and C<DELETE> names it C<populace> in the SQL.

A B<view> behaves exactly like a table here - the same C<db_name> rule applies.

=head2 COLUMNS

A column can use one name in the ORM and another in the database. Set
C<db_name> inside the column block:

    table people => sub {
        primary_key 'people_id';

        column people_id => sub { db_name 'id'   };
        column fullname  => sub { db_name 'name' };
        column data      => sub { db_name 'json'; type 'JSON' };
    };

Now your code uses the ORM names throughout:

    my $h   = $con->handle('people');
    my $row = $h->insert({fullname => 'Bob', data => {x => 1}});

    my $bob = $h->one({fullname => 'Bob'});
    print $bob->field('fullname');
    print $bob->people_id;

while the generated SQL uses the database names (C<id>, C<name>, C<json>). The
primary key, where-clauses, C<order_by>, the returned column list, and the keys
of C<data_only> result hashes are all in ORM names.

Two columns in the same table may not map to the same database name; that is
rejected when the schema is built.

=head1 HOW IT BEHAVES

=over 4

=item Everything you write uses ORM names.

Schema definitions, handle methods, where-clauses, C<order_by>, insert/update
data, primary keys, and the keys on fetched rows (including C<data_only>) are
all ORM names.

=item Generated SQL uses database names.

The SQL builder translates ORM names to database names for every statement it
builds, and translates fetched rows back to ORM names. You never see database
names on a row.

=item Literal SQL you write is never rewritten.

If you pass a raw SQL string (for example a literal where-clause), the ORM does
not parse or rewrite it - write database names in raw SQL yourself. This is the
one place the database name leaks into your code, and only because you asked
for raw SQL.

=item The database stays canonical.

When a schema is autofilled from a live database, introspected columns are
matched to your aliased columns by their database name, so the database's
metadata (types, nullability, identity, keys) fills in while your ORM names and
overrides win.

=back

=head1 ALIASING AND JOINS

Joins translate aliased names too. Refer to columns by their ORM names,
optionally qualified with the component alias:

    my $sel = $con->handle('people')
        ->join('orders')
        ->order_by('a.fullname');

    my $rows = $sel->where({'a.fullname' => 'Bob'})->all;

The generated SQL uses the database column names under each join alias, and the
fetched rows fracture back into per-table rows keyed by ORM names. A bare
(unqualified) column resolves to the first joined table that has it; qualify it
with the alias (C<< 'a.fullname' >>) to choose a specific table when more than
one could match.

=head1 SEE ALSO

=over 4

=item L<DBIx::QuickORM::Manual>

The documentation hub.

=item L<DBIx::QuickORM::Manual::Schema>

Composing schemas, tables, and columns with the DSL.

=item L<DBIx::QuickORM>

The DSL reference, including C<db_name>.

=item L<DBIx::QuickORM::Manual::SQLBuilder>

How the SQL builder performs the ORM-to-database name translation, for anyone
writing a custom builder.

=back

=head1 SOURCE

The source code repository for DBIx::QuickORM can be found at
L<https://github.com/exodist/DBIx-QuickORM>.

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
