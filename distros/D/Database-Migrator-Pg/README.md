# NAME

Database::Migrator::Pg - Database::Migrator implementation for Postgres

# VERSION

version 0.06

# SYNOPSIS

    package MyApp::Migrator;

    use Moose;

    extends 'Database::Migrator::Pg';

    has '+database' => (
        required => 0,
        default  => 'MyApp',
    );

# DESCRIPTION

This module provides a [Database::Migrator](https://metacpan.org/pod/Database::Migrator) implementation for Postgres. See
[Database::Migrator](https://metacpan.org/pod/Database::Migrator) and [Database::Migrator::Core](https://metacpan.org/pod/Database::Migrator::Core) for more documentation.

# ATTRIBUTES

This class adds several attributes in addition to those implemented by
[Database::Migrator::Core](https://metacpan.org/pod/Database::Migrator::Core). All of these attributes are optional.

- encoding

    The encoding of the database. This is only used when creating a new
    database.

- locale

    The locale of the database. This is only used when creating a new
    database.

- lc\_collate

    The LC\_COLLATE setting for the database. This is only used when creating a new
    database.

- lc\_ctype

    The LC\_CTYPE setting for the database. This is only used when creating a new
    database.

- owner

    The owner of the database. This is only used when creating a new
    database.

- tablespace

    The tablespace for the database. This is only used when creating a new
    database.

- template

    The template for the database. This is only used when creating a new database.

# SUPPORT

Please submit bugs to the CPAN RT system at
http://rt.cpan.org/NoAuth/Bugs.html?Dist=Database-Migrator-Pg or via email at
bug-database-migrator-pg@rt.cpan.org.

Bugs may be submitted through [https://github.com/maxmind/Database-Migrator-Pg/issues](https://github.com/maxmind/Database-Migrator-Pg/issues).

# AUTHOR

Dave Rolsky <autarch@urth.org>

# CONTRIBUTORS

- Gregory Oschwald <goschwald@maxmind.com>
- Kevin Phair <phair.kevin@gmail.com>

# COPYRIGHT AND LICENSE

This software is Copyright (c) 2013 - 2017 by MaxMind, Inc.

This is free software, licensed under:

    The Artistic License 2.0 (GPL Compatible)
