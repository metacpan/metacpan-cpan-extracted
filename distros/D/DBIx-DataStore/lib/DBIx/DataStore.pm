package DBIx::DataStore;
$DBIx::DataStore::VERSION = '0.097';
use strict;
use warnings;

# ABSTRACT: Abstracts away oft-repeated parts of DBI and simplifies the way SQL is issued.

use DBI;

=head1 NAME

DBIx::DataStore

=head1 DESCRIPTION

DBIx::DataStore is designed to abstract away the oft-repeated parts of DBI and to
simplify the way you issue SQL statements to your database(s).

=head1 EXAMPLE

As a fairly contrived example, below is a chunk of code using this module in a
relatively simple way.  It starts by instantiating a new DBIx::DataStore object
connected to the "commerce" data store.  It then issues a single SELECT query,
with the optional paginating feature turned on and set to the first page of
results.  It then gets a Data::Page object through the pager() method and loops
over the first page's worth of results from the database to print them.

    use DBIx::DataStore ( config => 'yaml' );

    my $db = DBIx::DataStore->new('commerce');

    my $results = $db->do({ page => 1, per_page => 15 }, q{
        select p.name, p.price, c.name as category
        from products p
            join product_categories pc on (pc.produc_id = p.id)
            join categories c on (c.id = pc.category_id)
        where c.id in ???
            and p.price between ? and ?
        order by p.price desc, p.name asc
    }, [2,3,5], 17, 23);

    my $pager = $results->pager;

    while ($results->next) {
        print sprintf("%s was found in category %s for \$%.2f.\n",
            @{$results}{qw( name category price )});
    }

    print sprintf("\nShowing %d to %d of %d total results.\n",
        $pager->first, $pager->last, $pager->total_entries);

And here is what the output from that code might look like.

    Golden Apple was found in category Food for $22.24.
    Mermaid Statue was found in category Artwork for $17.76.
    Norton's Epaulets was found in category Clothing for $17.76.

    Showing 1 to 3 of 3 total results.

=head2 IMPORTANT NOTICE

This is the legacy release of DBIx::DataStore and has a low chance of seeing
future (non-critical bug fix) releases. It is being published for the primary
purpose of easing the maintenance of existing installations.

Future versions of this module will make attempts to maintain as much backwards
compatibility as possible, but there are no guarantees that every feature or
method will carry over unchanged from the user perspective. It is recommended
that if you do build something around this module that you pin to pre-1.0
versions. A future release which breaks functionality with what is presented
here will begin with a new major version.

This code has been in heavy production use at multiple companies for almost
fifteen years and is considered pretty (though not perfectly) stable. You are
welcome to make use of it, in the form presented here, in your own projects.
Significant feature requests for this version will likely be met with a
somewhat low priority, and development of new applications or libraries with it
is not strongly encouraged.

Critical security and bug fix requests will be reviewed.

=head1 CONCEPTS

In using DBIx::DataStore, there are three main types of objects with which you'll
generally interact.

=over

=item *

Database objects

These objects manage the connections to your database servers (either one or two
servers at all times, depending on whether you have any reader databases
configured) and are used to issue all commands to your database backend.

=item *

Result Set objects

Every time you issue a read-oriented query through the C<do()> method of a
database object, a new result set object is created.  These objects are what you
use to access the results of your query.  Unlike the normal method of accessing
a row's data using DBI methods directly, with DBIx::DataStore result set objects,
the current row's data is accessed through the result set object itself.

Result set objects also contain a single result row object at any given time (or
no result row object if you haven't yet called the C<next()> method on a result
set object).  You don't actually directly interact with a distinct object for
each row -- row methods are issued through the result set object to act on the
currently visible row, and will simply fall through to the row object.

=item *

Pager objects

These objects are used only when you request one by calling the C<pager()>
method on a result set object.  They are normal L<Data::Page> objects, so refer
to the documentation for that module for further details.  Please note that you
can only use pager objects on a result set when you passed in at least one of
C<page> or C<per_page> arguments to the C<do()> method.  Without either of those
arguments, your query will be performed in I<unpaged> mode and you will trigger
an error if you attempt to call the C<pager()> method on your result set.  You
will also get an error if you explicitly turned paging support off when loading
DBIx::DataStore.

=back

=head1 MODULE ARGUMENTS

DBIx::DataStore allows a number of options to be specified at the time you
import the module into your code.  These options, and their effects, are
described here.  Arguments are passed as a hash (not a reference) to the
module as part of the use statement.  For example, to load DBIx::DataStore
with the default options, except for debugging which we'll set to "5", do:

    use DBIx::DataStore ( debug => 5 );

Below is a description of each option that can be fiddled with on module
import.  The name in parentheses at the start of each subsection is the
key name to use in the hash passed to DBIx::DataStore during use.

=head2 Debugging (debug)

Accepts any integer value.  Non-integer values, or any numbers zero or lower
will turn off debugging.  Any positive integers will turn on debugging, with
higher numbers producing more debugging output.  Typically, a debugging level
of 1 will only produce non-fatal-but-concerning debug messages, analogous to
an INFO level.  At level 2 messages will generally be produced that are more
warning-only in nature, but not serious issues.  Debugging level 3 introduces
submodule and method entry messages into the output.  Debugging level 4 and
above are more or less reserved for "here" statements to trace detailed
code execution.

Debugging level 5 is (or at least should) be the highest number that actually
introduces any changes in the output.  This level should not actually trigger
any more calls to the internal logger, so in terms of the number of statements
it should be functionally equivalent to debugging level 4.  However, unlike
lower levels of output, this will cause a full stack trace to be produced for
every single call to the logger.  As such, this debugging level is only
recommended for tracking down really nasty bugs or for general use by the
clinically insane.

Calls to the internal logger are handled by a foldable constant, so there
should be no performance penalty at all when debugging is turned off -- the
Perl compiler should remove those calls from the code entirely.

=head2 Configuration Loader (config)

DBIx::DataStore can use multiple configuration formats.  Right now support
only exists for YAML, but if you'd rather use INI files or on-disk Storable
seralized data structures (and if a DBIx::DataStore::Config submodule has
been written to support it) you're more than welcome to change that.  This
is done by passing in the config argument when loading DBIx::DataStore.

You can also indicate that none of the configuration loader submodules should
be used by not passing in a config argument at all.  If you do this, you
will be expected to pass in an appropriate configuration data structure
(details on that later in this document) to the constructor.

Note that if you do use a configuration loader, they read their actual
configuration files and do the processing work immediately when DBIx::DataStore
is imported, then cache the parsed configuration data.  Thus, you shouldn't
have to worry about the performance in web-based applications if you
have a facility to pre-load this module (such as mod_perl in Apache)
when you start the web server.

=head2 Home Directory Configurations (use_home)

This option goes in hand with the config option, and indicates to any
relevant configuration loaders that they should also look inside the
current user's home directory for configuration files.  This is turned off
by default because of the extra modules that are loaded (File::HomeDir and
all of its dependencies) as well as the extra CPU time and stat calls
necessary to do these checks.

=head2 Result Set Paginating (paging)

By default, Data::Page is automatically imported for use by the C<pager()>
method on result sets.  In situations where you have no need for paging
of your result sets and wish to avoid the extra time and memory spent on
that code, you can explicitly disable it.  Note that if you do so and then
try to call the pager method on a result set, you will trigger a fatal
error.

You can also set this option to "auto" which allows you to call pager()
without dying, but won't load Data::Page and its dependencies until the
first time you need it.  This load-on-demand can be bad in some cases,
though, even if it seems likes a good idea.  In single-process code that
may or may not ever need to page something, setting this to auto would
make sense.  In a situation like mod_perl in Apache, it is advised
against.

With load on demand in mod_perl, you end up only loading it
for a single Apache process when it's first needed.  If more than one
process needs it, more than one copy is loaded.  If those processes are
eventually killed (through max keepalive request like settings) and its
needed again, then it has to be loaded all over again.  Instead, preloading
it in the main Apache process creates a single copy available to every
child Apache process for the lifetime of that Apache run.

=head1 DATABASE METHODS

=head2 General methods

The following methods are your primary interface to database objects.  Typically
you will only be calling the C<new()> method once your applications, but unless
you have very simple database needs you will almost certainly be making many
calls to the C<do()> method.

=over

=item new()

The constructor method actually supports multiple distinct syntaxes.  The first
is the old syntax from the SQL::Wrapper module (the immediate predecessor to
DBIx::DataStore and never widely released).  This syntax is deprecated and
will some day be removed, so it is not discussed here (look at the code if you
really must know what it is).

There are three main forms of the currently-supported constructor syntax.  The
first of these is to simply specify the name of the data store to which you
want to connect and optionally and alternate schema list:

    my $db = DBIx::DataStore->new($datastore);
    my $db = DBIx::DataStore->new($datastore, @schemas);

This should be a single scalar value containing a string that matches the name of
one of the datastores defined in your configuration (whether it be YAML or any of
the other configuration loaders supported).

The second form allows more control over specific parts of a datastore's
configuration and connection parameters:

    my $db = DBIx::DataStore->new({ store => $datastore, ... });

This version allows for overriding not just the schemas, but which reader
should be used, changing the default settings for statement preparation, statement
caching and so on.

TODO: Go into more detail on how exactly to set these extra options.

The last is the simplest, to pass in no arguments at all to the constructor.
One of three things will happen.  First, DBIx::DataStore will get a list
of all the package names from the caller's stack, and starting with the
bottom, working its way up to the very top of the stack, will look for any
datastore which matches one of those package names with the regular
expression in its "packages" variable.  The first match to succeed will
cause that datastore to be used for the connection.

If no matches were found, then a datastore is looked for which has the
"is_default" flag set to a true value.  If there is one, then that datastore
will be used.  If that check fails, then an error is produced indicating that
there was no suitable choice for a default datastore connection.

=item do(\%options, $query, @binds)

