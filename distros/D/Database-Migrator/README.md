# NAME

Database::Migrator - A system for implementing database migrations

# VERSION

version 0.12

# DESCRIPTION

This distribution consists of a single role, [Database::Migrator::Core](https://metacpan.org/pod/Database::Migrator::Core). This
role can be consumed by classes which implement the required methods for the
role. These classes will then implement a complete database schema creation
and migration system.

# MIGRATION ARCHITECTURE

The migration system starts with a file containing the DDL (database
description language) for the full database schema. If the database doesn't
yet exist, the database will be created and this DDL will be run against it.

This DDL file _should not_ contain any sort of `CREATE DATABASE`
statement. This will be done separately before the DDL is run.

This DDL file _may_ contain DDL to create users and grant them access to the
database.

Once the database exists, the migrations are run against the database.

Each migration goes into its own directory. The directory name is the name of
the migration. Migrations are applied in sorted order. If the migrations start
with numbers, they are sorted by these numbers, otherwise they are sorted
alphabetically.

The migration directory can either contain files with SQL or Perl. If a file
ends in ".sql", the migration runner code will feed it to the appropriate
command line utility for your database.

Otherwise the file is assumed to contain Perl code. This code is expected to
return a single anonymous subroutine when `eval`ed. This subroutine will then
be called with the `Database::Migrator` object as its only argument.

Each file in a single migration's directory is run in sorted order. You can
use numeric prefixes on these files if necessary.

Once a migration has been applied, that fact is stored in the database, and
the migration will not be applied again. This is done by recording the
migration's name in a table. The name of the table is determined by your
code. I recommend something like `AppliedMigration` or `applied_migrations`,
depending on your table naming scheme.

## Migration Example

Let's assume a set of files like this:

    migrations/
     |
     |-- 01-add-foo-data/
     |     \
     |      \-- 01-create-foo-table.sql
     |      |
     |      |-- 02-insert-foo-data.pl
     |
     |-- 02-add-bar-table/
          \
           \-- add-bar-table.sql

The `01-add-foo-data/01-create-foo-table.sql` file might look like this:

    CREATE TABLE Foo (
      foo_id       INT   PRIMARY KEY AUTO_INCREMENT,
      size         INT   NOT NULL,
      description  TEXT  NOT NULL
    );

The `01-add-foo-data/02-insert-foo-data.pl` file might contain this:

    sub {
        use Text::CSV_XS;

        my $migrator = shift;

        my $csv = Text::CSV_XS->new( ... );
        my $fh = IO::File->new( ... );

        my $sql = q[INSERT INTO Foo (size, description) VALUES (?, ?)];
        my $sth = $migrator->dbh()->prepare()

        while ( my $foo = $csv->getline_hr($fh) ) {
            $sth->execute( $foo->{size}, $foo->{description} );
        }

        $sth->finish();
    }

The `02-add-bar-table/add-bar-table.sql` file would contain DDL to create the
`Bar` table.

# HOW TO USE THIS DISTRIBUTION

This distribution is not intended to be used all by itself. Instead, you will
need to start with a DBMS-specific implementation like
[Database::Migrator::mysql](https://metacpan.org/pod/Database::Migrator::mysql).

To actually run migrations, you either need to create an command line script
or subclass an implementation (or both).

The [Database::Migrator::Core](https://metacpan.org/pod/Database::Migrator::Core) role consumes the [MooseX::Getopt::Dashes](https://metacpan.org/pod/MooseX::Getopt::Dashes)
role, making it easy to create a command line script for migrations:

    #!/usr/bin/env perl

    use strict;
    use warnings;

    use Database::Migrator::mysql;

    Database::Migrator::mysql->new_with_options()->create_or_update_database();

However, all by itself, this will require quite a few command line options to
be passed. You can simplify this by subclassing the implementation class and
providing defaults for things like the migration directory and migration
table.

See the [Database::Migrator::Core](https://metacpan.org/pod/Database::Migrator::Core) documentation for more details on what
attributes you can provide defaults for.

# THE APPLIED MIGRATION TABLE

The fact that a migration has been applied is recorded in a table in the
database.

If you are creating a new schema from scratch, you can include this table. It
should contain a single text column as its primary key. This column _must_ be
named "migration".

The DDL to create this table might look like this:

    CREATE TABLE AppliedMigration (
        migration  TEXT  PRIMARY KEY
    );

## Bootstrapping This Table

If you are migrating an existing schema to use this migration system, you will
need to add this table to the schema. This can be done using the migration
system itself. If the schema already exists but the table does not exist, it
assumes that no migrations have been applied.

In this case, you must ensure that the first migration adds this table.

    migrations/
     |
     |-- 00-add-applied-migration-table
     |    \
     |     \-- create-applied-migration-table.sql
     |
     |-- 01-add-foo-data/
     |     \
     |      \-- 01-create-foo-table.sql
     |      |
     |      |-- 02-insert-foo-data.pl
     |
     |-- 02-add-bar-table/
          \
           \-- add-bar-table.sql

The `00-add-applied-migration-table/create-applied-migration-table.sql` file
would contain the DDL to create the table.

# IDEMPOTENT MIGRATIONS

Under normal operation, no migration should ever be applied twice. However, I
still strongly recommend that you make all your migrations idempotent. This is
much safer. For example, if the process applying migrations is killed, it's
possible that it will be killed after a migration is applied but before that
fact has been recorded.

# SUPPORT

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Database-Migrator or via email at
bug-database-migrator@rt.cpan.org.

Bugs may be submitted through [https://github.com/maxmind/Database-Migrator/issues](https://github.com/maxmind/Database-Migrator/issues).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Gregory Oschwald <goschwald@maxmind.com>
- Kevin Phair <phair.kevin@gmail.com>
- Olaf Alders <olaf@wundersolutions.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2012 - 2017 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
