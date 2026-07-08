package DBIx::QuickORM::Manual::Schema;
use strict;
use warnings;

our $VERSION = '0.000028';

1;

__END__

=head1 NAME

DBIx::QuickORM::Manual::Schema - Build your schema with the DSL.

=head1 DESCRIPTION

This guide walks through using the L<DBIx::QuickORM> DSL to compose schemas,
tables, columns, and whole ORMs - from a single self-contained ORM package up
to more advanced compositions where servers, databases, and schemas are defined
separately and combined into multiple ORMs.

This page focuses on B<how to put the pieces together>. For the
function-by-function reference (every DSL builder, what it accepts, and what it
returns) see L<DBIx::QuickORM>.

If you have not yet, start with L<DBIx::QuickORM::Manual::QuickStart> for a
fast introduction, and L<DBIx::QuickORM::Manual::Concepts> for the key concepts
(dialects, schema, affinity, ...) that the rest of this guide assumes.

=head1 YOUR ORM PACKAGE

The simplest layout is a single package that uses L<DBIx::QuickORM>, defines an
C<orm> containing a C<db> (the connection) and a C<schema> (the tables), and
exports an C<orm()> accessor for your app code.

There are two ways to populate the schema: define it by hand (manual schema) or
let DBIx::QuickORM introspect the live database and fill it in for you
(automagic schema).

=head2 MANUAL SCHEMA

Define every table and column yourself. This gives you complete control and
does not require the database to exist when the schema is defined.

    package My::ORM;
    use DBIx::QuickORM;

    # Define your ORM
    orm my_orm => sub {
        # Define your object
        db my_db => sub {
            dialect 'PostgreSQL'; # Or MySQL, MariaDB, SQLite
            host 'mydb.mydomain.com';
            port 1234;

            # Best not to hardcode these, read them from a secure place and pass them in here.
            user $USER;
            pass $PASS;
        };

        # Define your schema
        schema myschema => sub {
            table my_table => sub {
                column id => sub {
                    identity;
                    primary_key;
                    not_null;
                };

                column name => sub {
                    type \'VARCHAR(128)';    # Exact SQL for the type
                    affinity 'string';       # required if other information does not make it obvious to DBIx::QuickORM
                    unique;
                    not_null;
                };

                column added => sub {
                    type 'Stamp';            # Short for DBIx::QuickORM::Type::Stamp
                    not_null;

                    # Exact SQL to use if DBIx::QuickORM generates the table SQL
                    default \'NOW()';

                    # Perl code to generate a default value when rows are created by DBIx::QuickORM
                    default sub { ... };
                };
            };
        };
    };

=head2 AUTOMAGIC SCHEMA

Let DBIx::QuickORM introspect the live database and fill the schema in for you.
The C<autofill> builder reads columns, indexes, primary keys, and so on from the
connected database; the rest of the builders inside it tune that process
(automatic type handling, skipping tables, generating row classes, and custom
naming).

    package My::ORM;
    use DBIx::QuickORM;

    # Define your ORM
    orm my_orm => sub {
        # Define your object
        db my_db => sub {
            dialect 'PostgreSQL'; # Or MySQL, MariaDB, SQLite
            host 'mydb.mydomain.com';
            port 1234;

            # Best not to hardcode these, read them from a secure place and pass them in here.
            user $USER;
            pass $PASS;
        };

        # Define your schema
        schema myschema => sub {
            # The class name is optional, the one shown here is the default
            autofill 'DBIx::QuickORM::Schema::Autofill' => sub {
                autotype 'UUID';    # Automatically handle UUID fields
                autotype 'JSON';    # Automatically handle JSON fields

                # Do not autofill these tables
                autoskip table => qw/foo bar baz/;

                # Will automatically create My::Row::Table classes for you with
                # accessors for links and fields If My::Table::Row can be
                # loaded (IE My/Row/Table.pm exists) it will load it then
                # autofill anything missing.
                autorow 'My::Row';

                # autorow can also take a subref that accepts a table name as
                # input and provides the class name for it, here is the default
                # one used if none if provided:
                autorow 'My::Row' => sub {
                    my $name = shift;
                    my @parts = split /_/, $name;
                    return join '' => map { ucfirst(lc($_)) } @parts;
                };

                # You can provide custom names for tables. It will still refer
                # to the correct name in queries, but will provide an alternate
                # name for the orm to use in perl code.
                autoname table => sub {
                    my %params = @_;
                    my $table_hash = $params{table}; # unblessed ref that will become a table
                    my $name = $params{name}; # The name of the table
                    ...
                    return $new_name;
                };

                # You can provide custom names for link (foreign key) accessors when using autorow
                autoname link_accessor => sub {
                    my %params = @_;
                    my $link = $params{link};

                    return "obtain_" . $link->other_table if $params{link}->unique;
                    return "select_" . $link->other_table . "s";
                };

                # You can provide custom names for field accessors when using autorow
                autoname field_accessor => sub {
                    my %params = @_;
                    return "get_$params{name}";
                };
            };
        };
    };

