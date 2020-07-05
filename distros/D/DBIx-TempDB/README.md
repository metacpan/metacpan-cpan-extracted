# NAME

DBIx::TempDB - Create a temporary database

# VERSION

0.16

# SYNOPSIS

    use Test::More;
    use DBIx::TempDB;
    use DBI;

    # provide credentials with environment variables
    plan skip_all => 'TEST_PG_DSN=postgresql://postgres@localhost' unless $ENV{TEST_PG_DSN};

    # create a temp database
    my $tmpdb = DBIx::TempDB->new($ENV{TEST_PG_DSN});

    # print complete url to db server with database name
    diag $tmpdb->url;

    # useful for reading in fixtures
    $tmpdb->execute("create table users (name text)");
    $tmpdb->execute_file("path/to/file.sql");

    # connect to the temp database
    my $db = DBI->connect($tmpdb->dsn);

    # run tests...

    done_testing;
    # database is cleaned up when test exit

# DESCRIPTION

[DBIx::TempDB](https://metacpan.org/pod/DBIx%3A%3ATempDB) is a module which allows you to create a temporary database,
which only lives as long as your process is alive. This can be very
convenient when you want to run tests in parallel, without messing up the
state between tests.

This module currently support PostgreSQL, MySQL and SQLite by installing the optional
[DBD::Pg](https://metacpan.org/pod/DBD%3A%3APg), [DBD::mysql](https://metacpan.org/pod/DBD%3A%3Amysql) and/or [DBD::SQLite](https://metacpan.org/pod/DBD%3A%3ASQLite) modules.

Please create an [issue](https://github.com/jhthorsen/dbix-tempdb/issues)
or pull request for more backend support.

# CAVEAT

Creating a database is easy, but making sure it gets clean up when your
process exit is a totally different ball game. This means that
[DBIx::TempDB](https://metacpan.org/pod/DBIx%3A%3ATempDB) might fill up your server with random databases, unless
you choose the right "drop strategy". Have a look at the ["drop\_from\_child"](#drop_from_child)
parameter you can give to ["new"](#new) and test the different values and select
the one that works for you.

# ENVIRONMENT VARIABLES

## DBIX\_TEMP\_DB\_KEEP\_DATABASE

Setting this variable will disable the core feature in this module:
A unique database will be created, but it will not get dropped/deleted.

## DBIX\_TEMP\_DB\_URL

This variable is set by ["create\_database"](#create_database) and contains the complete
URL pointing to the temporary database.

Note that calling ["create\_database"](#create_database) on different instances of
[DBIx::TempDB](https://metacpan.org/pod/DBIx%3A%3ATempDB) will overwrite `DBIX_TEMP_DB_URL`.

# METHODS

## create\_database

    $tmpdb = $tmpdb->create_database;

This method will create a temp database for the current process. Calling this
method multiple times will simply do nothing. This method is normally
automatically called by ["new"](#new).

The database name generate is defined by the ["template"](#template) parameter passed to
["new"](#new), but normalization will be done to make it work for the given database.

## drop\_databases

    $tmpdb->drop_databases;
    $tmpdb->drop_databases({tmpdb => "include"});
    $tmpdb->drop_databases({tmpdb => "only"});
    $tmpdb->drop_databases({name => "some_database_name"});

Used to drop either sibling databases (default), sibling databases and the
current database or a given database by name.

## dsn

    ($dsn, $user, $pass, $attrs) = $tmpdb->dsn;

Will parse ["url"](#url) and return a list of arguments suitable for ["connect" in DBI](https://metacpan.org/pod/DBI#connect).

Note that this method cannot be called as an object method before
["create\_database"](#create_database) is called.

See also ["dsn\_for" in DBIx::TempDB::Util](https://metacpan.org/pod/DBIx%3A%3ATempDB%3A%3AUtil#dsn_for).

## execute

    $tmpdb = $tmpdb->execute(@sql);

This method will execute a list of `@sql` statements in the temporary
SQL server.

## execute\_file

    $tmpdb = $tmpdb->execute_file("relative/to/executable.sql");
    $tmpdb = $tmpdb->execute_file("/absolute/path/stmt.sql");

This method will read the contents of a file and execute the SQL statements
in the temporary server.

This method is a thin wrapper around ["execute"](#execute).

## new

    $tmpdb = DBIx::TempDB->new($url, %args);
    $tmpdb = DBIx::TempDB->new("mysql://127.0.0.1");
    $tmpdb = DBIx::TempDB->new("postgresql://postgres@db.example.com");
    $tmpdb = DBIx::TempDB->new("sqlite:");

Creates a new object after checking the `$url` is valid. `%args` can be:

- auto\_create

    ["create\_database"](#create_database) will be called automatically, unless `auto_create` is
    set to a false value.

- drop\_from\_child

    Setting "drop\_from\_child" to a true value will create a child process which
    will remove the temporary database, when the main process ends. There are two
    possible values:

    `drop_from_child=1` (the default) will create a child process which monitor
    the [DBIx::TempDB](https://metacpan.org/pod/DBIx%3A%3ATempDB) object with a pipe. This will then DROP the temp database
    if the object goes out of scope or if the process ends.

    `drop_from_child=2` will create a child process detached from the parent,
    which monitor the parent with `kill(0, $parent)`.

    The double fork code is based on a paste contributed by
    [Easy Connect AS](http://easyconnect.no), Knut Arne Bjørndal.

    See also ["on\_process\_end" in DBIx::TempDB::Util](https://metacpan.org/pod/DBIx%3A%3ATempDB%3A%3AUtil#on_process_end).

- template

    Customize the generated database name. Default template is "tmp\_%U\_%X\_%H%i".
    Possible variables to expand are:

        %i = The number of tries if tries are higher than 0. Example: "_3"
        %H = Hostname
        %P = Process ID ($$)
        %T = Process start time ($^T)
        %U = UID of current user
        %X = Basename of executable

    The default is subject to change!

## url

    $url = $tmpdb->url;

Returns the input URL as [URI::db](https://metacpan.org/pod/URI%3A%3Adb) compatible object. This URL will have
the [dbname](https://metacpan.org/pod/URI%3A%3Adb#dbname) part set to the database from ["create\_database"](#create_database),
but not _until_ after ["create\_database"](#create_database) is actually called.

The URL returned can be passed directly to modules such as [Mojo::Pg](https://metacpan.org/pod/Mojo%3A%3APg)
and [Mojo::mysql](https://metacpan.org/pod/Mojo%3A%3Amysql).

# COPYRIGHT AND LICENSE

Copyright (C) 2015, Jan Henning Thorsen

This program is free software, you can redistribute it and/or modify it under
the terms of the Artistic License version 2.0.

# AUTHOR

Jan Henning Thorsen - `jhthorsen@cpan.org`
