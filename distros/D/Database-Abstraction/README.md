# NAME

Database::Abstraction - read-only database abstraction layer (ORM)

# VERSION
Version 0.15

# SYNOPSIS

Abstract class giving read-only access to CSV,
XML and SQLite databases via Perl without writing any SQL,
using caching for performance optimization.

The module promotes code maintainability by abstracting database access logic into a single interface.
Users can switch between different storage formats without changing application logic.
The ability to handle numerous database and file formats adds versatility and makes it useful for a variety of applications.

It's a simple ORM like interface which,
for all of its simplicity,
allows you to do a lot of the heavy lifting of simple database operations without any SQL.
It offers functionalities like opening the database and fetching data based on various criteria.

Built-in support for flexible and configurable caching improves performance for read-intensive applications.

Supports logging to debug and monitor database operations.

Look for databases in $directory in this order:

- 1 `SQLite`

    File ends with .sql

- 2 `PSV`

    Pipe separated file, file ends with .psv

- 3 `CSV`

    File ends with .csv or .db, can be gzipped. Note the default sep\_char is '!' not ','

- 4 `XML`

    File ends with .xml

The AUTOLOAD feature allows for convenient access to database columns using method calls.
It hides the complexity of querying the underlying data storage.

If the table has a key column,
entries are keyed on that and sorts are based on it.
To turn that off, pass 'no\_entry' to the constructor, for legacy
reasons it's enabled by default.
The key column's default name is 'entry', but it can be overridden by the 'id' parameter.

CSV files that are not no\_entry can have empty lines or comment lines starting with '#',
to make them more readable.

For example, you can access the files in /var/db/foo.csv via this class:

    package MyPackageName::Database::Foo;

    use Database::Abstraction;

    our @ISA = ('Database::Abstraction');

    # Regular CSV: There is no entry column and the separators are commas
    sub new
    {
        my $class = shift;
        my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

        return $class->SUPER::new(no_entry => 1, sep_char => ',', %args);
    }

You can then access the data using:

    my $foo = MyPackageName::Database::Foo->new(directory => '/var/dat');
    print 'Customer name ', $foo->name(customer_id => 'plugh'), "\n";

    my $row = $foo->fetchrow_hashref(customer_id => 'xyzzy');
    print Data::Dumper->new([$row])->Dump();

# SUBROUTINES/METHODS

## init

Initializes the abstraction class and its subclasses with optional arguments for configuration.

    Database::Abstraction::init(directory => '../data');

See the documentation for new to see what variables can be set.

Returns a reference to a hash of the current values.
Therefore when given with no arguments you can get the current default values:

    my $defaults = Database::Abstraction::init();
    print $defaults->{'directory'}, "\n";

## new

Create an object to point to a read-only database.

Arguments:

Takes different argument formats (hash or positional)

- `cache`

    Place to store results

- `cache_duration`

    How long to store results in the cache (default is 1 hour)

- `dbname`

    The prefix of name of the database file (default is name of the table).
    The database will be held in a file such as $dbname.csv.

- `directory`

    Where the database file is held

- `max_slurp_size`

    CSV/PSV/XML files smaller than this are held in RAM (default is 16K),
    falling back to SQL on larger data sets.
    Setting this value to 0 will turn this feature off,
    thus forcing SQL to be used to access the database

If the arguments are not set, tries to take from class level defaults.

Checks for abstract class usage.

Slurp mode assumes that the key column (entry) is unique.
If it isn't, searches will be incomplete.
Turn off slurp mode on those databases,
by setting a low value for max\_slurp\_size.

Clones existing objects with or without modifications.
Uses Carp::carp to log warnings for incorrect usage or potential mistakes.

## set\_logger

Sets class or code reference that will be used for logging.

## selectall\_hashref

Returns a reference to an array of hash references of all the data meeting
the given criteria.

Note that since this returns an array ref,
optimisations such as "LIMIT 1" will not be used.

Use caching if that is available.

## selectall\_hash

Similar to selectall\_hashref but returns an array of hash references.

## fetchrow\_hashref

Returns a hash reference for a single row in a table.

Special argument: table: determines the table to read from if not the default,
which is worked out from the class name

## execute

Execute the given SQL query on the database.
In an array context, returns an array of hash refs,
in a scalar context returns a hash of the first row

On CSV tables without no\_entry, it may help to add
"WHERE entry IS NOT NULL AND entry NOT LIKE '#%'"
to the query.

If the data have been slurped,
this will still work by accessing that actual database.

## updated

Returns the timestamp of the last database update.

## AUTOLOAD

Directly access a database column.

Returns all entries in a column, a single entry based on criteria.
Uses cached data if available.

Returns an array of the matches,
or only the first when called in scalar context

If the database has a column called "entry" you can do a quick lookup with

    my $value = $foo->column('123');    # where "column" is the value you're after

    my @entries = $foo->entry();
    print 'There are ', scalar(@entries), " entries in the database\n";

Set distinct or unique to 1 if you're after a unique list.

Throws an error in slurp mode when an invalid column name is given.

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# BUGS

The default delimiter for CSV files is set to '!', not ',' for historical reasons.
I really ought to fix that.

It would be nice for the key column to be called key, not entry,
however key's a reserved word in SQL.

The no\_entry parameter should be no\_id.

XML slurping is hard,
so if XML fails for you on a small file force non-slurping mode with

    $foo = MyPackageName::Database::Foo->new({
        directory => '/var/db',
        max_slurp_size => 0     # force to not use slurp and therefore to use SQL
    });

# LICENSE AND COPYRIGHT

Copyright 2015-2025 Nigel Horne.

This program is released under the following licence: GPL2.
Usage is subject to licence terms.
The licence terms of this software are as follows:
Personal single user, single computer use: GPL2
All other users (for example Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at the
above e-mail.