=head1 DEFINE TABLES IN THEIR OWN PACKAGES/FILES

If you have many tables, or want each to have a custom row class (custom
methods for items returned by tables), then you probably want to define tables
in their own files.

When you follow this example you create the table C<My::ORM::Table::Foo>. The
package will automatically subclass L<DBIx::QuickORM::Row> unless you use
C<row_class()> to set an alternative base.

Any methods added in the file will be callable on the rows returned when
querying this table.

First create F<My/ORM/Table/Foo.pm>:

    package My::ORM::Table::Foo;
    use DBIx::QuickORM type => 'table';

    # Calling this will define the table. It will also:
    #  * Remove all functions imported from DBIx::QuickORM
    #  * Set the base class to DBIx::QuickORM::Row, or to whatever class you specify with 'row_class'.
    table foo => sub {
        column a => sub { ... };
        column b => sub { ... };
        column c => sub { ... };

        ....

        # This is the default, but you can change it to set an alternate base class.
        row_class 'DBIx::QuickORM::Row';
    };

    sub custom_row_method {
        my $self = shift;
        ...
    }

Then in your ORM package:

    package My::ORM;

    schema my_schema => sub {
        table 'My::ORM::Table::Foo'; # Bring in the table
    };

Or if you have many tables and want to load all the tables under C<My::ORM::Table::> at once:

    schema my_schema => sub {
        tables 'My::ORM::Table';
    };

=head1 ADVANCED COMPOSING

You can define databases and schemas on their own and create multiple ORMs that
combine them. You can also define a C<server> that has multiple databases.

    package My::ORM;
    use DBIx::QuickORM;

    server pg => sub {
        dialect 'PostgreSQL';
        host 'pg.myapp.com';
        user $USER;
        pass $PASS;

        db 'myapp';       # Points at the 'myapp' database on this db server
        db 'otherapp';    # Points at the 'otherapp' database on this db server
    };

    schema myapp => sub { ... };
    schema otherapp => sub { ... };

    orm myapp => sub {
        db 'pg.myapp';
        schema 'myapp';
    };

    orm otherapp => sub {
        db 'pg.otherapp';
        schema 'otherapp';
    };

Then to use them:

    use My::ORM;

    my $myapp    = orm('myapp');
    my $otherapp = orm('otherapp');

Also note that C<< alt(variant => sub { ... }) >> can be used in any of the
above builders to create MySQL/PostgreSQL/etc. variants on the databases and
schemas. Then access them like:

    my $myapp_pgsql = orm('myapp:pgsql');
    my $myapp_mysql = orm('myapp:myql');

The MySQL/PostgreSQL variant recipe is covered in full in
L<DBIx::QuickORM::Manual::Recipes>.

=head1 MORE RECIPES

This guide does not cover every composition trick. For defining the database
connection separately and attaching it later, renaming the exported C<orm()>
accessor, supporting nearly-identical MySQL and PostgreSQL databases from one
codebase, and other focused tasks, see L<DBIx::QuickORM::Manual::Recipes>.

=head1 SEE ALSO

=over 4

=item L<DBIx::QuickORM>

The DSL reference: every builder function documented one by one.

=item L<DBIx::QuickORM::Manual::QuickStart>

Connect, query, and get going in a few lines.

=item L<DBIx::QuickORM::Manual::Concepts>

Dialects, schema, affinity, and the other key concepts.

=item L<DBIx::QuickORM::Manual::Relations>

Define links (foreign keys) and follow them between rows.

=item L<DBIx::QuickORM::Manual::Recipes>

Focused recipes for specific composition tasks.

=item L<DBIx::QuickORM::Manual>

The documentation hub linking every tutorial, guide, and reference.

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
