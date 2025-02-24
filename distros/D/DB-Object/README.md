SYNOPSIS
========

        use DB::Object;

        my $dbh = DB::Object->connect({
            driver => 'Pg',
            conf_file => 'db-settings.json',
            database => 'webstore',
            host => 'localhost',
            login => 'store-admin',
            schema => 'auth',
            debug => 3,
        }) || bailout( "Unable to connect to sql server on host localhost: ", DB::Object->error );

        # Legacy regular query
        my $sth = $dbh->prepare( "SELECT login,name FROM login WHERE login='jack'" ) ||
        die( $dbh->errstr() );
        $sth->execute() || die( $sth->errstr() );
        my $ref = $sth->fetchrow_hashref();
        $sth->finish();

        # Get a list of databases;
        my @databases = $dbh->databases;
        # Doesn't exist? Create it:
        my $dbh2 = $dbh->create_db( 'webstore' );
        # Load some sql into it
        my $rv = $dbh2->do( $sql ) || die( $dbh->error );

        # Check a table exists
        $dbh->table_exists( 'customers' ) || die( "Cannot find the customers table!\n" );

        # Get list of tables, as array reference:
        my $tables = $dbh->tables;

        my $cust = $dbh->customers || die( "Cannot get customers object." );
        $cust->where( email => 'john@example.org' );
        my $str = $cust->delete->as_string;
        # Becomes: DELETE FROM customers WHERE email='john\@example.org'

        # Do some insert with transaction
        $dbh->begin_work;
        # Making some other inserts and updates here...
        my $cust_sth_ins = $cust->insert(
            first_name => 'Paul',
            last_name => 'Goldman',
            email => 'paul@example.org',
            active => 0,
        ) || do
        {
            # Rollback everything since the begin_work
            $dbh->rollback;
            die( "Error while create query to add data to table customers: " . $cust->error );
        };
        $result = $cust_sth_ins->as_string;
        # INSERT INTO customers (first_name, last_name, email, active) VALUES('Paul', 'Goldman', 'paul\@example.org', '0')
        $dbh->commit;
        # Get the last used insert id
        my $id = $dbh->last_insert_id();

        $cust->where( email => 'john@example.org' );
        $cust->order( 'last_name' );
        $cust->having( email => qr/\@example/ );
        $cust->limit( 10 );
        my $cust_sth_sel = $cust->select || die( "An error occurred while creating a query to select data frm table customers: " . $cust->error );
        # Becomes:
        # SELECT id, first_name, last_name, email, created, modified, active, created::ABSTIME::INTEGER AS created_unixtime, modified::ABSTIME::INTEGER AS modified_unixtime, CONCAT(first_name, ' ', last_name) AS name FROM customers WHERE email='john\@example.org' HAVING email ~ '\@example' ORDER BY last_name LIMIT 10

        $cust->reset;
        $cust->where( email => 'john@example.org' );
        my $cust_sth_upd = $cust->update( active => 0 )
        # Would become:
        # UPDATE ONLY customers SET active='0' WHERE email='john\@example.org'

        # Lets' dump the result of our query
        # First to STDERR
        $login->where( "login='jack'" );
        $login->select->dump();
        # Now dump the result to a file
        $login->select->dump( "my_file.txt" );

Using fields objects

        $cust->where( $dbh->OR( $cust->fo->email == 'john@example.org', $cust->fo->id == 2 ) );
        my $ref = $cust->select->fetchrow_hashref;

Doing some left join

        my $geo_tbl = $dbh->geoip || return( $self->error( "Unable to get the database object \"geoip\"." ) );
        my $name_tbl = $dbh->geoname || return( $self->error( "Unable to get the database object \"geoname\"." ) );
        $geo_tbl->as( 'i' );
        $name_tbl->as( 'l' );
        $geo_tbl->where( "INET '?'" << $geo_tbl->fo->network );
        $geo_tbl->alias( id => 'ip_id' );
        $name_tbl->alias( country_iso_code => 'code' );
        my $sth = $geo_tbl->select->join( $name_tbl, $geo_tbl->fo->geoname_id == $name_tbl->fo->geoname_id );
        # SELECT
        #     -- tables fields
        # FROM
        #     geoip AS i
        #     LEFT JOIN geoname AS l ON i.geoname_id = l.geoname_id
        # WHERE
        #     INET '?' << i.network

