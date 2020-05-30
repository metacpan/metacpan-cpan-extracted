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
    ## Get the last used insert id
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
    
    ## Lets' dump the result of our query
    ## First to STDERR
    $login->where( "login='jack'" );
    $login->select->dump();
    ## Now dump the result to a file
    $login->select->dump( "my_file.txt" );
    

# VERSION

    v0.9.7

# DESCRIPTION

[DB::Object](https://metacpan.org/pod/DB%3A%3AObject) is a SQL API much alike `DBI`.
So why use a private module instead of using that great `DBI` package?

At first, I started to inherit from `DBI` to conform to `perlmod` perl 
manual page and to general perl coding guidlines. It became very quickly a 
real hassle. Barely impossible to inherit, difficulty to handle error, too 
much dependent from an API that change its behaviour with new versions.
In short, I wanted a better, more accurate control over the SQL connection.

So, [DB::Object](https://metacpan.org/pod/DB%3A%3AObject) acts as a convenient, modifiable wrapper that provide the
programmer with an intuitive, user-friendly and hassle free interface.

# CONSTRUCTOR

- **new**()

    Create a new instance of [DB::Object](https://metacpan.org/pod/DB%3A%3AObject). Nothing much to say.

- **connect**( \[ DATABASE, LOGIN, PASSWORD, SERVER\[:PORT\], DRIVER, SCHEMA \] | %PARAMETERS | \\%PARAMETERS )

    Create a new instance of [DB::Object](https://metacpan.org/pod/DB%3A%3AObject), but also attempts a conection
    to SQL server.

    It can take either an array of value in the order database name, login, password, host, driver and optionally schema, or it can take a has or hash reference. The hash or hash reference attributes are as follow:

    - _database_ or _DB\_NAME_

        The database name you wish to connect to

    - _login_ or _DB\_LOGIN_

        The login used to access that database

    - _passwd_ or _DB\_PASSWD_

        The password that goes along

    - _host_ or _DB\_HOST_

        The server, that is hostname of the machine serving a SQL server.

    - _port_ or _DB\_PORT_

        The port to connect to

    - _driver_ or _DB\_DRIVER_

        The driver you want to use. It needs to be of the same type than the server
        you want to connect to. If you are connecting to a MySQL server, you would use
        `mysql`, if you would connecto to an Oracle server, you would use `oracle`.

        You need to make sure that those driver are properly installed in the system 
        before attempting to connect.

        To install the required driver, you could start with the command line:

            perl -MCPAN -e shell

        which will provide you a special shell to install modules in a convenient way.

    - _schema_ or _DB\_SCHEMA_

        The schema to use to access the tables. Currently only used by PostgreSQL

    - _opt_

        This takes a hash reference and contains the standard `DBI` options such as _PrintError_, _RaiseError_, _AutoCommit_, etc

    - _conf\_file_ or _DB\_CON\_FILE_

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

    - _uri_ or _DB\_CON\_URI_

        This is used to specify an uri to contain all the connection parameters for one database connection. It can also provided via the environment variable _DB\_CON\_URI_. For example:

            http://db.example.com:5432?database=some_database&login=sql_joe&passwd=some%020password&driver=Pg&schema=warehouse&&opt=%7B%22RaiseError%22%3A+false%2C+%22PrintError%22%3Atrue%2C+%22AutoCommit%22%3Atrue%7D
            

        Here the _opt_ parameter is passed as a json string, for example:

            {"RaiseError": false, "PrintError":true, "AutoCommit":true}

# METHODS

- **clear**()

    Reset error message.

- **debug**( \[ 0 | 1 \] )

    Toggle debug mode on/off

- **error**( \[ $string \] )

    Get set error message.
    If an error message is provided, **error** will pass it to **warn**.

- **get**( $parameter )

    Get object parameter.

- **message**( $string )

    Provided a multi line string, **message** will display it on the STDERR if either _verbose_ or _debug_ mode is on.

- **verbose**()

    Toggle verbose mode on/off

- **alias**( %parameters )

    Get/set alias for table fields in SELECT queries. The hash provided thus contain a list of field => alias pairs.

- **as\_string**()

    Return the sql query as a string.

- **avoid**( \[ @fields | \\@fields \] )

    Set the provided list of table fields to avoid when returning the query result.
    The list of fields can be provided either as an array of a reference to an array.

- **attribute**( $name | %names )

    Sets or get the value of database connection parameters.

    If only one argument is provided, returns its value.
    If multiple arguments in a form of pair => value are provided, it sets the corresponding database parameters.

    The authorised parameters are:

    - _Warn_

        Can be overridden.

    - _Active_

        Read-only.

    - _Kids_

        Read-only.

    - _ActiveKids_

        Read-only.

    - _CachedKids_

        Read-only.

    - _InactiveDestroy_

        Can be overridden.

    - _PrintError_

        Can be overridden.

    - _RaiseError_

        Can be overridden.

    - _ChopBlanks_

        Can be overridden.

    - _LongReadLen_

        Can be overridden.

    - _LongTruncOk_

        Can be overridden.

    - _AutoCommit_

        Can be overridden.

    - _Name_

        Read-only.

    - _RowCacheSize_

        Read-only.

    - _NUM\_OF\_FIELDS_

        Read-only.

    - _NUM\_OF\_PARAMS_

        Read-only.

    - _NAME_

        Read-only.

    - _TYPE_

        Read-only.

    - _PRECISION_

        Read-only.

    - _SCALE_

        Read-only.

    - _NULLABLE_

        Read-only.

    - _CursorName_

        Read-only.

    - _Statement_

        Read-only.

    - _RowsInCache_

        Read-only.

- **available\_drivers**()

    Return the list of available drivers.

- **bind**( \[ @values \] )

    If no values to bind to the underlying query is provided, **bind** simply activate the bind value feature.

    If values are provided, they are allocated to the statement object and will be applied when the query will be executed.

    Example:

        $dbh->bind()
        ## or
        $dbh->bind->where( "something" )
        ## or
        $dbh->bind->select->fetchrow_hashref()
        ## and then later
        $dbh->bind( 'thingy' )->select->fetchrow_hashref()

- **cache**()

    Activate caching.

        $tbl->cache->select->fetchrow_hashref();

- **check\_driver**()

    Check that the driver set in _$SQL\_DRIVER_ in ~/etc/common.cfg is indeed available.

    It does this by calling **available\_drivers**.

- **copy**( \[ \\%values | %values )

    Provided with either a reference to an hash or an hash of key => value pairs, **copy** will first execute a select statement on the table object, then fetch the row of data, then replace the key-value pair in the result by the ones provided, and finally will perform an insert.

    Return false if no data to copy were provided, otherwise it always returns true.

- **create\_table**( @parameters )

    The idea is to create a table with the givern parameters.

    This is currently heavily designed to work for PoPList. It needs to be rewritten.

- **data\_sources**( \[ %options \] )

    Given an optional list of options, this return the data source of the database handler.

- **data\_type**( \[ \\@types | @types \] )

    Given a reference to an array or an array of data type, **data\_type** will check their availability in the database driver.

    If nothing found, it return an empty list in list context, or undef in scalar context.

    If something was found, it returns a hash in list context or a reference to a hash in list context.

- **database**()

    Return the name of the current database.

- **delete**()

    **delete** will format a delete query based on previously set parameters, such as **where**.

    **delete** will refuse to execute a query without a where condition. To achieve this, one must prepare the delete query on his/her own by using the **do** method and passing the sql query directly.

        $tbl->where( "login" => "jack" );
        $tbl->limit( 1 );
        my $rows_affected = $tbl->delete();
        ## or passing the where condition directly to delete
        my $sth = $tbl->delete( "login" => "jack" );

- **disconnect**()

    Disconnect from database. Returns the return code.

        my $rc = $dbh->disconnect;

- **do**( $sql\_query, \[ \\%attributes, \\@bind\_values \] )

    Execute a sql query directly passed with possible attributes and values to bind.

    The attributes list will be used to **prepare** the query and the bind values will be used when executing the query.

    It returns the statement handler or the number of rows affected.

    Example:

        $rc = $dbh->do( $statement ) || die( $dbh->errstr );
        $rc = $dbh->do( $statement, \%attr ) || die( $dbh->errstr );
        $rv = $dbh->do( $statement, \%attr, @bind_values ) || die( $dbh->errstr );
        my $rows_deleted = $dbh->do(
        q{
             DELETE FROM table WHERE status = ?
        }, undef(), 'DONE' ) || die( $dbh->errstr );

- **enhance**( \[ @value \] )

    Toggle the enhance mode on/off.

    When on, the functions _from\_unixtime_ and _unix\_timestamp_ will be used on date/time field to translate from and to unix time seamlessly.

- **err**()

    Get the currently set error.

- **errno**()

    Is just an alias for **err**.

- **errmesg**()

    Is just an alias for **errstr**.

- **errstr**()

    Get the currently set error string.

- **fatal**( \[ 1 | 0 \] )

    Toggles fatal mode on/off.

- **from\_unixtime**( \[ @fields | \\@fields \] )

    Set the list of fields that are to be treated as unix time and converted accordingly after the sql query is executed.

    It returns the list of fields in list context or a reference to an array in scalar context.

- **format\_statement**( \[ \\@data, \\@order, $table \] )

    Format the sql statement.

    In list context, it returns 2 strings: one comma-separated list of fields and one comma-separated list of values. In scalar context, it only returns a comma-separated string of fields.

- **format\_update**( \\@data | \\%data | %data | @data )

    Formats update query based on the following arguments provided:

    - _data_

        An array of key-value pairs to be used in the update query. This array can be provided as the prime argument as a reference to an array, an array, or as the _data_ element of a hash or a reference to a hash provided.

        Why an array if eventually we build a list of key-value pair? Because the order of the fields may be important, and if the key-value pair list is provided, **format\_update** honors the order in which the fields are provided.

    **format\_update** will then iterate through each field-value pair, and perform some work:

    If the field being reviewed was provided to **from\_unixtime**, then **format\_update** will enclose it in the function FROM\_UNIXTIME() as in:

        FROM_UNIXTIME(field_name)
        

    If the the given value is a reference to a scalar, it will be used as-is, ie. it will not be enclosed in quotes or anything. This is useful if you want to control which function to use around that field.

    If the given value is another field or looks like a function having parenthesis, or if the value is a question mark, the value will be used as-is.

    If **bind** is off, the value will be escaped and the pair field='value' created.

    If the field is a SET data type and the value is a number, the value will be used as-is without surrounding single quote.

    If **bind** is enabled, a question mark will be used as the value and the original value will be saved as value to bind upon executing the query.

    Finally, otherwise the value is escaped and surrounded by single quotes.

    **format\_update** returns a string representing the comma-separated list of fields that will be used.

- **getdefault**( %default\_values )

    Does some preparation work such as :

    1. the date/time field to use the FROM\_UNIXTIME and UNIX\_TIMESTAMP functions
    2. removing from the query the fields to avoid, ie the ones set with the **avoid** method.
    3. set the fields alias based on the information provided with the **alias** method.
    4. if a field last\_name and first\_name exist, it will also create an alias _name_ based on the concatenation of the 2.
    5. it will set the default values provided. This is used for UPDATE queries.

    It returns a new [DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables) object with all the data prepared within.

- **group**( @fields | \\@fields )

    Format the group by portion of the query.

    It returns an empty list in list context of undef in scalar context if no group by clause was build.
    Otherwise, it returns the value of the group by clause as a string in list context and the full group by clause in scalar context.

    In list context, it returns: $group\_by

    In scalar context, it returns: GROUP BY $group\_by

- **insert**( [DB::Object::Statement](https://metacpan.org/pod/DB%3A%3AObject%3A%3AStatement) SELECT object, \\%key\_value | %key\_value )

    Prepares an INSERT query using the field-value pairs provided.

    If a [DB::Object::Statement](https://metacpan.org/pod/DB%3A%3AObject%3A%3AStatement) object is provided as first argument, it will considered as a SELECT query to be used in the INSERT query, as in: INSERT INTO my table SELECT FROM another\_table

    Otherwise, **insert** will build the query based on the fields provided.

    In scalar context, it returns the result of **execute** and in list context, it returns the statement object.

- **last\_insert\_id**()

    Get the id of the primary key from the last insert.

- **limit**( \[ END, \[ START, END \] \] )

    Set or get the limit for the future statement.

    If only one argument is provided, it is assumed to be the end limit. If 2 are provided, they wil be the start and end.

    It returns a list of the start and end limit in list context, and the string of the LIMIT in scalar context, such as: LIMIT 1, 10

- **local**( %params | \\%params )

    Not sure what it does. I forgot.

- **lock**( $lock\_id, \[ $timeout \] )

    Set a lock using a lock identifier and a timeout.
    By default the timeout is 2 seconds.

    If the lock failed (NULL), it returns undef(), otherwise, it returns the return value.

- **no\_bind**()

    When invoked, **no\_bind** will change any preparation made so far for caching the query with bind parameters, and instead substitute the value in lieu of the question mark placeholder.

- **no\_cache**()

    Disable caching of queries.

- **order**()

    Prepares the ORDER BY clause and returns the value of the clause in list context or the ORDER BY clause in full in scalar context, ie. "ORDER BY $clause"

- **param**( $param | %params )

    If only a single parameter is provided, its value is return. If a list of parameters is provided they are set accordingly using the `SET` sql command.

    Supported parameters are:

    - SQL\_AUTO\_IS\_NULL
    - AUTOCOMMIT
    - SQL\_BIG\_TABLES
    - SQL\_BIG\_SELECTS
    - SQL\_BUFFER\_RESULT
    - SQL\_LOW\_PRIORITY\_UPDATES
    - SQL\_MAX\_JOIN\_SIZE 
    - SQL\_SAFE\_MODE
    - SQL\_SELECT\_LIMIT
    - SQL\_LOG\_OFF
    - SQL\_LOG\_UPDATE 
    - TIMESTAMP
    - INSERT\_ID
    - LAST\_INSERT\_ID

    If unsupported parameters are provided, they are considered to be private and not passed to the database handler.

    It then execute the query and return undef() in case of error.

    Otherwise, it returns the object used to call the method.

- **ping**()

    Evals a SELECT 1 statement and returns 0 if errors occurred or the return value.

- **prepare**( $query, \\%options )

    Prepares the query using the options provided. The options are the same as the one in [DBI](https://metacpan.org/pod/DBI) **prepare** method.

    It returns a [DB::Object::Statement](https://metacpan.org/pod/DB%3A%3AObject%3A%3AStatement) object upon success or undef if an error occurred. The error can then be retrieved using **errstr** or **error**.

- **prepare\_cached**( $query, \\%options )

    Same as **prepare** except the query is cached.

- **query**( $query, \\%options )

    It prepares and executes the given SQL query with the options provided and return undef() upon error or the statement handler upon success.

- **replace**( [DB::Object::Statement](https://metacpan.org/pod/DB%3A%3AObject%3A%3AStatement) object, \[ %data \] )

    Just like for the INSERT query, **replace** takes one optional argument representing a [DB::Object::Statement](https://metacpan.org/pod/DB%3A%3AObject%3A%3AStatement) SELECT object or a list of field-value pairs.

    If a SELECT statement is provided, it will be used to construct a query of the type of REPLACE INTO mytable SELECT FROM other\_table

    Otherwise the query will be REPLACE INTO mytable (fields) VALUES(values)

    In scalar context, it execute the query and in list context it simply returns the statement handler.

- **reset**()

    This is used to reset a prepared query to its default values. If a field is a date/time type, its default value will be set to NOW()

    It execute an update with the reseted value and return the number of affected rows.

- **reverse**( \[ true \])

    Get or set the reverse mode.

- **select**( \[ \\$field, \\@fields, @fields \] )

    Given an optional list of fields to fetch, **select** prepares a SELECT query.

    If no field was provided, **select** will use default value where appropriate like the NOW() for date/time fields.

    **select** calls upon **tie**, **where**, **group**, **order**, **limit** and **local** to build the query.

    In scalar context, it execute the query and return it. In list context, it just returns the statement handler.

- **set**( $var )

    Issues a query to `SET` the given SQL variable.

    If any error occurred, undef will be returned and an error set, otherwise it returns true.

- **sort**()

    It toggles sort mode on and consequently disable reverse mode.

- **stat**( \[ $type \] )

    Issue a SHOW STATUS query and if a particular $type is provided, it will returns its value if it exists, otherwise it will return undef.

    In absence of particular $type provided, it returns the hash list of values returns or a reference to the hash list in scalar context.

- **state**()

    Queries the DBI state and return its value.

- **table**( $table\_name )

    Given a table name, **table** will return a [DB::Object::Tables](https://metacpan.org/pod/DB%3A%3AObject%3A%3ATables) object. The object is cached for re-use.

- **table\_push**( $table\_name )

    Add the given table name to the stack of cached table names.

- **tables**( \[ $database \] )

    Connects to the database and finds out the list of all available tables.

    Returns undef or empty list in scalar or list context respectively if no table found.

    Otherwise, it returns the list of table in list context or a reference of it in scalar context.

- **tables\_refresh**( \[ $database \] )

    Rebuild the list of available database table.

    Returns the list of table in list context or a reference of it in scalar context.

- **tie**( \[ %fields \] )

    If provided a hash or a hash ref, it sets the list of fields and their corresponding perl variable to bind their values to.

    In list context, it returns the list of those field-variable pair, or a reference to it in scalar context.

- **unix\_timestamp**( \[ \\@fields | @fields \] )

    Provided a list of fields or a reference to it, this sets the fields to be treated for seamless conversion from and to unix time.

- **unlock**( $lock\_id )

    Given a lock identifier, **unlock** releases the lock previously set with **lock**. It executes the underlying sql command and returns undef() if the result is NULL or the value returned otherwise.

- **update**( %data | \\%data )

    Given a list of field-value pairs, **update** prepares a sql update query.

    It calls upon **where** and **limit** as previously set.

    It returns undef and sets an error if it failed to prepare the update statement. In scalar context, it execute the query. In list context, it simply return the statement handler.

- **use**( $database )

    Given a database, it switch to it, but before it checks that the database exists.
    If the database is different than the current one, it sets the _multi\_db_ parameter, which will have the fields in the queries be prefixed by their respective database name.

    It returns the database handler.

- **use\_cache**( \[ 0 | 1 \] )

    Sets or get the _use\_cache_ parameter.

- **use\_bind**( \[ 0 | 1 \] )

    Sets or get the _use\_cache_ parameter.

- **variables**( \[ $type \] )

    Query the SQL variable $type

    It returns a blank string if nothing was found, or the value found.

- **where**( %args )

    Build the where clause based on the field-value hash provided.

    It returns the where clause in list context or the full where clause in scalar context, ie "WHERE $clause"

- **\_cache\_this**( $query )

    Provided with a query, this will cache it for future re-use.

    It does some check and maintenance job to ensure the cache does not get too big whenever it exceed the value of $CACHE\_SIZE set in the main config file.

    It returns the cached statement as an [DB::Object::Statement](https://metacpan.org/pod/DB%3A%3AObject%3A%3AStatement) object.

- **\_clean\_statement**( \\$query | $query )

    Given a query string or a reference to it, it cleans the statement by removing leading and trailing space before and after line breaks.

- **\_cleanup**()

    Removes object attributes, namely where, selected\_fields, group\_by, order\_by, limit, alias, avoid, local, and as\_string

- **\_make\_sth**( $package, $hashref )

    Given a package name and a hashref, this build a statement object with all the necessary parameters.

    It also sets the query time to the current time with the parameter _query\_time_

    It returns an object of the given $package.

- **\_reset\_query**()

    Being called using a statement handler, this reset the object by removing all the parameters set by various subroutine calls, such as **where**, **group**, **order**, **avoid**, **limit**, etc.

- **\_save\_bind**( $query\_type )

    This saves/cache the bin query and return the object used to call it.

- **\_value2bind**( $query, $ref )

    Given a sql query and a array reference, **\_value2bind** parse the query and interpolate values for placeholder (?).

    It returns true.

# OPERATORS

## AND( VALUES )

Given a value, this returns a [DB::Object::AND](https://metacpan.org/pod/DB%3A%3AObject%3A%3AAND) object. You can retrieve the value with **value**

This is used by **where**

    my $op = $dbh->AND( login => 'joe', status => 'active' );
    ## will produce:
    WHERE login = 'joe' AND status = 'active'

## NOT( VALUES )

Given a value, this returns a [DB::Object::NOT](https://metacpan.org/pod/DB%3A%3AObject%3A%3ANOT) object. You can retrieve the value with **value**

This is used by **where**

    my $op = $dbh->AND( login => 'joe', status => $dbh->NOT( 'active' ) );
    ## will produce:
    WHERE login = 'joe' AND status != 'active'

## OR( VALUES )

Given a value, this returns a [DB::Object::OR](https://metacpan.org/pod/DB%3A%3AObject%3A%3AOR) object. You can retrieve the value with **value**

This is used by **where**

    my $op = $dbh->OR( login => 'joe', login => 'john' );
    ## will produce:
    WHERE login = 'joe' OR login = 'john'

# COPYRIGHT

Copyright (c) 2019-2020 DEGUEST Pte. Ltd.

# CREDITS

Jacques Deguest <`jack@deguest.jp`>

# SEE ALSO

[DBI](https://metacpan.org/pod/DBI), [Apache::DBI](https://metacpan.org/pod/Apache%3A%3ADBI)
