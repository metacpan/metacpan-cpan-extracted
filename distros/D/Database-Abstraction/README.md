Database-Abstraction
====================

[![Appveyor Status](https://ci.appveyor.com/api/projects/status/1t1yhvagx00c2qi8?svg=true)](https://ci.appveyor.com/project/nigelhorne/database-abstraction)
[![CircleCI](https://dl.circleci.com/status-badge/img/circleci/8CE7w65gte4YmSREC2GBgW/THucjGauwLPtHu1MMAueHj/tree/main.svg?style=svg)](https://dl.circleci.com/status-badge/redirect/circleci/8CE7w65gte4YmSREC2GBgW/THucjGauwLPtHu1MMAueHj/tree/main)
[![Coveralls Status](https://coveralls.io/repos/github/nigelhorne/Database-Abstraction/badge.svg?branch=master)](https://coveralls.io/github/nigelhorne/Database-Abstraction?branch=master)
[![CPAN](https://img.shields.io/cpan/v/Database-Abstraction.svg)](http://search.cpan.org/~nhorne/Database-Abstraction/)
![GitHub Workflow Status](https://img.shields.io/github/actions/workflow/status/nigelhorne/ntpdate/ntpdate.yml?branch=master)
![Perl Version](https://img.shields.io/badge/perl-5.8+-blue)
[![Tweet](https://img.shields.io/twitter/url/http/shields.io.svg?style=social)](https://x.com/intent/tweet?text=Information+about+the+Database+Environment+#perl+#ORM&url=https://github.com/nigelhorne/database-abstraction&via=nigelhorne)

# NAME

Database::Abstraction - Read-only Database Abstraction Layer (ORM)

# VERSION

Version 0.33

# DESCRIPTION

`Database::Abstraction` is a read-only database abstraction layer (ORM) for Perl,
designed to provide a simple interface for accessing and querying various types of databases such as CSV, XML, and SQLite without the need to write SQL queries.
It promotes code maintainability by abstracting database access logic into a single interface,
allowing users to switch between different storage formats seamlessly.
The module supports caching for performance optimization,
flexible logging for debugging and monitoring,
and includes features like the AUTOLOAD method for convenient access to database columns.
By handling numerous database and file formats,
`Database::Abstraction` adds versatility and simplifies the management of read-intensive applications.

# SYNOPSIS

Abstract class giving read-only access to CSV,
XML,
BerkeleyDB and SQLite databases via Perl without writing any SQL,
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

- 5 `BerkeleyDB`

    File ends with .db

The AUTOLOAD feature allows for convenient access to database columns using method calls.
It hides the complexity of querying the underlying data storage.

If the table has a key column,
entries are keyed on that and sorts are based on it.
To turn that off, pass 'no\_entry' to the constructor, for legacy
reasons it's enabled by default.
The key column's default name is 'entry', but it can be overridden by the 'id' parameter.

Arrays are made read-only before being returned.
To disable that, pass `no_fixate` to the constructor.

CSV files that are not no\_entry can have empty lines or comment lines starting with '#',
to make them more readable.

# EXAMPLE

If the file /var/dat/foo.csv contains something like:

    "customer_id","name"
    "plugh","John"
    "xyzzy","Jane"

Create a driver for the file in .../Database/foo.pm:

    package Database::foo;

    use Database::Abstraction;

    our @ISA = ('Database::Abstraction');

    # Regular CSV: There is no entry column and the separators are commas
    sub new
    {
        my $class = shift;
        my %args = (ref($_[0]) eq 'HASH') ? %{$_[0]} : @_;

        return $class->SUPER::new(no_entry => 1, sep_char => ',', %args);
    }

You can then use this code to access the data via the driver:

    # Opens the file, e.g. /var/dat/foo.csv
    my $foo = Database::foo->new(directory => '/var/dat');

    # Prints "John"
    print 'Customer name ', $foo->name(customer_id => 'plugh'), "\n";

    # Prints:
    #  $VAR1 = {
    #     'customer_id' => 'xyzzy',
    #     'name' => 'Jane'
    #  };
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

## import

The module can be initialised by the `use` directive.

    use Database::Abstraction 'directory' => '/etc/data';

or

    use Database::Abstraction { 'directory' => '/etc/data' };

## new

Create an object to point to a read-only database.

Arguments:

Takes different argument formats (hash or positional)

- `auto_load`

    Enable/disable the AUTOLOAD feature.
    The default is to have it enabled.

- `cache`

    Place to store results

- `cache_duration`

    How long to store results in the cache (default is 1 hour).

- `config_file`

    Points to a configuration file which contains the parameters to `new()`.
    The file can be in any common format including `YAML`, `XML`, and `INI`.
    This allows the parameters to be set at run time.

- `expires_in`

    Synonym of `cache_duration`, for compatibility with `CHI`.

- `dbname`

    The prefix of name of the database file (default is name of the table).
    The database will be held in a file such as $dbname.csv.

- `directory`

    Where the database file is held.
    If only one argument is given to `new()`, it is taken to be `directory`.

- `filename`

    Filename containing the data.
    When not given,
    the filename is derived from the tablename
    which in turn comes from the class name.

- `logger`

    Takes an optional parameter logger, which is used for warnings and traces.
    Can be an object that understands warn() and trace() messages,
    such as a [Log::Log4perl](https://metacpan.org/pod/Log%3A%3ALog4perl) or [Log::Any](https://metacpan.org/pod/Log%3A%3AAny) object,
    a reference to code,
    or a filename.

- `max_slurp_size`

    CSV/PSV/XML files smaller than this are held in a HASH in RAM (default is 16K),
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

Sets the class, code reference, or file that will be used for logging.

## selectall\_arrayref

Returns a reference to an array of hash references of all the data meeting
the given criteria.

Note that since this returns an array ref,
optimisations such as "LIMIT 1" will not be used.

Use caching if that is available.

Returns undef if there are no matches.

## selectall\_hashref

Deprecated misleading legacy name for selectall\_arrayref.

## selectall\_array

Similar to selectall\_array but returns an array of hash references.

Con:	Copies more data around than selectall\_arrayref
Pro:	Better determination of list vs scalar mode than selectall\_arrayref by setting "LIMIT 1"

TODO:	Remove duplicated code

## selectall\_hash

Deprecated misleading legacy name for selectall\_array.

## count

Return the number items/rows matching the given criteria

## fetchrow\_hashref

Returns a hash reference for a single row in a table.

It searches for the given arguments, searching IS NULL if the value is `undef`

    my $res = $foo->fetchrow_hashref(entry => 'one');

Special argument: table: determines the table to read from if not the default,
which is worked out from the class name

When no\_entry is not set allow just one argument to be given: the entry value.

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

Nigel Horne, `<njh at nigelhorne.com>`

# SUPPORT

This module is provided as-is without any warranty.

Please report any bugs or feature requests to `bug-database-abstraction at rt.cpan.org`,
or through the web interface at
[http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Database-Abstraction](http://rt.cpan.org/NoAuth/ReportBug.html?Queue=Database-Abstraction).
I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.

# BUGS

The default delimiter for CSV files is set to '!', not ',' for historical reasons.
I really ought to fix that.

It would be nice for the key column to be called key, not entry,
however key's a reserved word in SQL.

The no\_entry parameter should be no\_id.

XML slurping is hard,
so if XML fails for you on a small file force non-slurping mode with

    $foo = MyPackageName::Database::Foo->new({
        directory => '/var/dat',
        max_slurp_size => 0     # force to not use slurp and therefore to use SQL
    });

# SEE ALSO

- Test coverage report: [https://nigelhorne.github.io/Database-Abstraction/coverage/](https://nigelhorne.github.io/Database-Abstraction/coverage/)

# LICENSE AND COPYRIGHT

Copyright 2015-2025 Nigel Horne.

This program is released under the following licence: GPL2.
Usage is subject to licence terms.
The licence terms of this software are as follows:
Personal single user, single computer use: GPL2
All other users (for example, Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at the
above e-mail.