This method requires at least one argument (C<$query>) but can in some cases be
called with far more than that.  The first argument is optional and is used
primarily to enable automated pagination of query results.  If passed in, it
should contain at least one of "page" (which will default to 1 if not specified)
or "per_page" (which defaults to 25).  If neither is passed in, automatic
pagination will not be available for the returned result set.

If you do take advantage of the paginating options to this method, do not
include any sort of row limit clause in your actual query (such as "LIMIT x
OFFSET y", "ROWS x TO y" or whatever the flavor is for your particular database
server).  This method will add that clause to your query as appropriate.

The next argument (which would be the first one if you choose to leave
pagination disabled) is required and must contain the SQL statement you would
like issued to your database server.  Regular scalar placeholders are allowed,
as well as a non-DBI placeholder that can be used with arrays and hashes (in
specific contexts).  Refer to the L</"PLACEHOLDERS"> section of this document
for details.

All arguments after the query will be used as your bind variables when executing
the SQL statement.  They must be in the same order as the actual placeholders
within your query and you must provide the exact same number of bind variables
as you did placeholders.  Failure to do so will result in a fatal error.

This method, when successful, returns a DBIx::DataStore result set object (see
L</"RESULT SET METHODS"> for details on what you can do with these).

=back

=head2 Transaction related methods

The following methods are used when dealing with transactions.  If your database
server does not support transactions, these will be useless to you.  You'll
probably also receive fatal errors if you try to use them.

=over

=item begin()

This method starts a new transaction block in your current database session.
Please note that not all databases support nested transactions (and even those
that do may have limits on how deeply they can be nested).  You will receive an
error if you attempt to call this method multiple times (with no intervening
C<commit()> or C<rollback()> calls) when using a database that does not support
nested transactions.  You may want to look into whether savepoints will suffice
for your needs in those cases.

As soon as you open a transaction, B<all> queries issued to your database
through the C<do()> method will be sent to your primary server.  No queries will
be issued to your reader database until you either commit or rollback the
transaction.

=item commit()

This method ends the current transaction block in your database session.  If you
are using a database server which supports nested transactions, you may need to
call this method as many times as you called C<begin()> (or you may not -- at
least some versions of Oracle, for instance, default to commiting B<all> your
open transactions unless you set a server/session variable).

=item rollback($savepoint)

This method takes one optional argument.  Called with no arguments, it rolls
back all of the changes you've made to your database within the current
transaction block.  If you are using a database server that supports savepoints,
you may also pass in a single argument with the name of an already defined
savepoint (it B<must> have been defined within the current transaction block,
and not have already been cleared out by another rollback) to undo all of the
changes made I<after> the savepoint was created.  Passing in an invalid
savepoint name will generate a fatal error.

=item savepoint($name)

Calling this method on a database server which supports savepoints will create a
new savepoint at the current point of your open transaction with the name you
provide.  This method can only be called when you have an open transaction
block.  Attempts to call it outside of a transaction will trigger a fatal error.
It is also your responsibility to make sure you use a unique name for each of
your savepoints if you require more than one.

=item in_transaction()

This method returns true if your database object is currently in an open
transaction.

=back

=head2 Convenience methods

=over

=item base_tables()

This method returns a list of the tables, excluding any views.

=item databases()

This method returns a list of the database (schema) names available on the
primary database server.

=item db_primary()

This method returns a hash reference containing the following information about
the primary database server: name (always "primary"), driver, host and database.

=item db_reader()

This method returns a hash reference containing the following information about
the currently selected reader database: name, driver, host and database.

=item last_insert_id()

This method is a pass-through for DBI's C<last_insert_id()> function.  All the
same caveats apply to this method.  But just in case you aren't familiar with
them, basically consider this method unreliable on many database servers.  It
should only be used with care, and only if you know your underlying RDBMS's
DBD driver will do The Right Thing.

=item ping()

This method, when called, attempts to issue a very simple SQL statement
(generally "select 1") against both the primary and reader database servers (or
primary only if no reader has been selected).  A true value will be returned if
the statements were successful.

=item schemas()

If called with no arguments, returns a list of the schemas currently in the
search path for the primary server connection.  If called with a list of
scalar arguments, sets the connection's search path to those schemas (in
the order they were provided).

=item servers()

Returns a list of hash references, detailing the database servers defined in the
YAML config file. All servers defined are returned, regardless of whether they
have, or will, respond to connections.

Within each hash reference the following key/value pairs are provided: name (as
defined in the configuration file), driver, host and database.  The first hash
reference in the returned list will always be the server defined as the primary,
followed by the readers sorted by their names.

=item tables()

This method returns a list of the table names that are present within the
currently selected database (schema) on the primary server.  The list returned
will also include views (use C<base_tables()> if you don't want the views).

=item views()

This method will return a list of the views defined within your current schema.

=back

=head1 RESULT SET METHODS

Every call to the C<do()> method on a database object which contains a
read-oriented SQL query returns a result set object.  These objects can then be
used to access the data contained within the database query's results.

=over

=item Hash and Array accessors

Each time you retrieve a record (aka "result row") from a query's result set,
the values for each column in that record can be transparently accessed through
hash keys (where the keys are the column names as defined by the original query)
or array indices (in the order the columns were defined by the query).  Both
methods of accessing the record's values are available at all times (unlike the
standard DBI methods where you have to choose up front between using
C<fetchrow_array[ref]()> or C<fetchrow_hashref()>).  Thus, something like the
following is perfectly acceptable:

    my $result = $db->do(q{
        select id, name from users order by name asc
    });
    while ($result->next) {
        print sprintf("ID %d: %s\n",
            $result->[0],
            $result->{'name'}
        );
    }

=item next()

