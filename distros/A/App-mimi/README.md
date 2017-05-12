# NAME

mimi - dbi migrations

# SYNOPSIS

    mimi check   --dsn=<dsn>
    mimi migrate --dsn=<dsn> --schema=<directory> [--verbose] [--dry-run]
    mimi setup   --dsn=<dsn> [--verbose] [--dry-run]
    mimi fix     --dsn=<dsn> [--verbose] [--dry-run]
    mimi set     --dsn=<dsn> <migration> [--verbose] [--dry-run]
    mimi -h | --help

    --dsn=<dsn>           DBI dsn string, 'dbi:SQLite:database.db' for example
    --schema=<directory>  Directory with migrations
    --dry-run             Do nothing, just show what's to be done
    --verbose             Be verbose
    -h --help             Show this screen.

# DESCRIPTION

This is a migration script for small home projects. Despite of being small it's
still robust. This means that all the precautions are made to not to corrupt
your data.

## Safety first

Every command has `verbose` and `dry-run` flags. Thus it is easy to check
first what's going to happen.

## Check

    mimi check --dsn 'dbi:SQLite:database.db'

Check what's going on. Are migrations installed? What is the latest migration? Was there an error?

## Setupping your database

    mimi setup --dsn 'dbi:SQLite:database.db'

This creates `mimi` table in your database. This table is used as a journal for
migrations.

## Migrations

    mimi migrate --dsn 'dbi:SQLite:database.db' --schema sql_files/

This will search `sql_files` for `*.sql` files, parse their names that usually
look like `01add_column.sql`, `02drop_table.sql` and so on. Then it will try
to find the last migration and run everything with a bigger number.

## Failures and fixes

Failures do occur. Like you made a mistake in your migration (of course you
should run them on a local machine first!). `mimi` will die but remember that
last migration was with error and won't let you run next migrations dying with:

    Error: Migrations are dirty. Last error was in migration 1:

        DBD::SQLite::db do failed: near "CREAT": syntax error

    After fixing the problem run <fix> command

After fixing the stuff, you either can `fix` or `set` the current migration
number manually:

    mimi fix --dsn '...'
    mimi set --dsn '...' 123

## Additional checks

You will get descriptive errors when trying to do unexpected stuff, like running
migrations on a fresh database or supplying a directory without migration files.
