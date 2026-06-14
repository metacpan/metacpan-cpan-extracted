package DBIx::QuickORM::Manual::Recipes;
use strict;
use warnings;

our $VERSION = '0.000023';

1;

__END__

=head1 NAME

DBIx::QuickORM::Manual::Recipes - A hub of focused, task-oriented recipes for L<DBIx::QuickORM>.

=head1 DESCRIPTION

This is a hub of focused, task-oriented recipes for L<DBIx::QuickORM>. Each
recipe below solves a specific problem; for broader topics see the guides
linked under L</SEE ALSO>.

=head2 DEFINE DB LATER

In some cases you may want to define your orm/schema before you have your
database credentials. Then you want to add the database later in an app/script
bootstrap process.

Schema:

    package My::Schema;
    use DBIx::QuickORM;

    orm MyORM => sub {
        autofill;
    };

Bootstrap process:

    package My::Bootstrap;
    use DBIx::QuickORM only => [qw/db db_name host port user pass/];
    use My::Schema;

    sub import {
        # Get the orm (the `orm => ...` param is required to prevent it from attempting a connection now)
        my $orm = qorm(orm => 'MyORM');

        return if $orm->db; # Already bootstrapped

        my %db_params = decrypt_creds();

        # Define the DB
        my $db = db {
            db_name 'quickdb';
            host $db_params{host};
            port $db_params{port};
            user $db_params{user};
            pass $db_params{pass};
        };

        # Set the db on the ORM:
        $orm->db($db);
    }

Your app:

    package My::App;

    # Get the qorm() subroutine
    use My::Schema;

    # This will do the db bootstrap
    use My::Bootstrap;

    # Connect to the database with the ORM
    my $con = qorm('MyORM');

=head2 SCHEMA WITH NO DATABASE, ADD A CONNECT CALLBACK LATER

Like L</"DEFINE DB LATER">, but instead of credentials you attach your own
C<connect> callback (any sub that returns a fresh L<DBI> handle) right before
you need the connection. This is handy when the connection comes from
something you build yourself - a pool, a tunnel, an already-open handle, and
so on.

Define the schema with no database at all:

    package My::Schema;
    use DBIx::QuickORM;

    orm MyORM => sub {
        # No db here - just the schema.
        schema my_schema => sub {
            table users => sub {
                column id   => sub { primary_key; identity; not_null };
                column name => sub { type \'VARCHAR(128)'; affinity 'string'; not_null };
            };
        };
    };

Then, just before you get a connection, build a database from a C<connect>
callback and set it on the ORM:

    use DBIx::QuickORM only => [qw/db dialect connect/];
    use My::Schema;

    # 'orm => ...' returns the ORM without trying to connect yet.
    my $orm = qorm(orm => 'MyORM');

    $orm->db(db {
        dialect 'PostgreSQL';                 # the dialect is still required
        connect sub { $pool->checkout_dbh };  # any sub returning a new DBI handle
    });

    # Now connect:
    my $con = $orm->connection;

The C<connect> callback must hand back a B<new> handle each time it is called
and must not cache or reuse one; the connection manages the handle's lifecycle
(see L<DBIx::QuickORM::Manual::Connections>).

=head2 RENAMING EXPORTS

When importing L<DBIx::QuickORM> you can provide
C<< rename => { name => new_name } >> mapping to rename exports.

    package My::ORM;
    use DBIx::QuickORM rename => {
        pass  => 'password',
        user  => 'username',
        table => 'build_table',
    };

B<Note> If you do not want to bring in the C<import()> method that normally
gets produced, you can also add C<< type => 'porcelain' >>.

    use DBIx::QuickORM type => 'porcelain';

Really any 'type' other than 'orm' and undef (which becomes 'orm' by default)
will work to prevent C<import()> from being exported to your namespace.

=head2 APP THAT CAN USE NEARLY IDENTICAL MYSQL AND POSTGRESQL DATABASES

Lets say you have a test app that can connect to nearly identical MySQL or
PostgreSQL databases. The schemas are the same apart from minor differences required by
the database engine. You want to make it easy to access whichever one you want,
or even both.

    package My::ORM;
    use DBIx::QuickORM;

    orm my_orm => sub {
        db myapp => sub {
            alt mysql => sub {
                dialect 'MySQL';
                driver '+DBD::mysql';     # Or 'mysql', '+DBD::MariaDB', 'MariaDB'
                host 'mysql.myapp.com';
                user $MYSQL_USER;
                pass $MYSQL_PASS;
                db_name 'myapp_mysql';    # In MySQL the db is named myapp_mysql
            };
            alt pgsql => sub {
                dialect 'PostgreSQL';
                host 'pgsql.myapp.com';
                user $PGSQL_USER;
                pass $PGSQL_PASS;
                db_name 'myapp_pgsql';    # In PostgreSQL the db is named myapp_pgsql
            };
        };

        schema my_schema => sub {
            table same_on_both => sub { ... };

            # Give the name 'differs' that can always be used to refer to this table, despite each db giving it a different name
            table differs => sub {
                # Each db has a different name for the table
                alt mysql => sub { db_name 'differs_mysql' };
                alt pgsql => sub { db_name 'differs_pgsql' };

                # Name for the column that the code can always use regardless of which db is in use
                column foo => sub {
                    # Each db also names this column differently
                    alt mysql => sub { db_name 'foo_mysql' };
                    alt pgsql => sub { db_name 'foo_pgsql' };
                    ...;
                };

                ...;
            };
        };
    };

Then to use it:

    use My::ORM;

    my $orm_mysql = orm('my_orm:mysql');
    my $orm_pgsql = orm('my_orm:pgsql');

Each ORM object is a complete and self-contained ORM with its own caching and
db connection. One connects to MySQL and one connects to PostgreSQL. Both can
ask for rows in the C<differs> table, on MySQL it will query the
C<differs_mysql>, on PostgreSQL it will query the C<differs_pgsql> table. You can
use them both at the same time in the same code.

=head1 MORE RECIPES

Some recipes live with the guide that owns the topic:

=over 4

=item Define tables in their own packages/files

See L<DBIx::QuickORM::Manual::Schema>.

=item Advanced composing (standalone databases and schemas, servers with
multiple databases, combining them into multiple ORMs)

See L<DBIx::QuickORM::Manual::Schema>.

=back

=head1 SEE ALSO

=over 4

=item L<DBIx::QuickORM::Manual>

The documentation hub linking every tutorial, guide, and reference doc.

=item L<DBIx::QuickORM::Manual::Schema>

Compose schemas, tables, columns, and whole ORMs - including defining tables in
their own files and advanced composition.

=item L<DBIx::QuickORM::Manual::Querying>

Fetch, create, update, and delete rows with handles.

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