Retrieves the next row of results from the result set.  The row's data is then
directly accessible through the result set object itself (see L</"Hash and Array
accessors">).  This method also returns a reference to the result set object,
making the following two snippets of code effectively identical (though the
second is unnecessarily verbose):

    while ($result->next) {
        print $result->{'some_col_name'};
    }

or

    while (my $row = $result->next) {
        print $row->{'some_col_name'};
    }

The return value will be undef when there are no more rows to retrieve from the
database.

=item next_hashref()

Similar to a next() call, in that it moves to the next row in the result set
(or returns an undefined value when all rows have been read already).  However,
this method returns a stand-alone hash reference containing as keys the column
names from the query, and as values the contents of the current row of the
result set.

=item hashref()

Returns the exact same data structure as next_hashref(), except that it does
not move to the next row in the result set first.  You get a hash representation
of the current row from the results, not the next row.

=item all()

This method retrieves all rows from the database at once and returns a list of
result set row objects, each one containing a single row from the result set.
It is functionally equivalent to the following:

    my (@rows);
    while (my $row = $result->next) {
        push(@rows, $row);
    }

Please keep in mind that, internally, that is effectively what this method does
itself (though slightly more efficiently).  So C<all()> won't actually return
I<everything> if you've already called C<next()> one or more times on your
result set.  You will only get the rows you have not yet retrieved via other
means -- which also means that only the first call to this method will actually
do anything.

It is recommended you don't use this method if you will actually be operating on
each row's data in your Perl code.  You're better off using C<next()> and doing
whatever processing you need to on each row.  However, this method is useful if
you're passing the results of your SQL query directly into another module like
Template Toolkit and don't actually need to do any processing on the data before
handing it off.

=item columns()

This method returns a list of the column names from your SQL query, in the same
order they were returned by the database.

=item count()

This method will return the number of rows that were either returned by the
database (in the case of read-oriented queries) or the number of the rows that
were affected by your query (in the case of updates, inserts, etc.).

If you used pagination in your call to the C<do()> method, the number returned
by this method is the number of rows your select query would have returned
B<without> pagination.  This makes it very simple to do simple pagination of
your query results, but still be able to display to the end user of your
application how many total results there are.

There is a catch to this feature, though.  Your database server B<must> support
subqueries against derived tables for this method to succeed.  If you aren't
sure whether your database supports this feature (most of them which support
subqueries do), you can try to run the following SQL query (change "some_table"
to a table name that actually exists first):

    select count(*) from (select * from some_table) derived

Some database servers, such as Oracle, don't allow you to give a name to a
derived table in a SQL query like the one above.  But if you're running Oracle,
this method is properly supported anyway (for what it's worth, the only change
to that query above to have it work on Oracle is to omit the word "derived" at
the end).

=item pager()

This method will return a L<Data::Page> object which you can use for easier
paginating of your database query results.  You cannot call this method on a
result set object which was created from a call to C<do()> that lacked the
optional pagination options.  Attempting to do so will generate a fatal error.

=back

=head1 PLACEHOLDERS

In addition to the standard scalar-value placeholder available through standard
DBI calls, this module adds another type of placeholder which can be used for
inserting entire arrays or hashes into your queries.  There are limitations on
how and where they can be used, though.  Both types of placeholders are written
as a series of three question marks.

These additional forms for placeholders are B<optional> in your queries.  You
are not forced to always use array placeholders for your IN clauses, nor are you
forced to use the hash placeholders for your UPDATEs and INSERTs.  You are more
than welcome to use the regular style placeholders if you really prefer them (or
have some other reason to not use the more convenient forms added by this
module).  You can also mix and match the styles within any single query as well,
having one IN specified with single-value placeholders and another IN with an
array placeholder in a single query.

=over

=item *

Array placeholders

These allow you to pass in a list of values to be used in an IN (...) clause,
without you having to know or care how many elements are in the array.  They
cannot be used anywhere else but as part of an IN (although placing the
parentheses around the placeholder is optional -- it will be added if you didn't
include it).

Example:

    my $result = $db->do(q{
        select * from users where id in (???)
    }, \@userid_list);

If your list of user IDs contained the values "1", "2" and "3" this would have
achieved the same exact effect as you writing out the C<do()> call more
verbosely as:

    my $result = $db->do(q{
        select * from users where id in (?,?,?)
    }, 1, 2, 3);

But then, you would have needed to know exactly how many elements were going to
be in the list of IDs you wanted to match against and would have had to write
that many single placeholders in the query yourself.  Because the values in your
list remain as real placeholders under the hood of this module, you can still
take advantage of statement caching and the like from the underlying DBI methods
(assuming you have that turned on), and the values you pass into the query will
be safely escaped as usual.

=item *

Hash placeholders for UPDATE

These can be used to fill in the SET portion of your UPDATE statement.  Each
key/value pair will be turned into "column = ?" with the values of your hash
remaining as placeholders so the same advantages of array placeholders apply
here as well.

Example:

    my $num_rows_updated = $db->do(q{
        update users set ??? where id = ?
    }, { name => $new_name }, $user_id);

Writing out the normal placeholder(s) yourself would work too, but would get
pretty annoying if you're updating many columns at once.

=item *

Hash placeholders for INSERT

The second place in which hash placeholders can be used is for INSERT
statements.  Multiple record inserts are also supported, just put all the hash
references containing each record's data into an array reference.

There is one slight I<gotcha> with using hash placeholders in INSERT statements.
You cannot specify the column name list inside your SQL query.  The C<do()>
method will fill that in for you when it processes the placeholder.  The
I<values> keyword in your query is optional, but if present, the placeholder
must come after it, not before.

Example:

    my $num_rows_inserted = $db->do(q{
        insert into users values ???
    }, { name => $name, email => $email, ... });

=back

=head1 EXCEPTIONS

=head2 Exceptions to selection of secondary servers for read-only statements

If indicated by the "reader" argument to new(), a secondary server may be used
for distributing the load of read-only statements.  However, no statements
within a transaction will be issued to any server other than the primary,
regardless of the "reader" setting.  Also, if only a single server (the primary)
is defined in the config, but "__random" is indicated in new()'s arguments, it
will have no effect (all statements will be issued through the primary) and no
errors will be reported.  Thus, it is safe to use "__random" even if you have no
secondary databases (and can save you time updating your code later if you add
more database servers down the road).

=head1 CONFIGURATION

Database server configuration may current be done through either a YAML file or
by passing in an equivalent datastructure to your C<new()> call.  Other
file formats would be possible with an appropriate config loader,
but YAML is the only one currently supported.

You can override where the configuration file is located when calling the new()
method, or you can pass in a scalar containing raw, unprocessed YAML, or even
pass in a hash reference which contains a data structure identical to what YAML
would have returned itself if you need to bypass the YAML parsing for any
reason. The latter is particularly useful if your application already has its
own configuration files and you wish to embed the DBIx::DataStore config data
within them.

Your configuration must contain at least one "primary" server definition, and
may contain any number of "reader" server definitions (or none at all if you
only have a single server).  Each server definition in the config must contain
the following: DBD driver name, host address, database name, username and
password.  You may optionally include a list of key/value pairs for each server
under the heading "dbd_opts" which will be passed directly through to any
connection setup to that server.  For details on what settings are available,
check the documentation for DBI and for any relevant DBD::* modules you will be
using.

For some database servers, depending on your configuration, you may also need to
specify a list of schemas for your connection's search path.  This is currently
only handled for PostgreSQL connections, and is only necessary if you will be
accessing tables, functions, etc. that exist outside the default "public"
schema.  If unspecified, you will only be able to access objects in the default
schema, unless you provide fully qualified identifiers (and assuming you have
appropriate permissions to do so).  If specified, you must list all schemas for
which you want in your search path, including the "public" schema.  Any number
of schemas may be listed, and they will be added to your search path in the
same order you specify in the configuration.  For all non-PostgreSQL servers,
the schemas option will be ignored if specified.

In addition to the definition of individual servers, there are a few top-level
configuration settings.

=over

=item *

default_reader

Defines which reader database to use.  Valid values are: the name of one of your
defined reader databases, "__random" (which will, as the name implies, choose a
random reader database from the list), "primary" and "none".  The last two have
the same effect as not defining a default reader at all.  Without a specific
reader named, or "__random" to choose one randomly, no reader database will be
used and all queries will be issued to the primary server.

=item *

reader_failover

Valid values are one or zero (defaults to zero).  With this option turned on,
every query issued to a reader database will be preceded by a C<ping()> call.
If the ping fails, then a new reader database will be selected (for the current
and all future queries issued to the reader).  A warning will be printed each
time a new reader database needs to be selected due to a failed ping, but no
error will be issued unless a new reader cannot be selected.

Please note that each time a new reader database needs to be selected, B<all>
readers will be considered, even if they had failed before.  This is done in the
event that a previously unresponsive reader becomes available again.  You can
turn this off (and only consider readers that have not failed before) by turning
on the I<flag_bad_readers> option.

=item *

flag_bad_readers

If both this option and I<reader_failover> are turned on, then a reader database
will be taken out of consideration for all future reconnection attempts if it
has failed a ping attempt at any point within the current process.

=item *

cache_connections

With this option turned on, new database connections will be created through
DBI's C<connect_cached()> method instead of the normal C<connect()> method. This
allows for basic connection pooling.  For the full details, check DBI's
documentation.  Basically what happens is if you make multiple calls to
C<connect_cached()> with the exact same arguments (including the extra
connection parameters like I<RaiseError>, I<AutoCommit>, etc. -- not just the
DSN, username and password) you will get back the same database connection
handle each time, instead of brand new and untainted handles.  The exception is
if an existing, and cached, database handle still has an active statement handle
on it, it will not be returned.  Instead it will be removed from the cache and a
fully-new connection to the database will be established, cached and returned.

=item *

cache_statements

When this option is turned on, statement preparation in DBI will use
C<prepare_cached()> instead of C<prepare()>.  For some databases this can
provide measurable performance improvements if you issue the same query (this
includes the placeholders, but not the values being used within those
placeholders) repeatedly.  Not all databases' DBD modules show much or any
difference in performance between C<prepare()> and C<prepare_cached()>, but
preparation caching is generally very safe.

=back

=head2 YAML Configuration Example

    default_reader: __random
    reader_failover: 1
    flag_bad_readers: 0
    cache_connections: 0
    cache_statements: 1
    primary:
        driver: Pg
        db: mydatabase
        host: db-1
        user: username
        pass: password
        schemas:
            - myschema
            - public
        dbd_opts:
            AutoCommit: 0
    readers:
        reader1:
            driver: Pg
            db: mydatabase
            host: db-2
            user: username
            schemas:
                - myschema
                - public
        secondreader:
            driver: Pg
            db: mydatabase
            host: 10.1.2.3
            port: 8306
            user: username
            schemas:
                - myschema
                - public

=head2 Explicit Hashref Configuration Example

    my $config = {
        default_reader      => '__random',
        reader_failover     => 1,
        flag_bad_readers    => 0,
        cache_connections   => 0,
        cache_statements    => 1,
        primary => {
            driver  => 'Pg',
            db      => 'mydatabase',
            host    => 'db-1',
            user    => 'username',
            pass    => 'password',
            schemas => ['myschema','public'],
            dbd_opts => {
                AutoCommit => 0,
            }
        },
        readers => {
            reader1 => {
                driver  => 'Pg',
                db      => 'mydatabase',
                host    => 'db-2',
                user    => 'username',
                schemas => ['myschema','public']
            },
            reader2 => {
                driver  => 'Pg',
                db      => 'mydatabase',
                host    => '10.1.2.3',
                port    => 8306,
                user    => 'username',
                schemas => ['myschema','public']
            }
        }
    };
    my $db = DBIx::DataStore->new({ config => $config });

=head2 Configuring Database Passwords

Because DBIx::DataStore uses the normal DBI/DBD layers underneath, all the
usual methods of locating and presenting database credentials to the
appropriate database server are available.  This includes methods such as the
C<.pgpass> file for PostgreSQL and equivalents for other RDBMSes. If your
DBIx::DataStore configuration does not include a C<pass> attribute for a given
database host, these alternate methods will be used as long as they are
properly configured.

=head1 SEE ALSO

L<Data::Page>, L<DBI>, L<YAML::Syck>

=head1 AUTHORS

Jon Sime E<lt>jonsime@gmail.comE<gt>,
Buddy Burden E<lt>buddy@barefoot.netE<gt>

=head1 LICENSE

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

my $HASH_PH = qr/\?\?\?/;
my $ARRAY_PH = $HASH_PH;

my $USE_PAGER = 1;

# some "true" values/strings reused in a few places (mostly submodules)
our %TV = map { $_ => 1 } qw( 1 yes true on enable enabled );
# same thing, but for "false"
our %FV = map { $_ => 1 } qw( 0 no false off disable disabled );

sub import {
    my ($pkg, %t) = @_;

    foreach (keys %t) {
        $t{lc($_)} = lc($t{$_});
        delete $t{$_} unless lc($_) eq $_;
    }

    # set up debugging and logger
    $t{'debug'} = $ENV{'DATASTORE_DEBUG'} if (!defined $t{'debug'} || $t{'debug'} !~ /^\d+$/o)
        && defined $ENV{'DATASTORE_DEBUG'} && $ENV{'DATASTORE_DEBUG'} =~ /^\d+$/o;
    $t{'debug'} = 0 unless defined $t{'debug'} && $t{'debug'} =~ /^\d+$/o;
    eval("use DBIx::DataStore::Debug ($t{'debug'});");

    if (defined $t{'paging'}) {
        if (exists $TV{lc($t{'paging'})}) { #load Data::Page now
            $USE_PAGER = 1;
            eval("use Data::Page");
        } elsif (exists $FV{lc($t{'paging'})}) { #don't ever load Data::Page
            $USE_PAGER = 0;
        } else { # auto-loading of Data::Page on first use
            $USE_PAGER = -1;
        }
    }

    # call the config loader submodule
    $t{'use_home'} = 0 if !defined $t{'use_home'} || $t{'use_home'} !~ /^\d+$/o;
    eval("use DBIx::DataStore::Config ('$t{'config'}', $t{'use_home'});")
        if defined $t{'config'} && length($t{'config'}) > 0;

    # we do these mandatory loads here instead of the normal area because we need to
    # delay their loading until after we've done things like define DEBUG and such
    eval("use DBIx::DataStore::ResultRow");
    eval("use DBIx::DataStore::ResultSet");
}

sub new {
    my $class = shift;

    my $self = { error => '' };
    my $opts = {};
    my @configs = ();

    # check for options hashref to override config file path and/or secondary DB selection
    if (scalar(@_) > 0 && ref($_[0]) eq 'HASH') {
        $opts = shift;
    }

    my @args = @_;

    # check first to see if a config option was passed in, and if so whether it was a
    # hashref containing the already-parsed config data, a scalar with raw YAML markup
    # in it that still needs to be parsed, or a filesystem path to a YAML file...
    # alternatively, if no config option was passed in, fall back on the default paths
    my $found_config = 0;
    if (exists $opts->{'config'}) {
        dslog(q{Deprecated config-in-hashref constructor syntax used. This feature won't exist someday!}) if DEBUG();
        if (ref($opts->{'config'}) eq 'HASH') {
            # blindly assume hashref contains a valid config structure for now... if it
            # doesn't, that will be caught soon enough
            $self->{'config'} = { %{$opts->{'config'}} };
            $found_config = 1;
        } elsif ($opts->{'config'} =~ /^\// && -r $opts->{'config'}) {
            # scalar contained what appeared to be a path, and lo and behold it pointed to
            # file we're able to read... we don't set found_config here, though... just add
            # it to the list of configs to check further down to make sure it's actually
            # valid
            @configs = ($opts->{'config'});
        } elsif (length($opts->{'config'}) > 0) {
            # fall back on assumining it must be raw YAML that needs to be parsed, so
            # give that a shot now
            eval("use YAML::Syck qw()");
            if ($self->{'config'} = YAML::Syck::Load($opts->{'config'})) {
                $found_config = 1;
            }
        }

        if (scalar(@configs) > 0) {
            eval("use YAML::Syck qw()");

            foreach my $path (@configs) {
                next unless -r $path;
                if ($self->{'config'} = YAML::Syck::LoadFile($path)) {
                    $found_config = 1;
                    last;
                } else {
                    dslog(qq{Configuration file "$path" could not be loaded. Skipping.}) if DEBUG();
                }
            }
        }

        die dslog(q{Instance config variable present, but no valid config found.}) unless $found_config;

        # Check whether connection caching should be enabled
        if (defined $opts->{'cache_connections'}) {
            $self->{'config'}->{'cache_connections'} = $opts->{'cache_connections'};
        } elsif (!defined $self->{'config'}->{'cache_connections'}) {
            $self->{'config'}->{'cache_connections'} = 0;
        }

        # Check whether statement handler caching should be used
        if (defined $opts->{'cache_statements'}) {
            $self->{'config'}->{'cache_statements'} = $opts->{'cache_statements'};
        } elsif (!defined $self->{'config'}->{'cache_statements'}) {
            $self->{'config'}->{'cache_statements'} = 0;
        }
    }

    # now for the new DBIx::DataStore syntax (the previous block was to support the
    # old SQL::Wrapper syntax -- it will likely be dropped some day down the road
    if ($found_config != 1 && defined $opts->{'store'} && length($opts->{'store'}) > 0) {
        eval(q|$self->{'config'} = DBIx::DataStore::Config::get_store($opts->{'store'})|);
        if ($@ || !defined $self->{'config'}) {
            die dslog(q{Error getting configuration for datastore:}, $opts->{'store'}, q{[}, $@, q{]});
        } else {
            $found_config = 1;
        }
    }

    # check for the alternate-new syntax of "new($store, @schemas)" (where @schemas is optional)
    if ($found_config != 1 && scalar(@args) > 0) {
        eval(q|$self->{'config'} = DBIx::DataStore::Config::get_store($args[0])|);
        if ($@ || !defined $self->{'config'}) {
            dslog(q{Non-hashref args passed in, but first one is not a valid datastore config name.}) if DEBUG();
        } else {
            dslog(q{Alternate constructor syntax [new($datastore, @schemas)] used.}) if DEBUG() >= 3;
            $found_config = 1;
            shift(@args); # remove datastore name from remaining args
            my @manual_schemas = grep { $_ =~ /^\w+$/o } @args;
            if (scalar(@manual_schemas) > 0) {
                dslog(q{Overriding configuration's schemas with custom list:}, join(', ', @manual_schemas)) if DEBUG() >= 2;
                $self->{'config'}->{'primary'}->{'schemas'} = [@manual_schemas];
                if (defined $self->{'config'}->{'readers'} && ref($self->{'config'}->{'readers'}) eq 'ARRAY') {
                    foreach my $reader (@{$self->{'config'}->{'readers'}}) {
                        $self->{'config'}->{'readers'}->{$reader}->{'schemas'} = [@manual_schemas];
                    }
                }
            }
        }
    }

    my ($i);

    # if we still don't have a config, use the package-matching option
    if ($found_config != 1) {
        my @packages;
        for ($i = 0; my @p = caller($i); $i++) {
            push(@packages, $p[0]) unless $p[0] eq 'main';
        }
        if (scalar(@packages) > 0) {
            eval(q|$self->{'config'} = DBIx::DataStore::Config::match_store(\@packages)|);
            if ($@ || !defined $self->{'config'}) {
                dslog(q{Locating configuration based on packages in stack failed.}) if DEBUG();
            } else {
                $found_config = 1;
            }
        }
    }

    # if that still doesn't work, return the default-marked configuration
    if ($found_config != 1) {
        eval(q|$self->{'config'} = DBIx::DataStore::Config::get_default()|);
        if ($@ || !defined $self->{'config'}) {
            die dslog(q{No configuration could be located and used for this connection!});
        }
    }

    # Validate connection to primary database
    $self->{'handles'} = {};
    unless ($self->{'handles'}->{'primary'} = _db_connect(
        cache => $self->{'config'}->{'cache_connections'},
        %{$self->{'config'}->{'primary'}})
    ) {
        die dslog("Validation of connection to primary database failed!");
    }
    $self->{'handles'}->{'primary'} = _set_schema_searchpath(
        $self->{'handles'}->{'primary'},
        $self->{'config'}->{'primary'}->{'driver'},
        $self->{'config'}->{'primary'}->{'schemas'}
    ) || die dslog(q{Error setting schema search path.});

    # Select the default reader DB
    my $num_readers = defined $self->{'config'}->{'readers'} && ref($self->{'config'}->{'readers'}) eq 'HASH'
        ? scalar keys %{$self->{'config'}->{'readers'}} : 0;

    $self->{'config'}->{'default_reader'} = $opts->{'reader'} if defined $opts->{'reader'};
    $self->{'config'}->{'default_reader'} = 'primary'
        if !defined $self->{'config'}->{'default_reader'}
        || lc($self->{'config'}->{'default_reader'}) eq 'none'
        || length($self->{'config'}->{'default_reader'}) < 1
        || $num_readers < 1;

    my @reader_list = ();

    # if a non-primary reader was selected (either in the YAML config or the opts hashref), populate
    # the reader_list array with candidates (__random will fill the list with all defined readers in
    # a randomized order; if a specific server was selected the list will contain only that entry)
    if (defined $self->{'config'}->{'default_reader'} && $self->{'config'}->{'default_reader'} ne 'primary') {
        if ($self->{'config'}->{'default_reader'} eq '__random') {
            if ($num_readers > 0) {
                @reader_list = keys %{$self->{'config'}->{'readers'}};
                $i = $#reader_list;
                while ($i--) {
                    my $j = int rand ($i+1);
                    @reader_list[$i,$j] = @reader_list[$j,$i];
                }
            }
        } else {
            die dslog("Non-existent reader database ($self->{'config'}->{'default_reader'}) selected!")
                unless exists $self->{'config'}->{'readers'}->{ $self->{'config'}->{'default_reader'} };
            @reader_list = ($self->{'config'}->{'default_reader'});
        }
    }

    if (scalar(@reader_list) < 1) {
        # if there is no selection for a reader, copy the objref of the primary DB
        $self->{'handles'}->{'reader'} = $self->{'handles'}->{'primary'};
        $self->{'config'}->{'default_reader'} = 'primary';
        $self->{'config'}->{'readers'} = { primary => $self->{'config'}->{'primary'} };
        $self->{'reader'} = 'primary';
    } else {
        my $found_reader = 0;
        foreach my $reader (@reader_list) {
            my ($dbh);
            if ($dbh = _db_connect(
                cache => $self->{'config'}->{'cache_connections'},
                %{$self->{'config'}->{'readers'}->{$reader}})
            ) {
                $self->{'handles'}->{'reader'} = _set_schema_searchpath(
                    $dbh,
                    $self->{'config'}->{'readers'}->{$reader}->{'driver'},
                    $self->{'config'}->{'readers'}->{$reader}->{'schemas'}
                );
                $self->{'reader'} = $reader;
                $found_reader = 1;
                last;
            }
        }

        if ($found_reader != 1) {
            die dslog("No valid connection could be made to a reader database!");
        }
    }

    # quick reference flag for whether AutoCommit was turned off on the primary DB
    $self->{'autocommit'} =
            defined $self->{'config'}->{'primary'}->{'dbd_opts'}
            && ref($self->{'config'}->{'primary'}->{'dbd_opts'}) eq 'HASH'
            && defined $self->{'config'}->{'primary'}->{'dbd_opts'}->{'AutoCommit'}
            && $self->{'config'}->{'primary'}->{'dbd_opts'}->{'AutoCommit'} == 0
        ? 0 : 1;

    # Init the "in transaction" flag
    $self->{'in_tx'} = 0;

    # Init the statement counter. This counter is used to check if there have
    # been any non-select statements issued to the primary DB since the last
    # commit() or rollback(). While technically it is incremented for each
    # non-select statement, it cannot be relied on for an exact count of the
    # statements since the last rollback()/commit(), as selective rollbacks
    # of savepoints or nested transactions will not reset this counter (it is
    # only reset by the rollback() method if that rollback has the side effect
    # of the in_tx flag == 0. Why bother if it's not an exact counter? I'm
    # glad you asked! When AutoCommit is turned off for the primary DB, this
    # counter is used to determine whether to silence warnings/errors on the
    # extraneous calls to transaction methods, particularly in DESTROY. For
    # the exact details of when this silencing will occur, check out the
    # code in the various transaction methods.
    $self->{'st_count'} = 0;

    # if AutoCommit is set to 0 for the primary server, we automatically start out inside a
    # transaction
    if ($self->{'autocommit'} == 0) {
        $self->{'in_tx'} = 1;
    }

    # set up arrayref to hold any error strings (usually DBI errors)
    $self->{'errors'} = [];

    return bless($self, $class);
}

sub base_tables {
    my ($self) = @_;

    my $driver = lc($self->{'config'}->{'primary'}->{'driver'});
    my $schema = $self->{'handles'}->{'primary'}->quote($self->{'config'}->{'primary'}->{'db'});

    my ($sql);

    if ($driver eq 'mysql') {
        $sql = qq{
            select table_name
            from information_schema.tables
            where table_schema in ($schema)
                and table_type = 'BASE TABLE'
            order by table_name asc
        };
    } elsif ($driver eq 'pg') {
        # make sure we only list the relations visible in the current search_path
        if (defined $self->{'config'}->{'primary'}->{'schemas'}
                && ref($self->{'config'}->{'primary'}->{'schemas'}) eq 'ARRAY') {
            $schema = join(',', @{$self->{'config'}->{'primary'}->{'schemas'}});
        } else {
            $schema = q{'public'};
        }

        $sql = qq{
            select c.relname
            from pg_catalog.pg_class c
                join pg_catalog.pg_roles r on (r.oid = c.relowner)
                left join pg_catalog.pg_namespace n on (n.oid = c.relnamespace)
            where c.relkind in ('r')
                and n.nspname in ($schema)
                and pg_catalog.pg_table_is_visible(c.oid)
            order by relname asc
        };
    } elsif ($driver eq 'oracle') {
        $sql = q{
            select object_name
            from user_objects
            where object_type in ('TABLE')
            order by object_name asc
        };
    } elsif ($driver eq 'db2') {
        $sql = q{
            select tabname
            from syscat.tables
            where tabschema not like 'SYS%' and type in ('T')
            order by tabname asc
        };
    } else {
        die dslog("This method is not yet implemented for your database server ($driver).");
    }

    my $res = $self->do($sql);

    if ($res) {
        my @tables = ();

        while ($res->next) {
            push(@tables, $res->[0]);
        }

        return @tables;
    } else {
        die dslog("Error encountered when retrieving list of tables: $DBI::errstr");
    }
}

sub begin {
    my ($self) = shift;

    die dslog("Somehow there appears to be no driver defined for the primary database!")
        unless defined $self->{'config'}->{'primary'}->{'driver'};

    my $driver = lc($self->{'config'}->{'primary'}->{'driver'});

    # If AutoCommit is turned off, new transactions are automatically started on
    # connect and immediately after any existing transactions are closed (either
    # through commit or rollback). This has the side-effect of causing begin()
    # to trigger a fatal error from DBI's begin_work() every time it is called
    # (in the "DBI Way of Doing Things" you never actually call begin_work()
    # yourself if you turn off AutoCommit). Personally, I find this annoying
    # and a bit counter-intuitive, so DBIx::DataStore will let you call begin()
    # if you are currently in one of the implicitly created transactions and
    # you have AutoCommit turned off *and* you have issued NO non-select
    # statements to the database since either a) connecting or b) closing the
    # last transaction.
    if ($self->{'st_count'} == 0 && $self->{'in_tx'} == 1 && $self->{'autocommit'} == 0) {
        return 1;
    }

    # We need to make sure the primary database server supports transactions,
    # and further that it supports nested transactions if we're already inside
    # one when ->begin() is called.
    if ($driver eq 'mysql') {
        if ($self->{'in_tx'} > 0) {
            die dslog("MySQL does not support nested transactions!");
        }
    } elsif ($driver eq 'pg') {
        if ($self->{'in_tx'} > 0) {
            die dslog("PostgreSQL does not support nested transactions (use savepoints instead)!");
        }
    } elsif ($driver eq 'sqlite') {
        if ($self->{'in_tx'} > 0) {
            die dslog("SQLite does not support nested transactions!");
        }
    } elsif ($driver eq 'db2') {
        if ($self->{'in_tx'} > 0) {
            die dslog("DB2 does not support nested transactions (use savepoints instead)!");
        }
    }

    $self->{'handles'}->{'primary'}->begin_work
        || die dslog("Error encountered during attempt to begin transaction: $DBI::errstr");

    $self->{'in_tx'}++;
    return 1;
}

sub commit {
    my ($self) = @_;

    die dslog("Commit attempted without any open transactions!") unless $self->{'in_tx'} > 0;

    $self->{'handles'}->{'primary'}->commit
        || die dslog("Error encountered during attempt to commit transaction: $DBI::errstr");

    $self->{'in_tx'}--;
    $self->{'st_count'} = 0;

    # if AutoCommit is turned off on the primary DB, then the closing of a transaction
    # (either through a rollback or commit) automatically begins a new transaction, in
    # which case we need to re-increment the in_tx count
    if ($self->{'autocommit'} == 0) {
        $self->{'in_tx'}++;
    }

    # reset the search path when AutoCommit is turned off (since everything, including
    # the initial setting of this on connect happens within transactions)
    if ($self->{'autocommit'} == 0 && defined $self->{'config'}->{'primary'}->{'schemas'}) {
        _set_schema_searchpath($self->{'handles'}->{'primary'}, $self->{'config'}->{'primary'}->{'driver'},
            $self->{'config'}->{'primary'}->{'schemas'});
    }

    return 1;
}

sub databases {
    my ($self) = @_;

    my $driver = lc($self->{'config'}->{'primary'}->{'driver'});

    my ($sql);

    if ($driver eq 'mysql') {
        $sql = q{
            select schema_name
            from information_schema.schemata
            where schema_name not in ('information_schema','cluster')
            order by schema_name asc
        };
    } elsif ($driver eq 'pg') {
        $sql = q{
            select d.datname
            from pg_catalog.pg_database d
                join pg_catalog.pg_roles r on (d.datdba = r.oid)
            where datname not in ('postgres')
                and datname not like 'template%'
            order by datname asc
        };
    } elsif ($driver eq 'db2') {
        $sql = q{
            select schemaname
            from syscat.schemata
            where schemaname not like 'SYS%'
            order by schemaname asc
        };
    } else {
        die dslog("This method is not yet implemented for your database server ($driver).");
    }

    my $res = $self->do($sql);

    if ($res) {
        my @schemas = ();

        while ($res->next) {
            push(@schemas, $res->[0]);
        }

        return @schemas;
    } else {
        die dslog("Error encountered when retrieving list of database schemas: $DBI::errstr");
    }
}

sub db_primary {
    my ($self) = @_;

    my %config = %{$self->{'config'}->{'primary'}};
    $config{'name'} = 'primary';

    # remove "sensitive" fields from config
    delete $config{'pass'} if defined $config{'pass'};

    return { %config };
}

sub db_reader {
    my ($self) = @_;

    return unless defined $self->{'config'}->{'default_reader'}
        && exists $self->{'config'}->{'readers'}->{$self->{'config'}->{'default_reader'}};

    my %config = %{$self->{'config'}->{'readers'}->{$self->{'config'}->{'default_reader'}}};

    delete $config{'pass'} if defined $config{'pass'};

    return { %config };
}

sub do {
    my ($self, @args) = @_;

    my $opts = {};

    # check first argument to see if options hashref was passed in before a SQL statement
    if (scalar(@args) > 1 && ref($args[0]) eq 'HASH') {
        $opts = shift @args;
    }

    # Default the pager settings unless caller passed in their own values. A
    # "page" value of <=0 denotes no paging to be used (IOW the query will not
    # be limited (at least by us -- the caller might have their own LIMIT in
    # there) and all possible results from the database will be available.
    $opts->{'per_page'} = 25 unless defined $opts->{'per_page'} && $opts->{'per_page'} =~ /^\d+$/o;
    $opts->{'page'} = -1 unless defined $opts->{'page'} && $opts->{'page'} =~ /^\d+$/o;

    # allow for overriding of statement preparation & caching on a per-query basis
    $opts->{'prepare'} = $self->{'config'}->{'prepare_statements'}
            unless defined $opts->{'prepare'} && $opts->{'prepare'} =~ /^\d+$/o;

    # pass the rest straight through for conversion from convenient-bindings to normal-bindings
    my ($st_type, $sql, @binds) = _transform_bindings(@args);

    # Figure out which DB handler we'll be using. If we're inside of a transaction,
    # it has to be the primary DB. But if we're not, then we check whether
    # reader_failover is turned on; if it is not, we just blindly set the currently
    # selected reader's handle, otherwise we go through the ping tests (keeping in
    # mind the flag_bad_readers setting as well) to find a new reader DB if the
    # current one doesn't succeed
    my $dbh;
    if ($self->{'in_tx'} > 0 || $st_type ne 'select') {
        $dbh = $self->{'handles'}->{'primary'};
    } else {
        if (exists $self->{'config'}->{'reader_failover'} && $self->{'config'}->{'reader_failover'} == 1) {
            my $flag_bad = exists $self->{'config'}->{'flag_bad_readers'} && $self->{'config'}->{'flag_bad_readers'} == 1
                ? 1 : 0;
            if (!$self->{'handles'}->{'reader'}->do("select 1")) {
                if ($self->{'config'}->{'default_reader'} eq 'primary') {
                    # current reader was the primary DB... we're in trouble now
                    die dslog("Primary database server failed connectivity test.");
                }

                my $reader_found = 0;
                # if flag_bad_readers is not turned on, we need to have a quasi-reasonable limit to the number
                # attempts we'll make to find a new reader, since the @new_readers list will never exhaust
                # itself (all readers will end up in it every single time, just in a random order)
                my $check_limit = scalar(keys(%{$self->{'config'}->{'readers'}})) * 2;

                CHECK_READER:
                while (!$reader_found) {
                    if ($check_limit < 1) {
                        dslog("Exhausted connection attempts to new reader databases. Giving up.") if DEBUG();
                        last CHECK_READER;
                    }
                    dslog("Current reader $self->{'config'}->{'default_reader'} failed ping test. Choosing new reader.")
                        if DEBUG();

                    my (@new_readers);
                    if ($flag_bad) {
                        $self->{'config'}->{'readers'}->{ $self->{'config'}->{'default_reader'} }->{'failure'} = time();
                        @new_readers = grep { !exists $self->{'config'}->{'readers'}->{$_}->{'failure'} }
                            keys %{$self->{'config'}->{'readers'}};
                    } else {
                        @new_readers = keys %{$self->{'config'}->{'readers'}};
                    }

                    last CHECK_READER if scalar(@new_readers) < 1;

                    # randomly sort the new reader DB list
                    my $i = $#new_readers;
                    while ($i--) {
                        my $j = int rand ($i+1);
                        @new_readers[$i,$j] = @new_readers[$j,$i];
                    }

                    my $reader = $new_readers[0];

                    if ($dbh = _db_connect(
                        cache => $self->{'config'}->{'cache_connections'},
                        %{$self->{'config'}->{'readers'}->{$reader}}))
                    {
                        # touch of extra paranoia... make sure we really did connect properly (since
                        # there is an ever-so-slight chance that connection caching, if turned on,
                        # might be deceiving us)
                        if ($dbh->do("select 1")) {
                            $self->{'config'}->{'default_reader'} = $reader;
                            $self->{'handles'}->{'reader'} = $dbh;
                            $reader_found = 1;
                        }
                    }
                    $check_limit--;
                }

                # if a new reader wasn't found, make one last attempt by pinging the primary and using it
                if (!$reader_found) {
                    if ($self->{'handles'}->{'primary'}->do("select 1")) {
                        $self->{'handles'}->{'reader'} = $self->{'handles'}->{'primary'};
                        $self->{'config'}->{'default_reader'} = 'primary';
                        $dbh = $self->{'handles'}->{'primary'};
                    } else {
                        die dslog("Failure attempting to fall back on primary database for reads after all readers failed.");
                    }
                }
            } else {
                $dbh = $self->{'handles'}->{'reader'};
            }
        } else {
            $dbh = $self->{'handles'}->{'reader'};
        }
    }

    # if we intend to bypass normal statement preparation with placeholders, we need to
    # now replace all of them with their actual values (properly quoted, of course) so
    # the underlying DBD::* driver doesn't spend time on this
    if (!$opts->{'prepare'}) {
        dslog("Manually replacing placeholders prior to statement execution.") if DEBUG();
        $sql =~ s{(\s+|,|\(|\=)\?(\s*)}{$1 . $dbh->quote(shift(@binds)) . $2}egsix;
    }

    my $unpaged_sql = $sql;

    if ($opts->{'page'} > 0) {
        # Caller wants auto-paging, so validate that the original query doesn't end with a
        # LIMIT clause and add our own
        my $driver = $self->{'in_tx'} > 0
            ? lc($self->{'config'}->{'primary'}->{'driver'})
            : lc($self->{'config'}->{'readers'}->{$self->{'config'}->{'default_reader'}}->{'driver'});

        # Warn if it appears there is already a limiting clause in the original query (but in
        # the event we misidentify something else as a limiting clause, give it a chance to run
        # and let the database server reject it if it really is invalid).
        if ($sql =~ /limit\s+\d+(\s+offset\s+\d+|\s*,\s*\d+)\s*$/ois
            || $sql =~ /rows\s+\d+(\s+to\s+\d+)\s*$/ois
        ) {
            dslog("Paging requested on a query that appears to already have a limiting clause. Attempting anyway.")
                if DEBUG();
        }

        my $limit_offset = ($opts->{'page'} - 1) * $opts->{'per_page'};
        $limit_offset = 0 unless $limit_offset > 0;
        my $limit_last = $limit_offset + $opts->{'per_page'} - 1;

        # Add appropriate limiting clause syntax based on current database server
        if (exists { map { $_ => '' } qw( mysql pg sqlite ) }->{$driver}) {
            $sql .= qq{ limit $opts->{'per_page'} offset $limit_offset };
        } elsif (exists { map { $_ => '' } qw( interbase firebird ) }->{$driver}) {
            $sql .= qq{ rows $limit_offset to $limit_last };
        } else {
            # TODO: Possibly use SQL::Abstract::Limit to handle other databases (which all pretty
            # pretty much support much more complicated ways of achieving the same effect).
            die dslog("Automated result set paging is not currently supported for this database server ($driver). Sorry.");
        }
    }

    # prepare & execute the query
    my ($dbi_res, $sth);

    my $error = 0;

    if ($opts->{'prepare'}) {
        if (defined $self->{'config'}->{'cache_statements'} && $self->{'config'}->{'cache_statements'} == 1) {
            # DBI prepare_cached's "if_active" argument (the third one) is passed in as 3 since
            # that is supposed to be the safest method (if there's a cached version of the same
            # query, but it's currently active, it's removed from the cache and a new statement
            # is created -- thus the currently-active handle that was in the cache is not
            # affected in any way by what may be done with the new handle)
            unless ($sth = $dbh->prepare_cached($sql, $opts, 3)) {
                dslog("Error encountered when preparing cached SQL statement: $DBI::errstr") if DEBUG();
                $error = 1;
            }
        } else {
            unless ($sth = $dbh->prepare($sql, $opts)) {
                dslog("Error encountered when preparing SQL statement: $DBI::errstr") if DEBUG();
                $error = 1;
            }
        }

        if ($error == 0) {
            unless ($dbi_res = $sth->execute(@binds)) {
                dslog("Error encountered when executing SQL statement: $DBI::errstr") if DEBUG();
                $error = 1;
            }
        }
    } else {
        # query will run without prior preparation (this can be desired with some databases on
        # various queries where to come up with the best (or even a reasonable) plan requires
        # the database's planner to know the actual values instead of having placeholders)...
        # if we're in here, it also means that _transform_binds() removed all the placeholders
        # and put in the actual values, so we don't need to pass @binds into execute()
        if ($st_type ne 'select' && $sql !~ /\s+returning\s+\w+(\s*,\s*\w+)*\s*/ois) {
            # no intermediary statement handler necessary, since we're apparently issuing
            # non-SELECT DML that does not end with a RETURNING clause
            $sth = { NAME => [], NAME_hash => [] }; # dummy these up so we don't die below

            unless ($dbi_res = $dbh->do($sql)) {
                dslog("Error calling DBI do() method on pre-bound, unprepared SQL statement: $DBI::errstr") if DEBUG();
                $error = 1;
            }
        } else {
            if ($sth = $dbh->prepare($sql, $opts)) {
                unless ($dbi_res = $sth->execute()) {
                    dslog("Error executing pre-bound SQL statement: $DBI::errstr") if DEBUG();
                    $error = 1;
                }
            } else {
                dslog("Error encountered preparing pre-bound SQL statement: $DBI::errstr") if DEBUG();
                $error = 1;
            }
        }
    }

    $self->{'st_count'}++ unless $st_type eq 'select';

    # Set up skeleton for a DBIx::DataStore::ResultSet object
    my $results = DBIx::DataStore::ResultRow->new({},{},[]);
    bless($results, 'DBIx::DataStore::ResultSet');

    $$results->{'error'} = $DBI::errstr if $error;

    $$results->{'_st_type'} = $st_type;
    $$results->{'_sql'} = $unpaged_sql;
    $$results->{'_binds'} = [ @binds ];

    $$results->{'_rows'} = $dbi_res;
    $$results->{'_dbh'} = $dbh;
    $$results->{'_sth'} = $sth;

    $$results->{'_page_num'} = $opts->{'page'};
    $$results->{'_page_per'} = $opts->{'per_page'};

    $$results->{'impl'}->[DBIx::DataStore::ResultRow::KEYS()] = $sth->{'NAME'};
    $$results->{'impl'}->[DBIx::DataStore::ResultRow::INDEX()] = $sth->{'NAME_hash'};

    return $results;
}

sub in_transaction {
    my ($self) = @_;

    return 1 if defined $self->{'in_tx'} && $self->{'in_tx'} > 0;
    return;
}

sub last_insert_id {
    my ($self, @args) = @_;

    my $driver = lc($self->{'config'}->{'primary'}->{'driver'});

    # fill in pass-through args with dummy values, since MySQL & Informix don't actually
    # support the full possibilities of this DBI function
    if (exists { map { $_ => '' } qw( mysql informix ) }->{$driver}) {
        $args[$_] = 'X' for (1..3);
    }

    if (my $id = $self->{'handles'}->{'primary'}->last_insert_id(@args)) {
        return $id;
    } else {
        die dslog("Error obtaining the Last Insert ID: $DBI::errstr");
    }
}

sub ping {
    my ($self) = @_;

    # Make sure we don't double-ping the primary server if it is both primary & reader
    my @servers = $self->{'config'}->{'default_reader'} eq 'primary' ? qw( primary ) : qw( primary reader );

    foreach my $server (@servers) {
        if (!$self->{'handles'}->{$server}->do("select 1")) {
            dslog("Error pinging $server database server: " . $self->{'handles'}->{$server}->errstr) if DEBUG();
            return;
        }
    }

    return 1;
}

sub rollback {
    my ($self, $savepoint) = @_;

    die dslog("Rollback attempted without any open transactions!") unless $self->{'in_tx'} > 0;

    # If a savepoint name was passed in, we have to issue the rollback statement ourselves,
    # since DBI doesn't support that syntax through it's rollback() method and an informally
    # proposed rollbackto() method on dbi-users hasn't been accepted by the DBI devs yet.
    if (defined $savepoint) {
        my $driver = lc($self->{'config'}->{'primary'}->{'driver'});
        my ($sql);

        if ($driver eq 'sybase') {
            die dslog("Savepoints are not supported by Sybase!");
        } elsif ($driver eq 'pg') {
            if (!$self->{'handles'}->{'primary'}->pg_rollback_to($savepoint)) {
                die dslog("Error rolling back to savepoint '$savepoint':", $self->{'handles'}->{'primary'}->errstr);
            }
        } else {
            $savepoint = $self->{'handles'}->{'primary'}->quote($savepoint)
                || die dslog("Error encountered when safe-quoting savepoint name:", $self->{'handles'}->{'primary'}->errstr);

            $sql = qq{ rollback to savepoint $savepoint };

            if (!$self->{'handles'}->{'primary'}->do($sql)) {
                die dslog("Error rolling back to savepoint '$savepoint':", $self->{'handles'}->{'primary'}->errstr);
            }
        }

        # Note that we do not decrement the transaction level counter, since we rolled
        # back *within* a transaction, we didn't rollback the transaction itself.
    } else {
        $self->{'handles'}->{'primary'}->rollback
            || die dslog("Error encountered during attempt to roll back transaction: $DBI::errstr");

        $self->{'in_tx'}--;
        $self->{'st_count'} = 0;
    }

    # if AutoCommit is turned off on the primary DB, then the closing of a transaction
    # (either through a rollback or commit) automatically begins a new transaction, in
    # which case we need to re-increment the in_tx count
    if ($self->{'autocommit'} == 0) {
        $self->{'in_tx'}++;
    }

    # reset schema search path if AutoCommit is turned off (since the setting of the
    # search path on connect would have occurred inside a transaction -- how annoying)
    if ($self->{'autocommit'} == 0 && defined $self->{'config'}->{'primary'}->{'schemas'}) {
        _set_schema_searchpath($self->{'handles'}->{'primary'}, $self->{'config'}->{'primary'}->{'driver'},
            $self->{'config'}->{'primary'}->{'schemas'});
    }

    return 1;
}

sub savepoint {
    my ($self, $savepoint) = @_;

    die dslog("Cannot create a savepoint outside of a transaction context!") unless $self->{'in_tx'} > 0;
    die dslog("No savepoint name was provided!") unless defined $savepoint && $savepoint =~ /\w+/o;

    my $driver = lc($self->{'config'}->{'primary'}->{'driver'});

    # DBI does not provide savepoint related methods (yet, at least -- there's been discussion
    # on the mailing lists about whether or not it should, and if so what they should be), so
    # we need to just build the statement ourself and issue it.
    my ($sql);

    if ($driver eq 'sybase') {
        die dslog("Sybase does not support transaction savepoints!");
    } elsif ($driver eq 'pg') {
        if (!$self->{'handles'}->{'primary'}->pg_savepoint($savepoint)) {
            die dslog("Error creating transaction savepoint '$savepoint': " . $self->{'handles'}->{'primary'}->errstr);
        }
    } else {
        $savepoint = $self->{'handles'}->{'primary'}->quote($savepoint)
            || die dslog("Error encountered when safe-quoting savepoint name: " . $self->{'handles'}->{'primary'}->errstr);

        $sql = qq{ savepoint $savepoint };

        if (!$self->{'handles'}->{'primary'}->do($sql)) {
            die dslog("Error creating transaction savepoint '$savepoint': " . $self->{'handles'}->{'primary'}->errstr);
        }
    }

    return 1;
}

sub schemas {
    my ($self, $schemas) = @_;

    if (defined $schemas && ref($schemas) eq 'ARRAY') {
        dslog(q{Got request to change schemas on existing connection.}) if DEBUG() >= 2;
        $self->{'config'}->{'primary'}->{'schemas'} = [@{$schemas}];
        $self->{'config'}->{'readers'}->{$self->{'reader'}}->{'schemas'} = $self->{'config'}->{'primary'}->{'schemas'}
            if $self->{'reader'} ne 'primary';
        _set_schema_searchpath(
            $self->{'handles'}->{'primary'},
            $self->{'config'}->{'primary'}->{'driver'},
            $schemas
        );
        _set_schema_searchpath(
            $self->{'handles'}->{'reader'},
            $self->{'config'}->{'readers'}->{$self->{'reader'}}->{'driver'},
            $schemas
        ) if $self->{'reader'} ne 'primary';
    } else {
        dslog(q{Current schema search path requested.}) if DEBUG() >= 4;
        return @{$self->{'config'}->{'primary'}->{'schemas'}}
            if defined $self->{'config'}->{'primary'}->{'schemas'}
                && ref($self->{'config'}->{'primary'}->{'schemas'}) eq 'ARRAY'
                && scalar(@{$self->{'config'}->{'primary'}->{'schemas'}}) > 0;
    }

    return;
}

sub servers {
    my ($self) = @_;

    my @servers = ();

    my %config = %{$self->{'config'}->{'primary'}};
    $config{'name'} = 'primary';
    delete $config{'password'} if defined $config{'password'};

    push(@servers, { %config });

    foreach my $reader (sort keys %{$self->{'config'}->{'readers'}}) {
        %config = %{$self->{'config'}->{'readers'}->{$reader}};
        delete $config{'password'} if defined $config{'password'};
        $config{'name'} = $reader;
        push(@servers, { %config });
    }

    return @servers;
}

sub tables {
    my ($self) = @_;

    my $driver = lc($self->{'config'}->{'primary'}->{'driver'});
    my $schema = $self->{'handles'}->{'primary'}->quote($self->{'config'}->{'primary'}->{'db'});

    my ($sql);

    if ($driver eq 'mysql') {
        $sql = qq{
            select table_name
            from information_schema.tables
            where table_schema in ($schema)
            order by table_name asc
        };
    } elsif ($driver eq 'pg') {
        # make sure we only list the relations visible in the current search_path
        if (defined $self->{'config'}->{'primary'}->{'schemas'}
                && ref($self->{'config'}->{'primary'}->{'schemas'}) eq 'ARRAY') {
            $schema = join(',', @{$self->{'config'}->{'primary'}->{'schemas'}});
        } else {
            $schema = q{'public'};
        }

        $sql = qq{
            select c.relname
            from pg_catalog.pg_class c
                join pg_catalog.pg_roles r on (r.oid = c.relowner)
                left join pg_catalog.pg_namespace n on (n.oid = c.relnamespace)
            where c.relkind in ('r','v')
                and n.nspname in ($schema)
                and pg_catalog.pg_table_is_visible(c.oid)
            order by relname asc
        };
    } elsif ($driver eq 'oracle') {
        $sql = q{
            select object_name
            from user_objects
            where object_type in ('TABLE','VIEW')
            order by object_name asc
        };
    } elsif ($driver eq 'db2') {
        $sql = q{
            select tabname
            from syscat.tables
            where tabschema not like 'SYS%' and type in ('T','V')
            order by tabname asc
        };
    } else {
        die dslog("This method is not yet implemented for your database server ($driver).");
    }

    my $res = $self->do($sql);

    if ($res) {
        my @tables = ();

        while ($res->next) {
            push(@tables, $res->[0]);
        }

        return @tables;
    } else {
        die dslog("Error encountered when retrieving list of tables: $DBI::errstr");
    }
}

sub views {
    my ($self) = @_;

    my $driver = lc($self->{'config'}->{'primary'}->{'driver'});
    my $schema = $self->{'handles'}->{'primary'}->quote($self->{'config'}->{'primary'}->{'db'});

    my ($sql);

    if ($driver eq 'mysql') {
        $sql = qq{
            select table_name
            from information_schema.tables
            where table_schema in ($schema)
                and table_type = 'VIEW'
            order by table_name asc
        };
    } elsif ($driver eq 'pg') {
        # make sure we only list the relations visible in the current search_path
        if (defined $self->{'config'}->{'primary'}->{'schemas'}
                && ref($self->{'config'}->{'primary'}->{'schemas'}) eq 'ARRAY') {
            $schema = join(',', @{$self->{'config'}->{'primary'}->{'schemas'}});
        } else {
            $schema = q{'public'};
        }

        $sql = qq{
            select c.relname
            from pg_catalog.pg_class c
                join pg_catalog.pg_roles r on (r.oid = c.relowner)
                left join pg_catalog.pg_namespace n on (n.oid = c.relnamespace)
            where c.relkind in ('v')
                and n.nspname in ($schema)
                and pg_catalog.pg_table_is_visible(c.oid)
            order by relname asc
        };
    } elsif ($driver eq 'oracle') {
        $sql = q{
            select object_name
            from user_objects
            where object_type = 'VIEW'
            order by object_name asc
        };
    } elsif ($driver eq 'db2') {
        $sql = q{
            select tabname
            from syscat.tables
            where tabschema not like 'SYS%' and type in ('V')
            order by tabname asc
        };
    } else {
        die dslog("This method is not yet implemented for your database server ($driver).");
    }

    my $res = $self->do($sql);

    if ($res) {
        my @views = ();

        while ($res->next) {
            push(@views, $res->[0]);
        }

        return @views;
    } else {
        die dslog("Error encountered when retrieving list of tables: $DBI::errstr");
    }
}

#######################################################################
# Internal/Private Subroutines

sub DESTROY {
    my ($self) = shift;

    # If primary handle is in a transaction, cluck out a warning and issue a rollback
    # (Note that the while{} is used to support nested-transactions, assuming the
    # underlying DB supports them -- whether nested transactions are supported is
    # actually checked elsewhere, so if it isn't this while loop will only ever
    # have a single iteration).
    while ($self->{'in_tx'} > 0) {
        # Don't issue the warning when AutoCommit is turned off, we're in an implicitly created
        # transaction and no non-select statements have been issued in the current transaction
        unless ($self->{'st_count'} == 0 && $self->{'in_tx'} == 1 && $self->{'autocommit'} == 0) {
            dslog("Database connection killed during a transaction!") if DEBUG();
        }
        $self->{'handles'}->{'primary'}->rollback
            || dslog("Attempted to rollback unclosed transaction but failed: $DBI::errstr");
        $self->{'in_tx'}--;
    }
}

sub _db_connect {
    my %args = (
        cache        => 0,
        dbd_opts    => {},
        @_,
    );

    my ($dsn);

    # if a custom DSN was present in the configuration, then just use it
    if (defined $args{'dsn'} && length($args{'dsn'}) > 0) {
        # Required DBI connection arguments when manual DSN specified
        foreach (qw( driver )) {
            if (!exists $args{$_}) {
                dslog("DBI connection attempted without providing '$_' argument!") if DEBUG() >= 3;
                return;
            }
        }

        $dsn = $args{'dsn'};
    # otherwise, build the DSN ourselves
    } else {
        # Required DBI connection arguments
        foreach (qw( driver database host )) {
            if (!exists $args{$_}) {
                dslog("DBI connection attempted without providing '$_' argument!") if DEBUG() >= 3;
                return;
            }
        }

        # Technically optional arguments that are almost always actually required for a good connection
        foreach (qw( user password )) {
            if (!exists $args{$_}) {
                dslog("DBI connection arguments do not contain '$_' argument. We'll try connecting anyway.") if DEBUG() >= 3;
                $args{$_} = '';
            }
        }

        $dsn = qq|dbi:$args{'driver'}:database=$args{'database'};host=$args{'host'}|;
        $dsn .= qq|;port=$args{'port'}| if defined $args{'port'} && $args{'port'} =~ /^\d+$/;
    }

    dslog(q{Connecting with DSN}, $dsn) if DEBUG();

    my ($dbh);

    # if DBI connection caching is desired, use connect_cached() method instead
    # also, issue immediate rollback after connecting, just in case we've been
    # returned a stale cached connection that had never closed its transaction
    if ($args{'cache'} && ($dbh = DBI->connect_cached($dsn, $args{'user'}, $args{'password'}, $args{'dbd_opts'}))) {
        $dbh->rollback if $dbh->ping >= 3;
        dslog(q{Returning DB connection from DBI's connect_cached.}) if DEBUG() >= 3;
        return $dbh;
    } elsif (!$args{'cache'} && ($dbh = DBI->connect($dsn, $args{'user'}, $args{'password'}, $args{'dbd_opts'}))) {
        $dbh->rollback if $dbh->ping >= 3;
        dslog(q{Returning DB connection from DBI's connect.}) if DEBUG() >= 3;
        return $dbh;
    } else {
        dslog("DBI connection attempt failed: $DBI::errstr") if DEBUG();
        return;
    }

    return;
}

sub _set_schema_searchpath {
    my ($dbh, $driver, $schemas) = @_;

    dslog(q{Search path setter entered.}) if DEBUG() >= 4;

    if (!defined $driver) {
        dslog("No driver name supplied during search path configuration") if DEBUG();
        return;
    }

    # schema search path support is only available for PostgreSQL for now
    return $dbh unless lc($driver) eq 'pg';

    if (!defined $schemas || ref($schemas) ne 'ARRAY' || scalar(@{$schemas}) < 1) {
        dslog("No schema names provided for inclusion in search path") if DEBUG();
        return;
    }

    dslog(q{Changing connection's schema search path to}, join(', ', @{$schemas})) if DEBUG() >= 2;

    # quote the schema names for paranoia
    my @s;
    push(@s, $dbh->quote($_)) for @{$schemas};

    my ($sql);

    if (lc($driver) eq 'pg') {
        $sql = 'set search_path to ' . join(', ', @s);
    }

    if (length($sql) > 0) {
        if ($dbh->do($sql)) {
            return $dbh;
        } else {
            dslog(q{Error occurred when setting schema search path:}, $dbh->errstr);
            return;
        }
    } else {
        dslog(q{No SQL to issue for setting schemas.}) if DEBUG() >= 2;
        return $dbh;
    }

    return;
}

sub _transform_bindings {
    my ($sql, @binds) = @_;

    # certain SQL statement types allow different styles of binding (i.e. hashrefs for insert/update
    # but not select, delete, create, etc.)
    $sql =~ s/(^\s+|\s+$)//os;
    my $st_type = lc( ($sql =~ /^(\w+)\s+/os)[0] );
    $st_type = 'select' if $st_type eq 'with'; # ugh (stupid workaround for legacy DataStore - rewrite is/will be much smarter about this and not just take random stabs in the dark)

    # if no bound variables were passed in, we can save a few cycles by returning right here
    return ($st_type, $sql) if !@binds || scalar(@binds) < 1;

    my @final_binds = ();

    # verify that binds passed in are appropriate for the type of statement being used
    if ($st_type eq 'update' && $sql =~ /\s+set\s+$HASH_PH/ois && (scalar(@binds) < 1 || ref($binds[0]) ne 'HASH')) {
        die dslog("First bind on UPDATE statements must be a hash reference when not using an explicit SET clause!");
    } elsif ($st_type eq 'insert' && $sql =~ /^\s*insert\s+into\s+\S+\s+(values\s+)?$HASH_PH/ois
            && (scalar(@binds) < 1 || !(ref($binds[0]) eq 'ARRAY' || ref($binds[0]) eq 'HASH'))) {
        die dslog("First bind on INSERT must be hash reference (or array reference of hash references) when using "
            . "a hash placeholder in the columns-values clause!");
    } elsif ($st_type eq 'select' && scalar(@binds) > 0) {
        foreach (@binds) {
            if (ref($_) eq 'HASH') {
                die dslog("Hash reference binds not permitted for SELECT statements!");
            }
        }
    }

    # for update statements, rework the first placeholder into a "set key = ?, ..." form and take
    # it off the list of binds. this is only done if a hashref placeholder was used, though
    if ($st_type eq 'update' && $sql =~ /$HASH_PH/o) {
        if ($sql =~ s/(set\s+)$HASH_PH(\s*)/ $1 . join(', ', map { "$_ = ?" } sort keys %{$binds[0]}) . $2 /siex) {
            push(@final_binds, $binds[0]->{$_}) for sort keys %{$binds[0]};
            # remove the bind from the list so that the catch-all bind code down below doesn't
            # try to reuse it (since updates can, and almost always will, have additional binds
            # after the hashref in the SET clause)
            shift @binds;
        }
    }

    # -- this only happens when a hash placeholder is used in the col-vals clause of an insert --
    # for insert statements, we need to figure out which columns we're inserting, place those
    # into $sql, then add the actual values list(s)' placeholders... however, we only do
    # any of this if the caller used a '???' placeholder in the query (if the caller passed in
    # something like "insert into tblX (a,b,c) values (?,?,?)" then we won't do anything
    # special here, and the placeholders will just be handled by the catch-all code lower down
    if ($st_type eq 'insert' && $sql =~ /^\s*insert\s+into\s+\S+\s+(values\s+)?$HASH_PH/ois) {
        my @cols = ();
        if (ref($binds[0]) eq 'HASH') {
            @cols = sort keys %{$binds[0]};
        } elsif (ref($binds[0]) eq 'ARRAY') {
            @cols = sort keys %{$binds[0]->[0]};
        }

        die dslog("No columns defined for insert statement!") if scalar(@cols) < 1;

        my $ph_replacement = '(' . join(',', @cols) . ') values ';

        my $rec_count = ref($binds[0]) eq 'ARRAY' ? scalar(@{$binds[0]}) : 1;

        $ph_replacement .= join(', ', ('(' . join(',', ('?') x scalar(@cols)) . ')') x $rec_count);

        $sql =~ s/^(\s*insert\s+into\s+\S+)\s+(?:values\s+)?$HASH_PH\s+(.*)/$1 $ph_replacement $2/si;

        if (ref($binds[0]) eq 'ARRAY') {
            foreach my $rec (@{$binds[0]}) {
                push(@final_binds, $rec->{$_}) for @cols;
            }
        } else {
            push(@final_binds, $binds[0]->{$_}) for @cols;
        }

        # remove the first bind from the list in case there are others (almost exclusively
        # in the case where the insert is getting its values from a select)
        shift @binds;
    }

    # now that the special cases have been handled, we can loop through the remaining
    # binds, handling the arrayref ones (for IN (...) lists) as we run into them
    foreach my $bind (@binds) {
        if (ref($bind) eq 'ARRAY') {
            # arrayref binds can only be used with IN (...) lists or ARRAY[] constructors, so if we don't have
            # one available in $sql to modify, error out
            if ($sql =~ /((in\s+)([(]?\s*$ARRAY_PH\s*[)]?)|(array\s*\[\s*$ARRAY_PH\s*\]))/is) {
                my $ph_block = $1;
                if ($ph_block =~ /^in/is) {
                    if ($sql =~ s/(in\s+)([(]?\s*$ARRAY_PH\s*[)]?)/ $1 . '( ' . join(', ', ('?') x scalar(@{$bind})) . ' )' /siex) {
                        push(@final_binds, @{$bind});
                    }
                } elsif ($ph_block =~ /^array/is) {
                    if ($sql =~ s/\s*array\s*\[\s*$ARRAY_PH\s*\]/ ' array [ ' . join(', ', ('?') x scalar(@{$bind})) . ' ] ' /siex) {
                        push(@final_binds, @{$bind});
                    }
                } else {
                    die dslog("Encountered arrayref placeholder syntax that cannot be understood at this time");
                }
            } else {
                die dslog("Arrayref bind was used without corresponding array placeholder as part of an IN (...) list or an ARRAY[] constructor!");
            }
        } else {
            push(@final_binds, $bind);
        }
    }

    # need to "fix" the statement type value now for queries that use a RETURNING
    # clause at the end of an INSERT, UPDATE or DELETE... for placeholder binding
    # purposes we treat them as their real type, but for everything else in datastore
    # they should be treated as SELECTs since that's effectively what comes back
    # from the database
    if (scalar(grep { $st_type eq $_ } qw( insert update delete )) > 0 && $sql =~ m{\s+returning\s+(\*|\w)}ois) {
        $st_type = 'select';
    }

    dslog(q{Binding transformation completed. SQL is now [[}, $sql, q{]] with bindings [[}, join(', ', @final_binds), q{]]})
        if DEBUG() >= 2;

    return ($st_type, $sql, @final_binds);
}

1;
