# NAME

DBIx::Auto::Migrate - Wrap your database connections and automatically apply db migrations.

# SYNOPSIS

    package MyCompany::DB;
    
    use v5.16.3;
    use strict;
    use warnings;

    use DBIx::Auto::Migrate;

    finish_auto_migrate;

    sub create_index {
           my ($table, $column) = @_;
           if (!$table) {
                   die 'Index requires table';
           }
           if (!$column) {
                   die 'Index requires column';
           }
           return "CREATE INDEX index_${table}_${column} ON $table ($column)";
    }

    sub migrations {
           return (
                   'CREATE TABLE options (
                           id BIGSERIAL PRIMARY KEY,
                           name TEXT,
                           value TEXT,
                           UNIQUE (name)
                   )',
                   create_index(qw/options name/),
                   'CREATE TABLE users (
                           id BIGSERIAL PRIMARY KEY,
                           uuid TEXT NOT NULL,
                           username TEXT NOT NULL,
                           name TEXT NOT NULL,
                           surname TEXT NOT NULL,
                           UNIQUE(username)
                   )',
                   create_index(qw/users uuid/),
                   create_index(qw/users username/),
           );
    }

    sub dsn {
           return 'dbi:Pg:dbname=my_fancy_app_db';
    }

    sub user {
           return 'user';
    }

    sub pass {
           return 'supertopsecretdbpass';
    }

    sub extra {
           {
                   PrintError => 1,
           }
    }

And elsewhere:

    my $dbh = MyCompany::DB->connect;
    my $dbh = MyCompany::DB->connect_cached;

# DESCRIPTION

Sometimes is convenient to be able to make server or desktop programs that
use a database with the ability to be automatically have their database
upgraded in runtime.

This module comes from a snippet of code I was copying all the time between
different projects with different database engines such as PostgreSQL and SQLite,
it is time to stop copying logic like this between projects and make public
my way to apply database migrations defined in code in a extensible way.

It is only possible to migrate forward so be careful.

To check an example project that uses this code you can check [https://github.com/sergiotarxz/Perl-App-RSS-Social](https://github.com/sergiotarxz/Perl-App-RSS-Social)

# SUBS TO IMPLEMENT IN YOUR OWN DATABASE WRAPPER

## migrations

    sub migrations {
           return (
                   'CREATE TABLE options (
                           id BIGSERIAL PRIMARY KEY,
                           name TEXT,
                           value TEXT,
                           UNIQUE (name)
                   )',
                   'CREATE TABLE users (
                           id BIGSERIAL PRIMARY KEY,
                           uuid TEXT NOT NULL,
                           username TEXT NOT NULL,
                           name TEXT NOT NULL,
                           surname TEXT NOT NULL,
                           UNIQUE(username)
                   )',
           );
    }

Returns a list of migrations, creating a options table in the first migration is
obligatory since it is internally used to keep track of the current migration number.

## dsn

    sub dsn {
           return 'dbi:Pg:dbname=my_fancy_app_db';
    }

Returns a valid DSN for [DBI](https://metacpan.org/pod/DBI), you can use any logic to return this, even reading a database config file.

## user

    sub user { 'mydbuser' }

Returns a valid user for [DBI](https://metacpan.org/pod/DBI), you can use any logic to return this, even reading a database config file.

## pass

    sub pass { 'mypass' }

Returns a valid password for [DBI](https://metacpan.org/pod/DBI), you can use any logic to return this, even reading a database config file.

## extra

    sub extra {
           {
                   PrintError => 1,
           }
    }

You can optionally implement this method to pass extra options to [DBI](https://metacpan.org/pod/DBI), the
return must be a hashref or undef.

# FINALIZING THE DATABASE WRAPPER CLASS

    finish_auto_migrate();

Calling this method will ensure your class is completely ready to be used,
you can do it at any point if every prerequisite is available.

# METHODS AUTOMATICALLY AVAILABLE IN YOUR WRAPPER

## connect

    my $dbh = MyCompany::DB->connect;

Same as [DBI](https://metacpan.org/pod/DBI)::`connect` but without taking any argument.

## connect\_cached

    my $dbh = MyCompany::DB->connect_cached;

Same as [DBI](https://metacpan.org/pod/DBI)::`connect_cached` but without taking any argument.

# BUGS AND LIMITATIONS

Tries to be database independent, but I cannot really ensure it.

More testing is needed.

# AUTHOR

SERGIOXZ - Sergio Iglesias

# CONTRIBUTORS

SERGIOXZ - Sergio Iglesias

# COPYRIGHT

Copyright © Sergio Iglesias (2025)

# LICENSE

This library is free software and may be distributed under the same terms
as perl itself. See [https://dev.perl.org/licenses/](https://dev.perl.org/licenses/).