Using a promise
([Promise::Me](https://metacpan.org/pod/Promise::Me){.perl-module}) to
execute an asynchronous query:

        my $sth = $dbh->prepare( "SELECT some_slow_function(?)" ) || die( $dbh->error );
        my $p = $sth->promise(10)->then(sub
        {
            my $st = shift( @_ );
            my $ref = $st->fetchrow_hashref;
            my $obj = My::Module->new( %$ref );
        })->catch(sub
        {
            $log->warn( "Failed to execute query: ", @_ );
        });
        # Do other regular processing here
        # Get the My::Module object
        my( $obj ) = await( $p );

Sometimes, having placeholders in expression makes it difficult to work,
so you can use placeholder objects to make it work:

            my $P = $dbh->placeholder( type => 'inet' );
        $orders_tbl->where( $dbh->OR( $orders_tbl->fo->ip_addr == "inet $P", "inet $P" << $orders_tbl->fo->ip_addr ) );
        my $order_ip_sth = $orders_tbl->select( 'id' ) || fail( "An error has occurred while trying to create a select by ip query for table orders: " . $orders_tbl->error );
        # SELECT id FROM orders WHERE ip_addr = inet ? OR inet ? << ip_addr

VERSION
=======

        v0.10.4

DESCRIPTION
===========

[DB::Object](https://metacpan.org/pod/DB::Object){.perl-module} is a SQL
API much alike `DBI`, but with the added benefits that it formats
queries in a simple object oriented, chaining way.

So why use a private module instead of using that great `DBI` package?

At first, I started to inherit from `DBI` to conform to `perlmod` perl
manual page and to general perl coding guidlines. It became very quickly
a real hassle. Barely impossible to inherit, difficulty to handle error,
too much dependent from an API that changes its behaviour with new
versions. In short, I wanted a better, more accurate control over the
SQL connection and an easy way to format sql statement using an object
oriented approach.

So, [DB::Object](https://metacpan.org/pod/DB::Object){.perl-module} acts
as a convenient, modifiable wrapper that provides the programmer with an
intuitive, user-friendly, object oriented and hassle free interface.

However, if you use the power of this interface to prepare queries
conveniently, you should cache the resulting statement handler object,
because there is an obvious real cost penalty in preparing queries and
they absolutely do not need to be prepared each time. So you can do
something like:

        my $sth;
        unless( $sth = $dbh->cache_query_get( 'some_arbitrary_identifier' ) )
        {
            # prepare the query
            my $tbl = $dbh->some_table || die( $dbh->error );
            $tbl->where( id => '?' );
            $sth = $tbl->select || die( $tbl->error );
            $dbh->cache_query_set( some_arbitrary_identifier => $sth );
        }
        $sth->exec(12) || die( $sth->error );
        my $ref = $sth->fetchrow_hashref;

This will provide you with the convenience and power of
[DB::Object](https://metacpan.org/pod/DB::Object){.perl-module} while
keeping execution fast.

CONSTRUCTOR
===========

new
---

Create a new instance of
[DB::Object](https://metacpan.org/pod/DB::Object){.perl-module}. Nothing
much to say.

connect
-------

Provided with a `database`, `login`, `password`, `server`:\[`port`\],
`driver`, `schema`, and optional hash or hash reference of parameters
and this will issue a, possibly cached, database connection and return
the resulting database handler.

Create a new instance of
[DB::Object](https://metacpan.org/pod/DB::Object){.perl-module}, but
also attempts a connection to SQL server.

It can take either an array of value in the order database name, login,
password, host, driver and optionally schema, or it can take a has or
hash reference. The hash or hash reference attributes are as follow.

Note that if you provide connection options that are not among the
followings, this will return an error.

*cache\_connections*

:   Defaults to true.

    If true, this will instruct
    [DBI](https://metacpan.org/pod/DBI){.perl-module} to use
    [\"connect\_cached\" in
    DBI](https://metacpan.org/pod/DBI#connect_cached){.perl-module}
    instead of just [\"connect\" in
    DBI](https://metacpan.org/pod/DBI#connect){.perl-module}

    Beware that using cached connections can have some drawbacks, such
    as if you open a cached connection, enters into a transaction using
    [\"begin\_work\" in
    DB::Object](https://metacpan.org/pod/DB::Object#begin_work){.perl-module},
    then somewhere else in your code a call to a cached connection using
    the same parameters, which
    [DBI](https://metacpan.org/pod/DBI){.perl-module} will provide, but
    will reset the database handler parameters, including the
    `AutoCommit` that will have been temporarily set to false when you
    called [\"begin\_work\"](#begin_work){.perl-module}, and then you
    close your transaction by calling
    [\"rollback\"](#rollback){.perl-module} or
    [\"commit\"](#commit){.perl-module}, but it will trigger an error,
    because `AutoCommit` will have been reset on this cached connection
    to a true value. [\"rollback\"](#rollback){.perl-module} and
    [\"commit\"](#commit){.perl-module} require that `AutoCommit` be
    disabled, which [\"begin\_work\"](#begin_work){.perl-module}
    normally do.

    Thus, if you want to avoid using a cached connection, set this to
    false.

    More on this issue at [DBI
    documentation](https://metacpan.org/pod/DBI#connect_cached){.perl-module}

*database* or *DB\_NAME*

:   The database name you wish to connect to

*login* or *DB\_LOGIN*

:   The login used to access that database

*passwd* or *DB\_PASSWD*

:   The password that goes along

*host* or *DB\_HOST*

:   The server, that is hostname of the machine serving a SQL server.

*port* or *DB\_PORT*

:   The port to connect to

*driver* or *DB\_DRIVER*

:   The driver you want to use. It needs to be of the same type than the
    server you want to connect to. If you are connecting to a MySQL
    server, you would use `mysql`, if you would connecto to an Oracle
    server, you would use `oracle`.

    You need to make sure that those driver are properly installed in
    the system before attempting to connect.

    To install the required driver, you could start with the command
    line:

            perl -MCPAN -e shell

    which will provide you a special shell to install modules in a
    convenient way.

*schema* or *DB\_SCHEMA*

:   The schema to use to access the tables. Currently only used by
    PostgreSQL

*opt*

:   This takes a hash reference and contains the standard `DBI` options
    such as *PrintError*, *RaiseError*, *AutoCommit*, etc

*conf\_file* or *DB\_CON\_FILE*

:   This is used to specify a json connection configuration file. It can
    also provided via the environment variable *DB\_CON\_FILE*. It has
    the following structure:

            {
            "database": "some_database",
            "host": "db.example.com",
            "login": "sql_joe",
            "passwd": "some password",
            "driver": "Pg",
            "schema": "warehouse",
            "opt":
                {
                "RaiseError": false,
                "PrintError": true,
                "AutoCommit": true
                }
            }

    Alternatively, it can contain connections parameters for multiple
    databases and drivers, such as:

            {
                "databases": [
                    {
                    "database": "some_database",
                    "host": "db.example.com",
                    "port": 5432,
                    "login": "sql_joe",
                    "passwd": "some password",
                    "driver": "Pg",
                    "schema": "warehouse",
                    "opt":
                        {
                        "RaiseError": false,
                        "PrintError": true,
                        "AutoCommit": true
                        }
                    },
                    {
                    "database": "other_database",
                    "host": "db.example2.com",
                    "login": "sql_bob",
                    "passwd": "other password",
                    "driver": "mysql",
                    },
                    {
                    "database": "/path/to/my/database.sqlite",
                    "driver": "SQLite",
                    }
                ]
            }

*uri* or *DB\_CON\_URI*

:   This is used to specify an uri to contain all the connection
    parameters for one database connection. It can also provided via the
    environment variable *DB\_CON\_URI*. For example:

        http://db.example.com:5432?database=some_database&login=sql_joe&passwd=some%020password&driver=Pg&schema=warehouse&&opt=%7B%22RaiseError%22%3A+false%2C+%22PrintError%22%3Atrue%2C+%22AutoCommit%22%3Atrue%7D

    Here the *opt* parameter is passed as a json string, for example:

            {"RaiseError": false, "PrintError":true, "AutoCommit":true}

METHODS
=======

alias
-----

See [\"alias\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#alias){.perl-module}

allow\_bulk\_delete
-------------------

Sets/gets the boolean value for whether to allow unsafe bulk delete.
This means query without any `where` clause.

allow\_bulk\_update
-------------------

Sets/gets the boolean value for whether to allow unsafe bulk update.
This means query without any `where` clause.

AND
---

Takes any arguments and wrap them into a `AND` clause.

        $tbl->where( $dbh->AND( $tbl->fo->id == ?, $tbl->fo->frequency >= .30 ) );

as\_string
----------

See [\"as\_string\" in
DB::Object::Statement](https://metacpan.org/pod/DB::Object::Statement#as_string){.perl-module}

auto\_convert\_datetime\_to\_object
-----------------------------------

Sets or gets the boolean value. If true, then this api will
automatically transcode datetime value into their equivalent
[DateTime](https://metacpan.org/pod/DateTime){.perl-module} object.

auto\_decode\_json
------------------

Sets or gets the boolean value. If true, then this api will
automatically transcode json data into perl hash reference.

avoid
-----

See [\"avoid\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#avoid){.perl-module}

attribute
---------

Sets or get the value of database connection parameters.

If only one argument is provided, returns its value. If multiple
arguments in a form of pair =\> value are provided, it sets the
corresponding database parameters.

The authorised parameters are:

*Active*

:   Is read-only.

*ActiveKids*

:   Is read-only.

*AutoCommit*

:   Can be changed.

*AutoInactiveDestroy*

:   Can be changed.

*CachedKids*

:   Is read-only.

*Callbacks*

:   Can be changed.

*ChildHandles*

:   Is read-only.

*ChopBlanks*

:   Can be changed.

*CompatMode*

:   Can be changed.

*CursorName*

:   Is read-only.

*ErrCount*

:   Is read-only.

*Executed*

:   Is read-only.

*FetchHashKeyName*

:   Is read-only.

*HandleError*

:   Can be changed.

*HandleSetErr*

:   Can be changed.

*InactiveDestroy*

:   Can be changed.

*Kids*

:   Is read-only.

*LongReadLen*

:   Can be changed.

*LongTruncOk*

:   Can be changed.

*NAME*

:   Is read-only.

*NULLABLE*

:   Is read-only.

*NUM\_OF\_FIELDS*

:   Is read-only.

*NUM\_OF\_PARAMS*

:   Is read-only.

*Name*

:   Is read-only.

*PRECISION*

:   Is read-only.

*PrintError*

:   Can be changed.

*PrintWarn*

:   Can be changed.

*Profile*

:   Is read-only.

*RaiseError*

:   Can be changed.

*ReadOnly*

:   Can be changed.

*RowCacheSize*

:   Is read-only.

*RowsInCache*

:   Is read-only.

*SCALE*

:   Is read-only.

*ShowErrorStatement*

:   Can be changed.

*Statement*

:   Is read-only.

*TYPE*

:   Is read-only.

*Taint*

:   Can be changed.

*TaintIn*

:   Can be changed.

*TaintOut*

:   Can be changed.

*TraceLevel*

:   Can be changed.

*Type*

:   Is read-only.

*Warn*

:   Can be changed.

available\_drivers
------------------

Return the list of available drivers.

base\_class
-----------

Returns the base class.

bind
----

If no values to bind to the underlying query is provided,
[\"bind\"](#bind){.perl-module} simply activate the bind value feature.

If values are provided, they are allocated to the statement object and
will be applied when the query will be executed.

Example:

        $dbh->bind()
        # or
        $dbh->bind->where( "something" )
        # or
        $dbh->bind->select->fetchrow_hashref()
        # and then later
        $dbh->bind( 'thingy' )->select->fetchrow_hashref()

cache
-----

Activate caching.

        $tbl->cache->select->fetchrow_hashref();

cache\_connections
------------------

Sets/get the cached database connection.

cache\_dir
----------

Sets or gets the directory on the file system used for caching data.

cache\_query\_get
-----------------

        my $sth;
        unless( $sth = $dbh->cache_query_get( 'some_arbitrary_identifier' ) )
        {
            # prepare the query
            my $tbl = $dbh->some_table || die( $dbh->error );
            $tbl->where( id => '?' );
            $sth = $tbl->select || die( $tbl->error );
            $dbh->cache_query_set( some_arbitrary_identifier => $sth );
        }
        $sth->exec(12) || die( $sth->error );
        my $ref = $sth->fetchrow_hashref;

Provided with a unique name, and this will return a cached statement
object if it exists already, otherwise it will return undef

cache\_query\_set
-----------------

        my $sth;
        unless( $sth = $dbh->cache_query_get( 'some_arbitrary_identifier' ) )
        {
            # prepare the query
            my $tbl = $dbh->some_table || die( $dbh->error );
            $tbl->where( id => '?' );
            $sth = $tbl->select || die( $tbl->error );
            $dbh->cache_query_set( some_arbitrary_identifier => $sth );
        }
        $sth->exec(12) || die( $sth->error );
        my $ref = $sth->fetchrow_hashref;

Provided with a unique name and a statement object
([DB::Object::Statement](https://metacpan.org/pod/DB::Object::Statement){.perl-module}),
and this will cache it.

What this does simply is store the statement object in a global
`$QUERIES_CACHE` hash reference of identifier-statement object pairs.

It returns the statement object cached.

cache\_tables
-------------

Sets or gets the
[DB::Object::Cache::Tables](https://metacpan.org/pod/DB::Object::Cache::Tables){.perl-module}
object.

check\_driver
-------------

Check that the driver set in *\$SQL\_DRIVER* in \~/etc/common.cfg is
indeed available.

It does this by calling
[\"available\_drivers\"](#available_drivers){.perl-module}.

connect
-------

This will attempt a database server connection.

It called
[\"\_connection\_params2hash\"](#connection_params2hash){.perl-module}
to get the necessary connection parameters, which is superseded in each
driver package.

Then, it will call
[\"\_check\_connect\_param\"](#check_connect_param){.perl-module} to get
the right parameters for connection.

It will also call
[\"\_check\_default\_option\"](#check_default_option){.perl-module} to
get some driver specific default options unless the previous call to
\_check\_connect\_param returned an has with a property *opt*.

It will then set the following current object properties:
[\"database\"](#database){.perl-module},
[\"host\"](#host){.perl-module}, [\"port\"](#port){.perl-module},
[\"login\"](#login){.perl-module}, [\"passwd\"](#passwd){.perl-module},
[\"driver\"](#driver){.perl-module}, [\"cache\"](#cache){.perl-module},
[\"bind\"](#bind){.perl-module}, [\"opt\"](#opt){.perl-module}

Unless specified in the connection options retrieved with
[\"\_check\_default\_option\"](#check_default_option){.perl-module}, it
sets some basic default value:

*AutoCommit* 1

:   

*PrintError* 0

:   

*RaiseError* 0

:   

Finally it tries to connect by calling the, possibly superseded, method
[\"\_dbi\_connect\"](#dbi_connect){.perl-module}

It instantiate a
[DB::Object::Cache::Tables](https://metacpan.org/pod/DB::Object::Cache::Tables){.perl-module}
object to cache database tables and return the current object.

constant\_queries\_cache
------------------------

Returns the global value for `$CONSTANT_QUERIES_CACHE`

constant\_queries\_cache\_get
-----------------------------

Provided with some hash reference with properties `pack`, `file` and
`line` that are together used as a key in the cache and this will use an
existing entry in the cache if available.

constant\_queries\_cache\_set
-----------------------------

Provided with some hash reference with properties `pack`, `file` and
`line` that are together used as a key in the cache and `query_object`
and this will set an entry in the cache. it returns the hash reference
initially provided.

copy
----

Provided with either a reference to an hash or an hash of key =\> value
pairs, [\"copy\"](#copy){.perl-module} will first execute a select
statement on the table object, then fetch the row of data, then replace
the key-value pair in the result by the ones provided, and finally will
perform an insert.

Return false if no data to copy were provided, otherwise it always
returns true.

create\_db
----------

This is a method that must be implemented by the driver package.

create\_table
-------------

This is a method that must be implemented by the driver package.

data\_sources
-------------

Given an optional list of options as hash, this return the data source
of the database handler.

data\_type
----------

Given a reference to an array or an array of data type,
[\"data\_type\"](#data_type){.perl-module} will check their availability
in the database driver.

If nothing found, it return an empty list in list context, or undef in
scalar context.

If something was found, it returns a hash in list context or a reference
to a hash in list context.

database
--------

Return the name of the current database.

databases
---------

This returns the list of available databases.

This is a method that must be implemented by the driver package.

delete
------

See [\"delete\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#delete){.perl-module}

disconnect
----------

Disconnect from database. Returns the return code.

        my $rc = $dbh->disconnect;

do
--

Provided with a string representing a sql query, some hash reference of
attributes and some optional values to bind and this will execute the
query and return the statement handler.

The attributes list will be used to **prepare** the query and the bind
values will be used when executing the query.

Example:

        $rc = $dbh->do( $statement ) || die( $dbh->errstr );
        $rc = $dbh->do( $statement, \%attr ) || die( $dbh->errstr );
        $rv = $dbh->do( $statement, \%attr, @bind_values ) || die( $dbh->errstr );
        my $rows_deleted = $dbh->do(
        q{
           DELETE FROM table WHERE status = ?
        }, undef(), 'DONE' ) || die( $dbh->errstr );

driver
------

Return the name of the driver for the current object.

enhance
-------

Toggle the enhance mode on/off.

When on, the functions
[\"from\_unixtime\"](#from_unixtime){.perl-module} and
[\"unix\_timestamp\"](#unix_timestamp){.perl-module} will be used on
date/time field to translate from and to unix time seamlessly.

err
---

Get the currently set error.

errno
-----

Is just an alias for [\"err\"](#err){.perl-module}.

errmesg
-------

Is just an alias for [\"errstr\"](#errstr){.perl-module}.

errstr
------

Get the currently set error string.

FALSE
-----

This return the keyword `FALSE` to be used in queries.

fatal
-----

Provided a boolean value and this toggles fatal mode on/off.

format\_statement
-----------------

See [\"format\_statement\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#format_statement){.perl-module}

format\_update
--------------

See [\"format\_update\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#format_update){.perl-module}

from\_unixtime
--------------

See [\"from\_unixtime\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#from_unixtime){.perl-module}

get\_sql\_type
--------------

Provided with a sql type, irrespective of the character case, and this
will return the driver equivalent constant value.

group
-----

See [\"group\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#group){.perl-module}

host
----

Sets or gets the `host` property for this database object.

insert
------

See [\"insert\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#insert){.perl-module}

last\_insert\_id
----------------

Get the id of the primary key from the last insert.

limit
-----

See [\"limit\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#limit){.perl-module}

local
-----

See [\"local\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#local){.perl-module}

lock
----

This method must be implemented by the driver package.

login
-----

Sets or gets the `login` property for this database object.

no\_bind
--------

When invoked, [\"no\_bind\"](#no_bind){.perl-module} will change any
preparation made so far for caching the query with bind parameters, and
instead substitute the value in lieu of the question mark placeholder.

no\_cache
---------

Disable caching of queries.

NOT
---

Returns a new
[DB::Object::NOT](https://metacpan.org/pod/DB::Object::NOT){.perl-module}
object, passing it whatever arguments were provided.

NULL
----

Returns a `NULL` string to be used in queries.

on\_conflict
------------

See [\"on\_conflict\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#on_conflict){.perl-module}

OR
--

Returns a new
[DB::Object::OR](https://metacpan.org/pod/DB::Object::OR){.perl-module}
object, passing it whatever arguments were provided.

order
-----

See [\"order\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#order){.perl-module}

P
-

Returns a
[DB::Object::Placeholder](https://metacpan.org/pod/DB::Object::Placeholder){.perl-module}
object, passing it whatever arguments was provided.

param
-----

If only a single parameter is provided, its value is return. If a list
of parameters is provided they are set accordingly using the `SET` sql
command.

Supported parameters are:

AUTOCOMMIT

:   

INSERT\_ID

:   

LAST\_INSERT\_ID

:   

SQL\_AUTO\_IS\_NULL

:   

SQL\_BIG\_SELECTS

:   

SQL\_BIG\_TABLES

:   

SQL\_BUFFER\_RESULT

:   

SQL\_LOG\_OFF

:   

SQL\_LOW\_PRIORITY\_UPDATES

:   

SQL\_MAX\_JOIN\_SIZE

:   

SQL\_SAFE\_MODE

:   

SQL\_SELECT\_LIMIT

:   

SQL\_LOG\_UPDATE

:   

TIMESTAMP

:   

If unsupported parameters are provided, they are considered to be
private and not passed to the database handler.

It then execute the query and return [\"undef\" in
perlfunc](https://metacpan.org/pod/perlfunc#undef){.perl-module} in case
of error.

Otherwise, it returns the current object used to call the method.

passwd
------

Sets or gets the `passwd` property for this database object.

ping
----

Evals a SELECT 1 statement and returns 0 if errors occurred or the
return value.

ping\_select
------------

Will prepare and execute a simple `SELECT 1` and return 0 upon failure
or return the value returned from calling [\"execute\" in
DBI](https://metacpan.org/pod/DBI#execute){.perl-module}.

placeholder
-----------

Same as [\"P\"](#p){.perl-module}. Returns a
[DB::Object::Placeholder](https://metacpan.org/pod/DB::Object::Placeholder){.perl-module}
object, passing it whatever arguments was provided.

port
----

Sets or gets the `port` property for this database object.

prepare
-------

Provided with a sql query and some hash reference of options and this
will prepare the query using the options provided. The options are the
same as the one in [\"prepare\" in
DBI](https://metacpan.org/pod/DBI#prepare){.perl-module} method.

It returns a
[DB::Object::Statement](https://metacpan.org/pod/DB::Object::Statement){.perl-module}
object upon success or undef if an error occurred. The error can then be
retrieved using [\"errstr\"](#errstr){.perl-module} or
[\"error\"](#error){.perl-module}.

prepare\_cached
---------------

Same as [\"prepare\"](#prepare){.perl-module} except the query is
cached.

query
-----

It prepares and executes the given SQL query with the options provided
and return [\"undef\" in
perlfunc](https://metacpan.org/pod/perlfunc#undef){.perl-module} upon
error or the statement handler upon success.

quote
-----

This is used to properly format data by surrounding them with quotes or
not.

Calls [\"quote\" in
DBI](https://metacpan.org/pod/DBI#quote){.perl-module} and pass it
whatever argument was provided.

replace
-------

See [\"replace\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#replace){.perl-module}

reset
-----

See [\"reset\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#reset){.perl-module}

returning
---------

See [\"returning\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#returning){.perl-module}

reverse
-------

See [\"reverse\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#reverse){.perl-module}

select
------

See [\"select\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#select){.perl-module}

set
---

Provided with variable and this will issue a query to `SET` the given
SQL variable.

If any error occurred, undef will be returned and an error set,
otherwise it returns true.

sort
----

See [\"sort\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#sort){.perl-module}

stat
----

Issue a `SHOW STATUS` query and if a particular `$type` is provided, it
will return its value if it exists, otherwise it will return [\"undef\"
in perlfunc](https://metacpan.org/pod/perlfunc#undef){.perl-module}.

In absence of particular \$type provided, it returns the hash list of
values returns or a reference to the hash list in scalar context.

state
-----

Queries the DBI state and return its value.

supported\_class
----------------

Returns the list of driver packages such as
[DB::Object::Postgres](https://metacpan.org/pod/DB::Object::Postgres){.perl-module}

supported\_drivers
------------------

Returns the list of driver name such as
[Pg](https://metacpan.org/pod/Pg){.perl-module}

table
-----

Given a table name, [\"table\"](#table){.perl-module} will return a
[DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables){.perl-module}
object. The object is cached for re-use.

When a cached table object is found, it is cloned and reset (using
[\"reset\"](#reset){.perl-module}), before it is returned to avoid
undesirable effets in following query that would have some table
properties set such as table alias.

table\_exists
-------------

Provided with a table name and this returns true if the table exist or
false otherwise.

table\_info
-----------

This is a method that must be implemented by the driver package.

table\_push
-----------

Add the given table name to the stack of cached table names.

tables
------

Connects to the database and finds out the list of all available tables.
If cache is available, it will use it instead of querying the database
server.

Returns undef or empty list in scalar or list context respectively if no
table found.

Otherwise, it returns the list of table in list context or a reference
of it in scalar context.

tables\_cache
-------------

Returns the table cache object

tables\_info
------------

This is a method that must be implemented by the driver package.

tables\_refresh
---------------

Rebuild the list of available database table.

Returns the list of table in list context or a reference of it in scalar
context.

tie
---

See [\"tie\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#tie){.perl-module}

transaction
-----------

True when a transaction has been started with
[\"begin\_work\"](#begin_work){.perl-module}, false otherwise.

TRUE
----

Returns `TRUE` to be used in queries.

unix\_timestamp
---------------

See [\"unix\_timestamp\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#unix_timestamp){.perl-module}

unlock
------

This is a convenient wrapper around [\"unlock\" in
DB::Object::Query](https://metacpan.org/pod/DB::Object::Query#unlock){.perl-module}

update
------

See [\"update\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#update){.perl-module}

use
---

Given a database, it switch to it, but before it checks that the
database exists. If the database is different than the current one, it
sets the *multi\_db* parameter, which will have the fields in the
queries be prefixed by their respective database name.

It returns the database handler.

use\_cache
----------

Provided with a boolean value and this sets or get the *use\_cache*
parameter.

use\_bind
---------

Provided with a boolean value and this sets or get the *use\_cache*
parameter.

variables
---------

Query the SQL variable \$type

It returns a blank string if nothing was found, or the value found.

version
-------

This is a method that must be implemented by the driver package.

where
-----

See [\"where\" in
DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables#where){.perl-module}

\_cache\_this
-------------

Provided with a query, this will cache it for future re-use.

It does some check and maintenance job to ensure the cache does not get
too big whenever it exceed the value of \$CACHE\_SIZE set in the main
config file.

It returns the cached statement as an
[DB::Object::Statement](https://metacpan.org/pod/DB::Object::Statement){.perl-module}
object.

\_check\_connect\_param
-----------------------

Provided with an hash reference of connection parameters, this will get
the valid parameters by calling
[\"\_connection\_parameters\"](#connection_parameters){.perl-module} and
the connection default options by calling
[\"\_connection\_options\"](#connection_options){.perl-module}

It returns the connection parameters hash reference.

\_check\_default\_option
------------------------

Provided with an hash reference of options, and it actually returns it,
so this does not do much, because this method is supposed to be
supereded by the driver package.

\_connection\_options
---------------------

Provided with an hash reference of connection parameters and this will
returns an hash reference of options whose keys match the regular
expression `/^[A-Z][a-zA-Z]+/`

So this does not do much, because this method is supposed to be
superseded by the driver package.

\_connection\_parameters
------------------------

Returns an array reference containing the following keys: db login
passwd host port driver database server opt uri debug

\_connection\_params2hash
-------------------------

Provided with an hash reference of connection parameters and this will
check if the following environment variables exists and if so use them:
`DB_NAME`, `DB_LOGIN`, `DB_PASSWD`, `DB_HOST`, `DB_PORT`, `DB_DRIVER`,
`DB_SCHEMA`

If the parameter property *uri* was provided of if the environment
variable `DB_CON_URI` is set, it will use this connection uri to get the
necessary connection parameters values.

An [URI](https://metacpan.org/pod/URI){.perl-module} could be
`http://localhost:5432?database=somedb` or
`file:/foo/bar?opt={"RaiseError":true}`

Alternatively, if the connection parameter *conf\_file* is provided then
its json content will be read and decoded into an hash reference.

The following keys can be used in the json data in the *conf\_file*:
`database`, `login`, `passwd`, `host`, `port`, `driver`, `schema`, `opt`

The port can be specified in the *host* parameter by separating it with
a semicolon such as `localhost:5432`

The *opt* parameter can Alternatively be provided through the
environment variable `DB_OPT`

It returns the hash reference of connection parameters.

\_clean\_statement
------------------

Given a query string or a reference to it, it cleans the statement by
removing leading and trailing space before and after line breaks.

It returns the cleaned up query as a string if the original query was
provided as a scalar reference.

\_convert\_datetime2object
--------------------------

Provided with an hash or hash reference of options and this will simply
return the *data* property.

This does not do anything meaningful, because it is supposed to be
superseded by the diver package.

\_convert\_json2hash
--------------------

Provided with an hash or hash reference of options and this will simply
return the *data* property.

This does not do anything meaningful, because it is supposed to be
superseded by the diver package.

\_dbi\_connect
--------------

This will call [\"\_dsn\"](#dsn){.perl-module} which must exist in the
driver package, and based on the `dsn` received, this will initiate a
[\"connect\_cache\" in
DBI](https://metacpan.org/pod/DBI#connect_cache){.perl-module} if the
object property
[\"cache\_connections\"](#cache_connections){.perl-module} has a true
value, or simply a [\"connect\" in
DBI](https://metacpan.org/pod/DBI#connect){.perl-module} otherwise.

It returns the database handler.

\_decode\_json
--------------

Provided with some json data and this will decode it using
[JSON](https://metacpan.org/pod/JSON){.perl-module} and return the
associated hash reference or [\"undef\" in
perlfunc](https://metacpan.org/pod/perlfunc#undef){.perl-module} if an
error occurred.

\_dsn
-----

This will die complaining the driver has not implemented this method,
unless the driver did implement it.

\_encode\_json
--------------

Provided with an hash reference and this will encode it into a json
string and return it.

\_make\_sth
-----------

Given a package name and a hash reference, this builds a statement
object with all the necessary parameters.

It also sets the query time to the current time with the parameter
*query\_time*

It returns an object of the given \$package.

\_param2hash
------------

Provided with some hash reference parameters and this will simply return
it, so it does not do anything meaningful.

This is supposed to be superseded by the driver package.

\_process\_limit
----------------

A convenient wrapper around the [\"\_process\_limit\" in
DB::Object::Query](https://metacpan.org/pod/DB::Object::Query#_process_limit){.perl-module}

\_query\_object\_add
--------------------

Provided with a
[DB::Object::Query](https://metacpan.org/pod/DB::Object::Query){.perl-module}
and this will add it to the current object property *query\_object* and
return it.

\_query\_object\_create
-----------------------

This is supposed to be called from a
[DB::Object::Tables](https://metacpan.org/pod/DB::Object::Tables){.perl-module}

Create a new
[DB::Object::Query](https://metacpan.org/pod/DB::Object::Query){.perl-module}
object, sets the *debug* and *verbose* values and sets its property
[\"table\_object\" in
DB::Object::Query](https://metacpan.org/pod/DB::Object::Query#table_object){.perl-module}
to the value of the current object.

\_query\_object\_current
------------------------

Returns the current *query\_object*

\_query\_object\_get\_or\_create
--------------------------------

Check to see if the [\"query\_object\"](#query_object){.perl-module} is
already set and then return its value, otherwise create a new object by
calling
[\"\_query\_object\_create\"](#query_object_create){.perl-module} and
return it.

\_query\_object\_remove
-----------------------

Provided with a
[DB::Object::Query](https://metacpan.org/pod/DB::Object::Query){.perl-module}
and this will remove it from the current object property
*query\_object*.

It returns the object removed.

\_reset\_query
--------------

If this has not already been reset, this will mark the current query
object as reset and calls
[\"\_query\_object\_remove\"](#query_object_remove){.perl-module} and
return the value for
[\"\_query\_object\_get\_or\_create\"](#query_object_get_or_create){.perl-module}

If it has been already reset, this will return the value for
[\"\_query\_object\_current\"](#query_object_current){.perl-module}

OPERATORS
=========

AND( VALUES )
-------------

Given a value, this returns a
[DB::Object::AND](https://metacpan.org/pod/DB::Object::AND){.perl-module}
object. You can retrieve the value with [\"value\" in
DB::Object::AND](https://metacpan.org/pod/DB::Object::AND#value){.perl-module}

This is used by [\"where\"](#where){.perl-module}

        my $op = $dbh->AND( login => 'joe', status => 'active' );
        # will produce:
        WHERE login = 'joe' AND status = 'active'

NOT( VALUES )
-------------

Given a value, this returns a
[DB::Object::NOT](https://metacpan.org/pod/DB::Object::NOT){.perl-module}
object. You can retrieve the value with [\"value\" in
DB::Object::NOT](https://metacpan.org/pod/DB::Object::NOT#value){.perl-module}

This is used by [\"where\"](#where){.perl-module}

        my $op = $dbh->AND( login => 'joe', status => $dbh->NOT( 'active' ) );
        # will produce:
        WHERE login = 'joe' AND status != 'active'

OR( VALUES )
------------

Given a value, this returns a
[DB::Object::OR](https://metacpan.org/pod/DB::Object::OR){.perl-module}
object. You can retrieve the value with [\"value\" in
DB::Object::OR](https://metacpan.org/pod/DB::Object::OR#value){.perl-module}

This is used by [\"where\"](#where){.perl-module}

        my $op = $dbh->OR( login => 'joe', login => 'john' );
        # will produce:
        WHERE login = 'joe' OR login = 'john'

SEE ALSO
========

[DBI](https://metacpan.org/pod/DBI){.perl-module},
[Apache::DBI](https://metacpan.org/pod/Apache::DBI){.perl-module}

AUTHOR
======

Jacques Deguest \<`jack@deguest.jp`{classes="ARRAY(0x55bf74e28d40)"}\>

COPYRIGHT & LICENSE
===================

Copyright (c) 2019-2021 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated
files under the same terms as Perl itself.
