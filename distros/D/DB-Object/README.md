# NAME

DB::Object - SQL API

# SYNOPSIS

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

Using [fields objects](https://metacpan.org/pod/DB%3A%3AObject%3A%3AFields%3A%3AField)

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

Using a promise ([Promise::Me](https://metacpan.org/pod/Promise%3A%3AMe)) to execute an asynchronous query:

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

Sometimes, having placeholders in expression makes it difficult to work, so you can use placeholder objects to make it work:

        my $P = $dbh->placeholder( type => 'inet' );
    $orders_tbl->where( $dbh->OR( $orders_tbl->fo->ip_addr == "inet $P", "inet $P" << $orders_tbl->fo->ip_addr ) );
    my $order_ip_sth = $orders_tbl->select( 'id' ) || fail( "An error has occurred while trying to create a select by ip query for table orders: " . $orders_tbl->error );
    # SELECT id FROM orders WHERE ip_addr = inet ? OR inet ? << ip_addr

Be careful though, when using [fields objects](https://metacpan.org/pod/DB%3A%3AObject%3A%3AFields%3A%3AField), not to do this:

    my $tbl = $dbh->some_table;
    $tbl->where( $tbl->fo->some_field => '?', $tbl->fo->other_field => '?' );
    my $sth = $tbl->select || die( $tbl->error );

Because the [fields objects](https://metacpan.org/pod/DB%3A%3AObject%3A%3AFields%3A%3AField) are overloaded, instead do this:

    my $tbl = $dbh->some_table;
    $tbl->where( $tbl->fo->some_field == '?', $tbl->fo->other_field == '?' );
    my $sth = $tbl->select || die( $tbl->error );

Accessing a property in a `JSON` or `JSONB` field:

    my $tbl = $dbh->some_table;
    $tbl->where( metadata => { is_system => 'true' } );
    my $sth = $tbl->select;
    say $sth->as_string;
    # SELECT * FROM some_table WHERE metadata->>is_system = 'true';

In future release, other operators than `=` will be implemented for `JSON` and `JSONB` fields.

# VERSION

    v1.9.0

# DESCRIPTION

[DB::Object](https://metacpan.org/pod/DB%3A%3AObject) is a SQL API much alike `DBI`, but with the added benefits that it formats queries in a simple object oriented, chaining way.

So why use a private module instead of using that great `DBI` package?

At first, I started to inherit from `DBI` to conform to `perlmod` perl manual page and to general perl coding guidlines. It became very quickly a real hassle. Barely impossible to inherit, difficulty to handle error, too much dependent from an API that changes its behaviour with new versions.
In short, I wanted a better, more accurate control over the SQL connection and an easy way to format sql statement using an object oriented approach.

So, [DB::Object](https://metacpan.org/pod/DB%3A%3AObject) acts as a convenient, modifiable wrapper that provides the programmer with an intuitive, user-friendly, object oriented and hassle free interface.

However, if you use the power of this interface to prepare queries conveniently, you should cache the resulting statement handler object, because there is an obvious real cost penalty in preparing queries and they absolutely do not need to be prepared each time. So you can do something like:

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

This will provide you with the convenience and power of [DB::Object](https://metacpan.org/pod/DB%3A%3AObject) while keeping execution fast.

# CONSTRUCTOR

## new

Create a new instance of [DB::Object](https://metacpan.org/pod/DB%3A%3AObject). Nothing much to say.

## connect

Provided with a `database`, `login`, `password`, `server`:\[`port`\], `driver`, `schema`, and optional hash or hash reference of parameters and this will issue a, possibly cached, database connection and return the resulting database handler.

Create a new instance of [DB::Object](https://metacpan.org/pod/DB%3A%3AObject), but also attempts a connection to SQL server.

It can take either an array of value in the order database name, login, password, host, driver and optionally schema, or it can take a has or hash reference. The hash or hash reference attributes are as follow.

Note that if you provide connection options that are not among the followings, this will return an error.

- `cache_connections`

    Defaults to true.

    If true, this will instruct [DBI](https://metacpan.org/pod/DBI) to use ["connect\_cached" in DBI](https://metacpan.org/pod/DBI#connect_cached) instead of just ["connect" in DBI](https://metacpan.org/pod/DBI#connect)

    Beware that using cached connections can have some drawbacks, such as if you open a cached connection, enters into a transaction using ["begin\_work" in DB::Object](https://metacpan.org/pod/DB%3A%3AObject#begin_work), then somewhere else in your code a call to a cached connection using the same parameters, which [DBI](https://metacpan.org/pod/DBI) will provide, but will reset the database handler parameters, including the `AutoCommit` that will have been temporarily set to false when you called ["begin\_work"](#begin_work), and then you close your transaction by calling ["rollback"](#rollback) or ["commit"](#commit), but it will trigger an error, because `AutoCommit` will have been reset on this cached connection to a true value. ["rollback"](#rollback) and ["commit"](#commit) require that `AutoCommit` be disabled, which ["begin\_work"](#begin_work) normally do.

    Thus, if you want to avoid using a cached connection, set this to false.

    More on this issue at [DBI documentation](https://metacpan.org/pod/DBI#connect_cached)

- `database` or _DB\_NAME_

    The database name you wish to connect to

- `login` or _DB\_LOGIN_

    The login used to access that database

- `passwd` or _DB\_PASSWD_

    The password that goes along

- `host` or _DB\_HOST_

    The server, that is hostname of the machine serving a SQL server.

- `port` or _DB\_PORT_

    The port to connect to

- `driver` or _DB\_DRIVER_

    The driver you want to use. It needs to be of the same type than the server you want to connect to. If you are connecting to a MySQL server, you would use `mysql`, if you would connecto to an Oracle server, you would use `oracle`.

    You need to make sure that those driver are properly installed in the system before attempting to connect.

    To install the required driver, you could start with the command line:

        perl -MCPAN -e shell

    which will provide you a special shell to install modules in a convenient way.

- `schema` or _DB\_SCHEMA_

    The schema to use to access the tables. Currently only used by PostgreSQL

- `opt`

    This takes a hash reference and contains the standard `DBI` options such as _PrintError_, _RaiseError_, _AutoCommit_, etc

- `conf_file` or `DB_CON_FILE`

    This is used to specify a json connection configuration file. It can also provided via the environment variable _DB\_CON\_FILE_. It has the following structure:

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

    Alternatively, it can contain connections parameters for multiple databases and drivers, such as:

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

- `uri` or _DB\_CON\_URI_

    This is used to specify an uri to contain all the connection parameters for one database connection. It can also provided via the environment variable _DB\_CON\_URI_. For example:

        http://db.example.com:5432?database=some_database&login=sql_joe&passwd=some%020password&driver=Pg&schema=warehouse&&opt=%7B%22RaiseError%22%3A+false%2C+%22PrintError%22%3Atrue%2C+%22AutoCommit%22%3Atrue%7D

    Here the _opt_ parameter is passed as a json string, for example:

        {"RaiseError": false, "PrintError":true, "AutoCommit":true}

# METHODS

## alias

See ["alias" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#alias)

## allow\_bulk\_delete

Sets/gets the boolean value for whether to allow unsafe bulk delete. This means query without any `where` clause.

Default is false.

## allow\_bulk\_update

Sets/gets the boolean value for whether to allow unsafe bulk update. This means query without any `where` clause.

Default is false.

## AND

Takes any arguments and wrap them into a `AND` clause.

    $tbl->where( $dbh->AND( $tbl->fo->id == ?, $tbl->fo->frequency >= .30 ) );

## as\_string

See ["as\_string" in DB::Object::Statement](https://metacpan.org/pod/DB%3A%3AObject%3A%3AStatement#as_string)

## auto\_convert\_datetime\_to\_object

Sets or gets the boolean value. If true, then this api will automatically transcode datetime value into their equivalent [DateTime](https://metacpan.org/pod/DateTime) object.

Default is false.

## auto\_decode\_json

Sets or gets the boolean value. If true, then this api will automatically transcode json data into perl hash reference.

Default is true.

## avoid

See ["avoid" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#avoid)

## attribute

Sets or get the value of database connection parameters.

If only one argument is provided, returns its value.
If multiple arguments in a form of pair => value are provided, it sets the corresponding database parameters.

The authorised parameters are:

- _Active_

    Is read-only.

- _ActiveKids_

    Is read-only.

- _AutoCommit_

    Can be changed.

- _AutoInactiveDestroy_

    Can be changed.

- _CachedKids_

    Is read-only.

- _Callbacks_

    Can be changed.

- _ChildHandles_

    Is read-only.

- _ChopBlanks_

    Can be changed.

- _CompatMode_

    Can be changed.

- _CursorName_

    Is read-only.

- _ErrCount_

    Is read-only.

- _Executed_

    Is read-only.

- _FetchHashKeyName_

    Is read-only.

- _HandleError_

    Can be changed.

- _HandleSetErr_

    Can be changed.

- _InactiveDestroy_

    Can be changed.

- _Kids_

    Is read-only.

- _LongReadLen_

    Can be changed.

- _LongTruncOk_

    Can be changed.

- _NAME_

    Is read-only.

- _NULLABLE_

    Is read-only.

- _NUM\_OF\_FIELDS_

    Is read-only.

- _NUM\_OF\_PARAMS_

    Is read-only.

- _Name_

    Is read-only.

- _PRECISION_

    Is read-only.

- _PrintError_

    Can be changed.

- _PrintWarn_

    Can be changed.

- _Profile_

    Is read-only.

- _RaiseError_

    Can be changed.

- _ReadOnly_

    Can be changed.

- _RowCacheSize_

    Is read-only.

- _RowsInCache_

    Is read-only.

- _SCALE_

    Is read-only.

- _ShowErrorStatement_

    Can be changed.

- _Statement_

    Is read-only.

- _TYPE_

    Is read-only.

- _Taint_

    Can be changed.

- _TaintIn_

    Can be changed.

- _TaintOut_

    Can be changed.

- _TraceLevel_

    Can be changed.

- _Type_

    Is read-only.

- _Warn_

    Can be changed.

## available\_drivers

Return the list of available drivers.

## base\_class

Returns the base class.

## bind

If no values to bind to the underlying query is provided, ["bind"](#bind) simply activate the bind value feature.

If values are provided, they are allocated to the statement object and will be applied when the query will be executed.

Example:

    $dbh->bind()
    # or
    $dbh->bind->where( "something" )
    # or
    $dbh->bind->select->fetchrow_hashref()
    # and then later
    $dbh->bind( 'thingy' )->select->fetchrow_hashref()

## cache

Activate caching.

    $tbl->cache->select->fetchrow_hashref();

## cache\_connections

Sets/get the cached database connection.

## cache\_dir

Sets or gets the directory on the file system used for caching data.

## cache\_query

Boolean. When set to a true value, this will enable the caching of the query objects.

You can specify a particular serialiser with the method ["serialiser"](#serialiser). By default, the serialiser used is [Storable::Improved](https://metacpan.org/pod/Storable%3A%3AImproved)

## cache\_query\_get

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

Provided with a unique name, and this will return a cached statement object if it exists already, otherwise it will return undef

## cache\_query\_set

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

Provided with a unique name and a statement object ([DB::Object::Statement](https://metacpan.org/pod/DB%3A%3AObject%3A%3AStatement)), and this will cache it.

What this does simply is store the statement object in a global repository `queries_cache` of identifier-statement object pairs. This is managed using [Module::Generic::Global](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AGlobal)

It returns the statement object cached.

## cache\_size

The maximum number of serialised objects in the cache.

This defaults to the class global variable `$CACHE_SIZE`, which is `10`

## cache\_table

Sets or gets a boolean value whether to cache the table fields object.

When this is enabled, the second time a database table is accessed, it will retrieve its field objects from the cache rather than recreating them after reading the structure from the database. This is much faster.

By default, this is set to false.

This can be specified in the configuration file passed when instantiating a new `DB::Object` object with the property `cache_table`

## cache\_table\_fields

    my $all_dbs = $dbh->cache_table_fields;
    my $all_tables = $dbh->cache_table_fields( database => $some_database );
    my $all_fields = $dbh->cache_table_fields(
        database => $some_database,
        table => $some_table,
    );
    $dbh->cache_table_fields(
        database => $some_database,
        table => $some_table,
        fields => $some_hash_reference,
    );

Sets or gets the hash reference of database table field name to their [corresponding object](https://metacpan.org/pod/DB%3A%3AObject%3A%3AFields%3A%3AField).

If no parameter is provided, it will return the entire cache for all databases for a given driver.

If only a database name is provided, it will return the cache hash reference for all the tables in the given database.

If a database and a table name is provided, this will return an hash reference of field name to their [corresponding object](https://metacpan.org/pod/DB%3A%3AObject%3A%3AFields%3A%3AField).

If a database and a table name and an hash reference of field names to their [corresponding objects](https://metacpan.org/pod/DB%3A%3AObject%3A%3AFields%3A%3AField) is provided, it will set this hash as the cache for the given database and table.

## cache\_tables

Sets or gets the [DB::Object::Cache::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ACache%3A%3ATables) object.

## check\_driver

Check that the driver set in _$SQL\_DRIVER_ in ~/etc/common.cfg is indeed available.

It does this by calling ["available\_drivers"](#available_drivers).

## connect

This will attempt a database server connection. 

It called ["\_connection\_params2hash"](#_connection_params2hash) to get the necessary connection parameters, which is superseded in each driver package.

Then, it will call ["\_check\_connect\_param"](#_check_connect_param) to get the right parameters for connection.

It will also call ["\_check\_default\_option"](#_check_default_option) to get some driver specific default options unless the previous call to \_check\_connect\_param returned an has with a property _opt_.

It will then set the following current object properties: ["database"](#database), ["host"](#host), ["port"](#port), ["login"](#login), ["passwd"](#passwd), ["driver"](#driver), ["cache"](#cache), ["bind"](#bind), ["opt"](#opt)

Unless specified in the connection options retrieved with ["\_check\_default\_option"](#_check_default_option), it sets some basic default value:

- _AutoCommit_ 1
- _PrintError_ 0
- _RaiseError_ 0

Finally it tries to connect by calling the, possibly superseded, method ["\_dbi\_connect"](#_dbi_connect)

It instantiate a [DB::Object::Cache::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ACache%3A%3ATables) object to cache database tables and return the current object.

## connect\_via

Sets or gets the perl module used to connect to DBI. Typically, this would be [Apache::DBI](https://metacpan.org/pod/Apache%3A%3ADBI). By default, this is empty.

## constant\_queries\_cache

Returns the global repository of constant queries. This uses [Module::Generic::Global](https://metacpan.org/pod/Module%3A%3AGeneric%3A%3AGlobal), and is thread-safe.

This is used by ["constant\_queries\_cache\_get"](#constant_queries_cache_get) and ["constant\_queries\_cache\_set"](#constant_queries_cache_set)

## constant\_queries\_cache\_get

Provided with some hash reference with properties `pack`, `file` and `line` that are together used as a key in the cache and this will use an existing entry in the cache if available.

## constant\_queries\_cache\_del

Removes a constant query cache.

## constant\_queries\_cache\_set

Provided with some hash reference with properties `pack`, `file` and `line` that are together used as a key in the cache and `query_object` and this will set an entry in the cache. it returns the hash reference initially provided.

## constant\_to\_datatype

Provided with a data type constant value and this returns its equivalent data type as a string in upper case.

This constant is set by the driver, or by default by [DBI](https://metacpan.org/pod/DBI). For example `SQL_VARCHAR` is `12` and its data type is `VARCHAR`

See also ["datatype\_to\_constant"](#datatype_to_constant)

## copy

Provided with either a reference to an hash or an hash of key => value pairs, ["copy"](#copy) will first execute a select statement on the table object, then fetch the row of data, then replace the key-value pair in the result by the ones provided, and finally will perform an insert.

Return false if no data to copy were provided, otherwise it always returns true.

## create\_db

This is a method that must be implemented by the driver package.

## create\_table

This is a method that must be implemented by the driver package.

## data\_sources

Given an optional list of options as hash, this return the data source of the database handler.

## data\_type

Given a reference to an array or an array of data type, ["data\_type"](#data_type) will check their availability in the database driver.

If nothing found, it return an empty list in list context, or undef in scalar context.

If something was found, it returns a hash in list context or a reference to a hash in list context.

## database

Return the name of the current database.

## databases

This returns the list of available databases.

This is a method that must be implemented by the driver package.

## datatype\_dict

Returns an hash reference of each data type with their equivalent `constant`, regular expression (`re`), constant `name` and `type` name.

Each data type is an hash with the following properties for each type: `constant`, `name`, `re`, `type`

The data returned is dependent on each driver.

## datatype\_to\_constant

    my $type = $dbh->datatype_to_constant( 'varchar' ); # 12

    # Below achieves the same result
    use DBI ':sql_types';
    say SQL_VARCHAR; # 12

Provided with a data type as a string and this returns its equivalent driver value if any, or by default the one of set by [DBI](https://metacpan.org/pod/DBI).

The data type provided is case insensitive.

If no matching data type exists, it returns `undef` in scalar context, or an empty list in list context.

As pointed out by [DBI documentation](https://metacpan.org/pod/DBI#DBI-Constants): "just because the DBI defines a named constant for a given data type doesn't mean that drivers will support that data type."

See also ["constant\_to\_datatype"](#constant_to_datatype)

## datatypes

    my $types = $dbh->datatypes;

Returns an hash reference of data types to their respective values.

If the driver has its own, it will return the driver's constants, otherwise, this will return an hash reference of [DBI data type constants](https://metacpan.org/pod/DBI#DBI-Constants).

As pointed out by [DBI documentation](https://metacpan.org/pod/DBI#DBI-Constants): "just because the DBI defines a named constant for a given data type doesn't mean that drivers will support that data type."

## delete

See ["delete" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#delete)

## disconnect

Disconnect from database. Returns the return code.

    my $rc = $dbh->disconnect;

## do

Provided with a string representing a sql query, some hash reference of attributes and some optional values to bind and this will execute the query and return the statement handler.

The attributes list will be used to **prepare** the query and the bind values will be used when executing the query.

Example:

    $rc = $dbh->do( $statement ) || die( $dbh->errstr );
    $rc = $dbh->do( $statement, \%attr ) || die( $dbh->errstr );
    $rv = $dbh->do( $statement, \%attr, @bind_values ) || die( $dbh->errstr );
    my $rows_deleted = $dbh->do(
    q{
       DELETE FROM table WHERE status = ?
    }, undef(), 'DONE' ) || die( $dbh->errstr );

## driver

Return the name of the driver for the current object.

## enhance

Toggle the enhance mode on/off.

When on, the functions ["from\_unixtime"](#from_unixtime) and ["unix\_timestamp"](#unix_timestamp) will be used on date/time field to translate from and to unix time seamlessly.

## err

Get the currently set error.

## errno

Is just an alias for ["err"](#err).

## errmesg

Is just an alias for ["errstr"](#errstr).

## errstr

Get the currently set error string.

## FALSE

This return the keyword `FALSE` to be used in queries.

## fatal

Provided a boolean value and this toggles fatal mode on/off.

## format\_statement

See ["format\_statement" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#format_statement)

## format\_update

See ["format\_update" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#format_update)

## from\_unixtime

See ["from\_unixtime" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#from_unixtime)

## get\_sql\_type

Provided with a sql type, irrespective of the character case, and this will return the driver equivalent constant value.

## group

See ["group" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#group)

## host

Sets or gets the `host` property for this database object.

## insert

See ["insert" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#insert)

## last\_insert\_id

Get the id of the primary key from the last insert.

## LIKE

Returns a new [DB::Object::LIKE](https://metacpan.org/pod/DB%3A%3AObject%3A%3ALIKE) object, passing it whatever arguments were provided.

## limit

See ["limit" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#limit)

## local

See ["local" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#local)

## lock

This method must be implemented by the driver package.

## login

Sets or gets the `login` property for this database object.

## no\_bind

When invoked, ["no\_bind"](#no_bind) will change any preparation made so far for caching the query with bind parameters, and instead substitute the value in lieu of the question mark placeholder.

## no\_cache

Disable caching of queries.

## NOT

Returns a new [DB::Object::NOT](https://metacpan.org/pod/DB%3A%3AObject%3A%3ANOT) object, passing it whatever arguments were provided.

## NULL

Returns a `NULL` string to be used in queries.

## on\_conflict

See ["on\_conflict" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#on_conflict)

## OR

Returns a new [DB::Object::OR](https://metacpan.org/pod/DB%3A%3AObject%3A%3AOR) object, passing it whatever arguments were provided.

## order

See ["order" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#order)

## P

Returns a [DB::Object::Placeholder](https://metacpan.org/pod/DB%3A%3AObject%3A%3APlaceholder) object, passing it whatever arguments was provided.

## param

If only a single parameter is provided, its value is return. If a list of parameters is provided they are set accordingly using the `SET` sql command.

Supported parameters are:

- AUTOCOMMIT
- INSERT\_ID
- LAST\_INSERT\_ID
- SQL\_AUTO\_IS\_NULL
- SQL\_BIG\_SELECTS
- SQL\_BIG\_TABLES
- SQL\_BUFFER\_RESULT
- SQL\_LOG\_OFF
- SQL\_LOW\_PRIORITY\_UPDATES
- SQL\_MAX\_JOIN\_SIZE 
- SQL\_SAFE\_MODE
- SQL\_SELECT\_LIMIT
- SQL\_LOG\_UPDATE 
- TIMESTAMP

If unsupported parameters are provided, they are considered to be private and not passed to the database handler.

It then execute the query and return ["undef" in perlfunc](https://metacpan.org/pod/perlfunc#undef) in case of error.

Otherwise, it returns the current object used to call the method.

## passwd

Sets or gets the `passwd` property for this database object.

## ping

Evals a SELECT 1 statement and returns 0 if errors occurred or the return value.

## ping\_select

Will prepare and execute a simple `SELECT 1` and return 0 upon failure or return the value returned from calling ["execute" in DBI](https://metacpan.org/pod/DBI#execute).

## placeholder

Same as ["P"](#p). Returns a [DB::Object::Placeholder](https://metacpan.org/pod/DB%3A%3AObject%3A%3APlaceholder) object, passing it whatever arguments was provided.

## port

Sets or gets the `port` property for this database object.

## prepare

Provided with a sql query and some hash reference of options and this will prepare the query using the options provided. The options are the same as the one in ["prepare" in DBI](https://metacpan.org/pod/DBI#prepare) method.

It returns a [DB::Object::Statement](https://metacpan.org/pod/DB%3A%3AObject%3A%3AStatement) object upon success or undef if an error occurred. The error can then be retrieved using ["errstr"](#errstr) or ["error"](#error).

## prepare\_cached

Same as ["prepare"](#prepare) except the query is cached.

## query

It prepares and executes the given SQL query with the options provided and return ["undef" in perlfunc](https://metacpan.org/pod/perlfunc#undef) upon error or the statement handler upon success.

## query\_object

Sets or gets the [query object](https://metacpan.org/pod/DB%3A%3AObject%3A%3AQuery).

## quote

This is used to properly format data by surrounding them with quotes or not.

Calls ["quote" in DBI](https://metacpan.org/pod/DBI#quote) and pass it whatever argument was provided.

## replace

See ["replace" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#replace)

## reset

See ["reset" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#reset)

## returning

See ["returning" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#returning)

## reverse

See ["reverse" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#reverse)

## select

See ["select" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#select)

## set

Provided with variable and this will issue a query to `SET` the given SQL variable.

If any error occurred, undef will be returned and an error set, otherwise it returns true.

## sort

See ["sort" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#sort)

## stat

Issue a `SHOW STATUS` query and if a particular `$type` is provided, it will return its value if it exists, otherwise it will return ["undef" in perlfunc](https://metacpan.org/pod/perlfunc#undef).

In absence of particular $type provided, it returns the hash list of values returns or a reference to the hash list in scalar context.

## state

Queries the DBI state and return its value.

## supported\_class

Returns the list of driver packages such as [DB::Object::Postgres](https://metacpan.org/pod/DB%3A%3AObject%3A%3APostgres)

## supported\_drivers

Returns the list of driver name such as [Pg](https://metacpan.org/pod/Pg)

## table

Given a table name, ["table"](#table) will return a [DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables) object. The object is cached for re-use.

When a cached table object is found, it is cloned and reset (using ["reset"](#reset)), before it is returned to avoid undesirable effets in following query that would have some table properties set such as table alias.

## table\_exists

Provided with a table name and this returns true if the table exist or false otherwise.

## table\_info

This is a method that must be implemented by the driver package.

It returns an array reference of hash reference containing information about each table column.

## table\_push

Add the given table name to the stack of cached table names.

## tables

Connects to the database and finds out the list of all available tables. If cache is available, it will use it instead of querying the database server.

Returns undef or empty list in scalar or list context respectively if no table found.

Otherwise, it returns the list of table in list context or a reference of it in scalar context.

## tables\_cache

Returns the table cache object

## tables\_info

This is a method that must be implemented by the driver package.

## tables\_refresh

Rebuild the list of available database table.

Returns the list of table in list context or a reference of it in scalar context.

## tie

See ["tie" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#tie)

## transaction

True when a transaction has been started with ["begin\_work"](#begin_work), false otherwise.

## TRUE

Returns `TRUE` to be used in queries.

## unix\_timestamp

See ["unix\_timestamp" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#unix_timestamp)

## for POD::Coverage unknown\_field

## unlock

This is a convenient wrapper around ["unlock" in DB::Object::Query](https://metacpan.org/pod/DB%3A%3AObject%3A%3AQuery#unlock)

## update

See ["update" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#update)

## use

Given a database, it switch to it, but before it checks that the database exists.
If the database is different than the current one, it sets the _multi\_db_ parameter, which will have the fields in the queries be prefixed by their respective database name.

It returns the database handler.

## use\_cache

Provided with a boolean value and this sets or get the _use\_cache_ parameter.

## use\_bind

Provided with a boolean value and this sets or get the _use\_cache_ parameter.

## variables

Query the SQL variable $type

It returns a blank string if nothing was found, or the value found.

## version

This is a method that must be implemented by the driver package.

## where

See ["where" in DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables#where)

## \_cache\_this

Provided with a query, this will cache it for future re-use.

It does some check and maintenance job to ensure the cache does not get too big whenever it exceed the value of $CACHE\_SIZE set in the main config file.

It returns the cached statement as an [DB::Object::Statement](https://metacpan.org/pod/DB%3A%3AObject%3A%3AStatement) object.

## \_check\_connect\_param

Provided with an hash reference of connection parameters, this will get the valid parameters by calling ["\_connection\_parameters"](#_connection_parameters) and the connection default options by calling ["\_connection\_options"](#_connection_options)

It returns the connection parameters hash reference.

## \_check\_default\_option

Provided with an hash reference of options, and it actually returns it, so this does not do much, because this method is supposed to be supereded by the driver package.

## \_connection\_options

Provided with an hash reference of connection parameters and this will returns an hash reference of options whose keys match the regular expression `/^[A-Z][a-zA-Z]+/`

So this does not do much, because this method is supposed to be superseded by the driver package.

## \_connection\_parameters

Returns an array reference containing the following keys: db login passwd host port driver database server opt uri debug

## \_connection\_params2hash

Provided with an hash reference of connection parameters and this will check if the following environment variables exists and if so use them: `DB_NAME`, `DB_LOGIN`, `DB_PASSWD`, `DB_HOST`, `DB_PORT`, `DB_DRIVER`, `DB_SCHEMA`

If the parameter property _uri_ was provided of if the environment variable `DB_CON_URI` is set, it will use this connection uri to get the necessary connection parameters values.

An [URI](https://metacpan.org/pod/URI) could be `http://localhost:5432?database=somedb` or `file:/foo/bar?opt={"RaiseError":true}`

Alternatively, if the connection parameter _conf\_file_ is provided then its json content will be read and decoded into an hash reference.

The following keys can be used in the json data in the _conf\_file_: `database`, `login`, `passwd`, `host`, `port`, `driver`, `schema`, `opt`

The port can be specified in the _host_ parameter by separating it with a semicolon such as `localhost:5432`

The _opt_ parameter can Alternatively be provided through the environment variable `DB_OPT`

It returns the hash reference of connection parameters.

## \_clean\_statement

Given a query string or a reference to it, it cleans the statement by removing leading and trailing space before and after line breaks.

It returns the cleaned up query as a string if the original query was provided as a scalar reference.

## \_convert\_datetime2object

Provided with an hash or hash reference of options and this will simply return the _data_ property.

This does not do anything meaningful, because it is supposed to be superseded by the diver package.

## \_convert\_json2hash

Provided with an hash or hash reference of options and this will simply return the _data_ property.

This does not do anything meaningful, because it is supposed to be superseded by the diver package.

## \_dbi\_connect

This will call ["\_dsn"](#_dsn) which must exist in the driver package, and based on the `dsn` received, this will initiate a ["connect\_cache" in DBI](https://metacpan.org/pod/DBI#connect_cache) if the object property ["cache\_connections"](#cache_connections) has a true value, or simply a ["connect" in DBI](https://metacpan.org/pod/DBI#connect) otherwise.

It returns the database handler.

## \_decode\_json

Provided with some json data and this will decode it using [JSON](https://metacpan.org/pod/JSON) and return the associated hash reference or ["undef" in perlfunc](https://metacpan.org/pod/perlfunc#undef) if an error occurred.

## \_dsn

This will die complaining the driver has not implemented this method, unless the driver did implement it.

## \_encode\_json

Provided with an hash reference and this will encode it into a json string and return it.

## \_make\_sth

Given a package name and a hash reference, this builds a statement object with all the necessary parameters.

It also sets the query time to the current time with the parameter _query\_time_

It returns an object of the given $package.

## \_param2hash

Provided with some hash reference parameters and this will simply return it, so it does not do anything meaningful.

This is supposed to be superseded by the driver package.

## \_process\_limit

A convenient wrapper around the ["\_process\_limit" in DB::Object::Query](https://metacpan.org/pod/DB%3A%3AObject%3A%3AQuery#process_limit)

## \_query\_object\_add

Provided with a [DB::Object::Query](https://metacpan.org/pod/DB%3A%3AObject%3A%3AQuery) and this will add it to the current object property _query\_object_ and return it.

## \_query\_object\_create

This is supposed to be called from a [DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables)

Create a new [DB::Object::Query](https://metacpan.org/pod/DB%3A%3AObject%3A%3AQuery) object, sets the _debug_ and _verbose_ values and sets its property ["table\_object" in DB::Object::Query](https://metacpan.org/pod/DB%3A%3AObject%3A%3AQuery#table_object) to the value of the current object.

## \_query\_object\_current

Returns the current _query\_object_

## \_query\_object\_get\_or\_create

Check to see if the ["query\_object"](#query_object) is already set and then return its value, otherwise create a new object by calling ["\_query\_object\_create"](#_query_object_create) and return it.

## \_query\_object\_remove

Provided with a [DB::Object::Query](https://metacpan.org/pod/DB%3A%3AObject%3A%3AQuery) and this will remove it from the current object property _query\_object_.

It returns the object removed.

## \_reset\_query

If this has not already been reset, this will mark the current query object as reset and calls ["\_query\_object\_remove"](#_query_object_remove) and return the value for ["\_query\_object\_get\_or\_create"](#_query_object_get_or_create)

If it has been already reset, this will return the value for ["\_query\_object\_current"](#_query_object_current)

# OPERATORS

## ALL( VALUES )

This operator is used to query an array where all elements must match.

    my $tbl = $dbh->hosts || die( "Uable to get table object 'hosts'." );
    $tbl->where( $dbh->OR(
        $tbl->fo->name == 'example.com',
        'example.com' == $dbh->ALL( $tbl->fo->alias )
    ));
    my $sth = $tbl->select || die( "Failed to prepare query to get host information: ", $tbl->error );
    my $ref = $sth->fetchrow_hashref;

See [PostgreSQL documentation](https://www.postgresql.org/docs/current/arrays.html)

## AND( VALUES )

Given a value, this returns a [DB::Object::AND](https://metacpan.org/pod/DB%3A%3AObject%3A%3AAND) object. You can retrieve the value with ["value" in DB::Object::AND](https://metacpan.org/pod/DB%3A%3AObject%3A%3AAND#value)

This is used by ["where"](#where)

    my $op = $dbh->AND( login => 'joe', status => 'active' );
    # will produce:
    WHERE login = 'joe' AND status = 'active'

## ANY( VALUES )

This operator is used to query an array where all elements must match.

    my $tbl = $dbh->hosts || die( "Uable to get table object 'hosts'." );
    $tbl->where( $dbh->OR(
        $tbl->fo->name == 'example.com',
        'example.com' == $dbh->ANY( $tbl->fo->alias )
    ));
    my $sth = $tbl->select || die( "Failed to prepare query to get host information: ", $tbl->error );
    my $ref = $sth->fetchrow_hashref;

See [PostgreSQL documentation](https://www.postgresql.org/docs/current/arrays.html)

## IN

For example:

    SELECT
        c.code, c.name, c.name_l10n, c.locale
    FROM country_locale AS c
    WHERE
        c.locale = 'fr_FR' OR
        ('fr_FR' NOT IN (SELECT DISTINCT l.locale FROM country_locale AS l ORDER BY l.locale) AND 
        c.locale = 'en_GB')
    ORDER BY c.code

    my $tbl = $dbh->country_locale || die( $dbh->error );
    my $tbl2 = $dbh->country_locale || die( $dbh->error );
    $tbl2->as( 'l' );
    $tbl2->order( 'locale' );
    my $sth2 = $tbl2->select( 'DISTINCT locale' ) || die( $tbl2->error );

    $tbl->as( 'c' );
    $tbl->where( $dbh->OR(
        $tbl->fo->locale == 'fr_FR',
        $dbh->AND(
            'fr_FR' != $dbh->IN( $sth2 ),
            $tbl->fo->locale == 'en_GB'
        )
    ) );

    $tbl->order( $tbl->fo->code );
    my $sth = $tbl->select( qw( code name name_l10n locale ) ) || die( $tbl->error );
    say $sth->as_string;

## NOT( VALUES )

Given a value, this returns a [DB::Object::NOT](https://metacpan.org/pod/DB%3A%3AObject%3A%3ANOT) object. You can retrieve the value with ["value" in DB::Object::NOT](https://metacpan.org/pod/DB%3A%3AObject%3A%3ANOT#value)

This is used by ["where"](#where)

    my $op = $dbh->AND( login => 'joe', status => $dbh->NOT( 'active' ) );
    # will produce:
    WHERE login = 'joe' AND status != 'active'

## OR( VALUES )

Given a value, this returns a [DB::Object::OR](https://metacpan.org/pod/DB%3A%3AObject%3A%3AOR) object. You can retrieve the value with ["value" in DB::Object::OR](https://metacpan.org/pod/DB%3A%3AObject%3A%3AOR#value)

This is used by ["where"](#where)

    my $op = $dbh->OR( login => 'joe', login => 'john' );
    # will produce:
    WHERE login = 'joe' OR login = 'john'

# SEE ALSO

[DBI](https://metacpan.org/pod/DBI), [Apache::DBI](https://metacpan.org/pod/Apache%3A%3ADBI)

# AUTHOR

Jacques Deguest <`jack@deguest.jp`>

# COPYRIGHT & LICENSE

Copyright (c) 2019-2025 DEGUEST Pte. Ltd.

You can use, copy, modify and redistribute this package and associated files under the same terms as Perl itself.
