# NAME

Database::Abstraction - database abstraction layer

# VERSION

Version 0.01

# SYNOPSIS

Abstract class giving read-only access to CSV, XML and SQLite databases via Perl without writing any SQL.
Look for databases in $directory in this order:
1) SQLite (file ends with .sql)
2) PSV (pipe separated file, file ends with .psv)
3) CSV (file ends with .csv or .db, can be gzipped)
4) XML (file ends with .xml)

For example, you can access the files in /var/db/foo.csv via this class:

    package MyPackageName::Database::Foo;;

    use Database::Abstraction;

    our @ISA = ('Database::Abstraction');

    1;

You can then access the data using:

    my $foo = MyPackageName::Database->new(directory => '/var/db');
    my $row = $foo->fetchrow_hashref(customer_id => '12345);
    print Data::Dumper->new([$row])->Dump();

CSV files can have empty lines of comment lines starting with '#', to make them more readable

If the table has a column called "entry", sorts are based on that
To turn that off, pass 'no\_entry' to the constructor, for legacy
reasons it's enabled by default

# SUBROUTINES/METHODS

## init

Set some class level defaults.

    __PACKAGE__::Database(directory => '../databases')

See the documentation for new() to see what variables can be set

## new

Create an object to point to a read-only database.

Arguments:

cache => place to store results;
cache\_duration => how long to store results in the cache (default is 1 hour);
directory => where the database file is held

If the arguments are not set, tries to take from class level defaults

## set\_logger

Pass a class that will be used for logging

## selectall\_hashref

Returns a reference to an array of hash references of all the data meeting
the given criteria

## selectall\_hash

Returns an array of hash references

## fetchrow\_hashref

Returns a hash reference for one row in a table.
Special argument: table: determines the table to read from if not the default,
which is worked out from the class name

## execute

Execute the given SQL on the data.
In an array context, returns an array of hash refs,
in a scalar context returns a hash of the first row

## updated

Time that the database was last updated

## AUTOLOAD

Return the contents of an arbitrary column in the database which match the
given criteria
Returns an array of the matches, or just the first entry when called in
scalar context

If the first column if the database is "entry" you can do a quick lookup with
    my $value = $table->column($entry);	# where column is the value you're after

Set distinct to 1 if you're after a unique list

# AUTHOR

Nigel Horne, `<njh at bandsman.co.uk>`

# LICENSE AND COPYRIGHT

Copyright 2015-2024 Nigel Horne.

This program is released under the following licence: GPL2.
Usage is subject to licence terms.
The licence terms of this software are as follows:
Personal single user, single computer use: GPL2
All other users (for example Commercial, Charity, Educational, Government)
must apply in writing for a licence for use from Nigel Horne at the
above e-mail.
