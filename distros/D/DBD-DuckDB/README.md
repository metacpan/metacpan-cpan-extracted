[![Release](https://img.shields.io/github/release/giterlizzi/perl-DBD-DuckDB.svg)](https://github.com/giterlizzi/perl-DBD-DuckDB/releases) [![Actions Status](https://github.com/giterlizzi/perl-DBD-DuckDB/workflows/linux/badge.svg)](https://github.com/giterlizzi/perl-DBD-DuckDB/actions) [![License](https://img.shields.io/github/license/giterlizzi/perl-DBD-DuckDB.svg)](https://github.com/giterlizzi/perl-DBD-DuckDB) [![Starts](https://img.shields.io/github/stars/giterlizzi/perl-DBD-DuckDB.svg)](https://github.com/giterlizzi/perl-DBD-DuckDB) [![Forks](https://img.shields.io/github/forks/giterlizzi/perl-DBD-DuckDB.svg)](https://github.com/giterlizzi/perl-DBD-DuckDB) [![Issues](https://img.shields.io/github/issues/giterlizzi/perl-DBD-DuckDB.svg)](https://github.com/giterlizzi/perl-DBD-DuckDB/issues) [![Coverage Status](https://coveralls.io/repos/github/giterlizzi/perl-DBD-DuckDB/badge.svg)](https://coveralls.io/github/giterlizzi/perl-DBD-DuckDB)

# DBD::DuckDB - DuckDB database driver for the DBI module

# SYNOPSIS

    use DBI;
    my $dbh = DBI->connect("dbi:DuckDB:dbname=$dbfile", "", "");

# DESCRIPTION

DuckDB is a high-performance analytical database system. It is designed to be 
fast, reliable, portable, and easy to use. DuckDB provides a rich SQL dialect 
with support far beyond basic SQL. DuckDB supports arbitrary and nested 
correlated subqueries, window functions, collations, complex types (arrays, 
structs, maps), and several extensions designed to make SQL easier to use.

[https://duckdb.org](https://duckdb.org)

# MODULE DOCUMENTATION

This documentation describes driver specific behavior and restrictions. It is
not supposed to be used as the only reference for the user. In any case
consult the **DBI** documentation first!

[Latest DBI documentation.](https://metacpan.org/pod/DBI)

# SETUP

To use [DBD::DuckDB](https://metacpan.org/pod/DBD%3A%3ADuckDB), the native DuckDB library must be available when the
module is loaded.  There are two common ways to satisfy this requirement.

## Manual installation

- Download the library

        $ wget https://github.com/duckdb/duckdb/releases/download/v$VERSION/libduckdb-linux-amd64.zip
        $ unzip duckdb-linux-amd64.zip
        $ sudo cp libduckdb.so /usr/lib64/          # or another system library directory

- Update the library search path

    If the library was not placed in a directory already listed in
    `/etc/ld.so.conf` (or equivalent), add its location to
    `LD_LIBRARY_PATH`:

        $ export LD_LIBRARY_PATH=/usr/lib64:$LD_LIBRARY_PATH

    or add the directory to `/etc/ld.so.conf` and run:

        $ sudo ldconfig

## Use Alien::DuckDB

[Alien::DuckDB](https://metacpan.org/pod/Alien%3A%3ADuckDB) is a CPAN module that automatically downloads and
installs the native DuckDB C library for the current platform.

- Install the Alien module

        $ cpanm Alien::DuckDB

        # or

        $ perl -MCPAN -e 'install Alien::DuckDB'

- DBD::DuckDB detects Alien automatically

    No environment variables or manual copying of \*.so files are needed;
    when you `use DBD::DuckDB`, the module calls
    `Alien::DuckDB->dynamic_lib` to obtain the correct library path.

# THE DBI CLASS

## DBI Class Methods

### **connect**

This method creates a database handle by connecting to a database, and is the 
DBI equivalent of the "new" method.

The connection string is always of the form: "dbi:DuckDB:dbname=&lt;dbfile>"

    my $dbh = DBI->connect("dbi:DuckDB:dbname=$dbfile", "", "", \%attr);

DuckDB creates a file per a database.

The file is opened in read/write mode, and will be created if it does not exist yet.

Although the database is stored in a single file, the directory containing the 
database file must be writable by DuckDB because the library will create 
several temporary files there.

If the filename `$dbfile` is `:memory:`, then a private, temporary in-memory 
database is created for the connection. This in-memory database will vanish 
when the database connection is closed. It is handy for your library tests.

## Common connect Attributes

See ["ATTRIBUTES-COMMON-TO-ALL-HANDLES" in DBI](https://metacpan.org/pod/DBI#ATTRIBUTES-COMMON-TO-ALL-HANDLES).

## DuckDB connect Attributes

### **duckdb\_checkpoint\_on\_disconnect**

Execute `CHECKPOINT` statement on disconnect.

The `CHECKPOINT` statement synchronizes data in the write-ahead log (WAL) to the
database data file.

### **duckdb\_config**

Configuration options can be provided to change different settings of the database
system. Note that many of these settings can be changed later on using `PRAGMA`
statements as well.

    my $dbh = DBI->connect("dbi:DuckDB:dbname=$dbfile", undef, undef, {
        duckdb_config => {
            access_mode   => 'READ_WRITE',
            threads       => 8,
            max_memory    => '8GB',
            default_order => 'DESC'
        }
    });

See [https://duckdb.org/docs/stable/configuration/overview#global-configuration-options](https://duckdb.org/docs/stable/configuration/overview#global-configuration-options).

## Methods Common To All Handles

For all of the methods below, **$h** can be either a database handle (**$dbh**) 
or a statement handle (**$sth**). Note that _$dbh_ and _$sth_ can be replaced with 
any variable name you choose: these are just the names most often used. Another 
common variable used in this documentation is $_rv_, which stands for "return value".

### **err**

    $rv = $h->err;

Returns the error code from the last method called. 

### **errstr**

    $str = $h->errstr;

Returns the last error that was reported by DuckDB. 

### **state**

    $str = $h->state;

Returns a five-character "SQLSTATE" code. Success is indicated by a `00000` code, which 
gets mapped to an empty string by DBI.

Note that the specific success code `00000` is translated to any empty string
(false). DuckDB does not support SQLSTATE then state() will return `S1000` (General Error)
for all errors.

### **trace**

    $h->trace($trace_settings);
    $h->trace($trace_settings, $trace_filename);
    $trace_settings = $h->trace;

Changes the trace settings on a database or statement handle. 
The optional second argument specifies a file to write the 
trace information to. If no filename is given, the information 
is written to `STDERR`. Note that tracing can be set globally as 
well by setting `DBI->trace`, or by using the environment 
variable _DBI\_TRACE_.

### **trace\_msg**

    $h->trace_msg($message_text);
    $h->trace_msg($message_text, $min_level);

Writes a message to the current trace output (as set by the ["trace"](#trace) method). If a second argument 
is given, the message is only written if the current tracing level is equal to or greater than 
the `$min_level`.

### **Other common methods**

See the [DBI](https://metacpan.org/pod/DBI) documentation for full details.

# DBI DATABASE HANDLE OBJECTS

## Database Handle Methods

### **selectall\_arrayref**

    $ary_ref = $dbh->selectall_arrayref($sql);
    $ary_ref = $dbh->selectall_arrayref($sql, \%attr);
    $ary_ref = $dbh->selectall_arrayref($sql, \%attr, @bind_values);

Returns a reference to an array containing the rows returned by preparing and
executing the SQL string. See the [DBI](https://metacpan.org/pod/DBI) documentation for full details.

### **selectcol\_arrayref**

    $ary_ref = $dbh->selectcol_arrayref($sql, \%attr, @bind_values);

Returns a reference to an array containing the first column from each rows 
returned by preparing and executing the SQL string. It is possible to specify 
exactly which columns to return. See the [DBI](https://metacpan.org/pod/DBI) documentation for full details.

### **prepare**

    $sth = $dbh->prepare($statement, \%attr);

Prepares a statement for later execution by the database engine and returns a
reference to a statement handle object.

### **prepare\_cached**

    $sth = $dbh->prepare_cached($statement, \%attr);

Implemented by DBI, no driver-specific impact. This method is most useful if
the same query is used over and over as it will cut down round trips to the server.

### **do**

    $rv = $dbh->do($statement);
    $rv = $dbh->do($statement, \%attr);
    $rv = $dbh->do($statement, \%attr, @bind_values);

Prepare and execute a single statement. Returns the number of rows affected if 
the query was successful, returns undef if an error occurred, and returns -1 if 
the number of rows is unknown or not available. Note that this method will 
return **0E0** instead of 0 for 'no rows were affected', in order to always 
return a true value if no error occurred.

### **last\_insert\_id**

DuckDB does not implement auto\_increment of serial type columns it uses 
predefined sequences where the id numbers are either selected before insert, at 
insert time, or as part of the query.

    $dbh->do('CREATE SEQUENCE id_sequence START 1');

    $dbh->do( q{CREATE TABLE tbl (
        id INTEGER DEFAULT nextval('id_sequence'),
        s VARCHAR
    } );

    $dbh->do( q{INSERT INTO tbl (s) VALUES ('hello'), ('world')} );

See [https://duckdb.org/docs/stable/sql/statements/create\_sequence.html](https://duckdb.org/docs/stable/sql/statements/create_sequence.html).

### **commit**

    $rv = $dbh->commit;

Issues a COMMIT to DuckDB, indicating that the current transaction is 
finished and that all changes made will be visible to other processes. If 
AutoCommit is enabled, then a warning is given and no COMMIT is issued. Returns 
true on success, false on error.

### **rollback**

    $rv = $dbh->rollback;

Issues a ROLLBACK to DuckDB, which discards any changes made in the current 
transaction. If AutoCommit is enabled, then a warning is given and no ROLLBACK 
is issued. Returns true on success, and false on error.

### **begin\_work**

This method turns on transactions until the next call to "commit" or "rollback",
if AutoCommit is currently enabled. If it is not enabled, calling begin\_work will
issue an error. Note that the transaction will not actually begin until the first
statement after begin\_work is called.

Example:

    $dbh->{AutoCommit} = 1;
    $dbh->do('INSERT INTO foo VALUES (123)'); ## Changes committed immediately
    $dbh->begin_work();
    ## Not in a transaction yet, but AutoCommit is set to 0

    $dbh->do("INSERT INTO foo VALUES (345)");
    ## DuckDB actually issues two statements here:
    ## BEGIN;
    ## INSERT INTO foo VALUES (345)
    ## We are now in a transaction

    $dbh->commit();
    ## AutoCommit is now set to 1 again

### **disconnect**

    $rv = $dbh->disconnect;

Disconnects from the DuckDB database. Any uncommitted changes will be rolled 
back upon disconnection. It's good policy to always explicitly call commit or 
rollback at some point before disconnecting, rather than relying on the default 
rollback behavior.

If the script exits before disconnect is called (or, more precisely, if the 
database handle is no longer referenced by anything), then the database 
handle's DESTROY method will call the rollback() and disconnect() methods 
automatically. It is best to explicitly disconnect rather than rely on this 
behavior.

### **quote**

    $rv = $dbh->quote($value, $data_type);

### **quote\_identifier**

    $string = $dbh->quote_identifier( $name );
    $string = $dbh->quote_identifier( undef, $schema, $table);

### **table\_info**

    $sth = $dbh->table_info( $catalog, $schema, $table, $type );

Returns all tables and schemas (databases) as specified in ["table\_info" in DBI](https://metacpan.org/pod/DBI#table_info).
The schema and table arguments will do a `LIKE` search. The `$type`
argument accepts a comma separated list of the following types 'TABLE',
'INDEX', 'VIEW' and 'TRIGGER' (by default all are returned).
Note that a statement handle is returned, and not a direct list of tables.
The following fields are returned:

- **TABLE\_CAT**: The name of the catalog.
- **TABLE\_SCHEM**: The name of the schema (database) that the table or view is
in. The default schema is 'main' and other databases will be in the name given when
the database was attached.
- **TABLE\_NAME**: The name of the table or view.
- **TABLE\_TYPE**: The type of object returned. Will be one of 'TABLE', 'INDEX',
'VIEW', 'TRIGGER'.
- **REMARKS**: A description of the table.

### **column\_info**

    $sth = $dbh->column_info( $catalog, $schema, $table, $column );

Fetch information about columns in specificed table (["column\_info" in DBI](https://metacpan.org/pod/DBI#column_info)).
The catalog, schema and table arguments will do a `LIKE` search.
Note that a statement handle is returned, and not a direct list of columns.
The following fields are returned:

- **TABLE\_CAT**: The name of the catalog.
- **TABLE\_SCHEM**: The name of the schema (database) that the table or 
view is in. The default schema is 'main' and other databases will be in the 
name given when the database was attached.
- **TABLE\_NAME**: The name of the table or view.
- **COLUMN\_NAME**: The column identifier.
- **DATA\_TYPE**
- **TYPE\_NAME**: A data source dependent data type name.
- **COLUMN\_SIZE**
- **BUFFER\_LENGTH**
- **DECIMAL\_DIGITS**: The total number of significant digits to the right
of the decimal point.
- **NUM\_PREC\_RADIX**: The radix for numeric precision. The value is 10 or
2 for numeric data types and NULL (undef) if not applicable.
- **NULLABLE**: Indicates if a column can accept NULLs (0 = SQL\_NO\_NULLS, 
1 = SQL\_NULLABLE)
- **REMARKS**: A description of the column.
- **COLUMN\_DEF**: The default value of the column, in a format that can be 
used directly in an SQL statement.
- **SQL\_DATA\_TYPE**
- **SQL\_DATETIME\_SUB**
- **CHAR\_OCTET\_LENGTH**
- **ORDINAL\_POSITION**: The column sequence number (starting with 1).
- **IS\_NULLABLE**: Indicates if the column can accept NULLs. Possible 
values are: 'NO', 'YES' and ''.

### **tables**

    @names = $dbh->tables( undef, $schema, $table, $type, \%attr );

Supported by this driver as proposed by DBI. This method returns all tables
and/or views (including foreign tables and materialized views) which are
visible to the current user: see ["table\_info"](#table_info) for more information about
the arguments.

### **type\_info\_all**

    $type_info_all = $dbh->type_info_all;

Supported by this driver as proposed by DBI. Information is only provided for
SQL datatypes and for frequently used datatypes.

### **type\_info**

    @type_info = $dbh->type_info($data_type);

Returns a list of hash references holding information about one or more variants of $data\_type. 
See the DBI documentation for more details.

### **primary\_key primary\_key\_info**

    @names = $dbh->primary_key(undef, $schema, $table);
    $sth   = $dbh->primary_key_info(undef, $schema, $table, \%attr);

You can retrieve primary key names or more detailed information.

### **foreign\_key\_info**

    $sth = $dbh->foreign_key_info( $pk_catalog, $pk_schema, $pk_table,
                                   $fk_catalog, $fk_schema, $fk_table );

Supported by this driver as proposed by DBI, using the SQL/CLI variant.

### **ping**

    my $bool = $dbh->ping;

Returns true if the database file exists (or the database is in-memory), and
the database connection is active.

## DuckDB methods

### **x\_duckdb\_version**

Return the current DuckDB library version using `duckdb_library_version` C
function.

### **x\_duckdb\_appender**

Appenders are the most efficient way of loading data into DuckDB from within 
the C interface, and are recommended for fast data loading. The appender is 
much faster than using prepared statements or individual INSERT INTO statements.

    $dbh->do('CREATE TABLE people (id INTEGER, name VARCHAR)');
    my $appender = $dbh->x_duckdb_appender('people');

    $appender->append(1, DUCKDB_TYPE_INTEGER);
    $appender->append('Mark', DUCKDB_TYPE_VARCHAR);
    $appender->end_row;

    # or

    $appeder->append_row(id => 1, name => 'Mark');

See [DBD::DuckDB::Appender](https://metacpan.org/pod/DBD%3A%3ADuckDB%3A%3AAppender).

### **x\_duckdb\_read\_csv**

    $dbh->x_duckdb_read_csv( $file );
    $dbh->x_duckdb_read_csv( $file, \%params );

Helper method for `read_csv` function ([https://duckdb.org/docs/stable/data/csv/overview](https://duckdb.org/docs/stable/data/csv/overview)).

    $sth = $dbh->x_duckdb_read_csv('https://duckdb.org/data/flights.csv' => {sep => '|'}) or Carp::croak $dbh->errstr;

    while (my $row = $sth->fetchrow_hashref) {
        say sprintf '%s --> %s', $row->{OriginCityName}, $row->{DestCityName}; 
    }

### **x\_duckdb\_read\_json**

    $dbh->x_duckdb_read_json( $file );
    $dbh->x_duckdb_read_json( $file, \%params );

Helper method for `read_json` function ([https://duckdb.org/docs/stable/data/json/loading\_json](https://duckdb.org/docs/stable/data/json/loading_json)).

    $sth = $dbh->x_duckdb_read_json('https://duckdb.org/data/json/todos.json') or Carp::croak $dbh->errstr;

    while (my $row = $sth->fetchrow_hashref) {
        say sprintf '[%s] %s', ($row->{completed} ? '✓' : ' '), $row->{title};
    }

### **x\_duckdb\_read\_xlsx**

    $dbh->x_duckdb_read_xlsx( $file );
    $dbh->x_duckdb_read_xlsx( $file, \%params );

Helper method for `read_xlsx` function ([https://duckdb.org/docs/stable/core\_extensions/excel](https://duckdb.org/docs/stable/core_extensions/excel)).

# DBI STATEMENT HANDLE OBJECTS

## Statement Handle Methods

### **bind\_param**

    $rv = $sth->bind_param($param_num, $bind_value);
    $rv = $sth->bind_param($param_num, $bind_value, $bind_type);
    $rv = $sth->bind_param($param_num, $bind_value, \%attr);

Allows the user to bind a value and/or a data type to a placeholder.

### **bind\_param\_array**

    $rv = $sth->bind_param_array($param_num, $array_ref_or_value)
    $rv = $sth->bind_param_array($param_num, $array_ref_or_value, $bind_type)
    $rv = $sth->bind_param_array($param_num, $array_ref_or_value, \%attr)

Binds an array of values to a placeholder, so that each is used in turn by a call 
to the ["execute\_array"](#execute_array) method.

### **execute**

    $rv = $sth->execute(@bind_values);

Perform whatever processing is necessary to execute the prepared statement.

### **execute\_array**

    $tuples = $sth->execute_array() or die $sth->errstr;
    $tuples = $sth->execute_array(\%attr) or die $sth->errstr;
    $tuples = $sth->execute_array(\%attr, @bind_values) or die $sth->errstr;
    ($tuples, $rows) = $sth->execute_array(\%attr) or die $sth->errstr;
    ($tuples, $rows) = $sth->execute_array(\%attr, @bind_values) or die $sth->errstr;

Execute a prepared statement once for each item in a passed-in hashref, or items that 
were previously bound via the ["bind\_param\_array"](#bind_param_array) method. See the [DBI](https://metacpan.org/pod/DBI) documentation 
for more details.

### **execute\_for\_fetch**

    $tuples = $sth->execute_for_fetch($fetch_tuple_sub);
    $tuples = $sth->execute_for_fetch($fetch_tuple_sub, \@tuple_status);
    ($tuples, $rows) = $sth->execute_for_fetch($fetch_tuple_sub);
    ($tuples, $rows) = $sth->execute_for_fetch($fetch_tuple_sub, \@tuple_status);

Used internally by the ["execute\_array"](#execute_array) method, and rarely used directly. See the 
[DBI](https://metacpan.org/pod/DBI) documentation for more details.

### **fetchrow\_arrayref**

    $ary_ref = $sth->fetchrow_arrayref;

Fetches the next row of data from the statement handle, and returns a reference to an array 
holding the column values. Any columns that are NULL are returned as undef within the array.

If there are no more rows or if an error occurs, then this method return undef. You should 
check `$sth->err` afterwards (or use the [RaiseError](#raiseerror-boolean-inherited) attribute) to discover if the undef returned 
was due to an error.

Note that the same array reference is returned for each fetch, so don't store the reference and 
then use it after a later fetch. Also, the elements of the array are also reused for each row, 
so take care if you want to take a reference to an element. See also ["bind\_columns"](#bind_columns).

### **fetchrow\_array**

    @ary = $sth->fetchrow_array;

Similar to the ["fetchrow\_arrayref"](#fetchrow_arrayref) method, but returns a list of column information rather than 
a reference to a list. Do not use this in a scalar context.

### **fetchrow\_hashref**

    $hash_ref = $sth->fetchrow_hashref;
    $hash_ref = $sth->fetchrow_hashref($name);

Fetches the next row of data and returns a hashref containing the name of the columns as the keys 
and the data itself as the values. Any NULL value is returned as an undef value.

If there are no more rows or if an error occurs, then this method return undef. You should 
check `$sth->err` afterwards (or use the [RaiseError](#raiseerror-boolean-inherited) attribute) to discover if the undef returned 
was due to an error.

The optional `$name` argument should be either `NAME`, `NAME_lc` or `NAME_uc`, and indicates 
what sort of transformation to make to the keys in the hash.

### **fetchall\_arrayref**

    $tbl_ary_ref = $sth->fetchall_arrayref();
    $tbl_ary_ref = $sth->fetchall_arrayref( $slice );
    $tbl_ary_ref = $sth->fetchall_arrayref( $slice, $max_rows );

Returns a reference to an array of arrays that contains all the remaining rows to be fetched from the 
statement handle. If there are no more rows, an empty arrayref will be returned. If an error occurs, 
the data read in so far will be returned. Because of this, you should always check `$sth->err` after 
calling this method, unless [RaiseError](#raiseerror-boolean-inherited) has been enabled.

If `$slice` is an array reference, fetchall\_arrayref uses the ["fetchrow\_arrayref"](#fetchrow_arrayref) method to fetch each 
row as an array ref. If the `$slice` array is not empty then it is used as a slice to select individual 
columns by perl array index number (starting at 0, unlike column and parameter numbers which start at 1).

With no parameters, or if $slice is undefined, fetchall\_arrayref acts as if passed an empty array ref.

If `$slice` is a hash reference, fetchall\_arrayref uses ["fetchrow\_hashref"](#fetchrow_hashref) to fetch each row as a hash reference.

See the [DBI](https://metacpan.org/pod/DBI) documentation for a complete discussion.

### **fetchall\_hashref**

    $hash_ref = $sth->fetchall_hashref( $key_field );

Returns a hashref containing all rows to be fetched from the statement handle. See the DBI documentation for 
a full discussion.

### **finish**

    $rv = $sth->finish;

Indicates to DBI that you are finished with the statement handle and are not going to use it again. Only needed 
when you have not fetched all the possible rows.

### **rows**

    $rv = $sth->rows;

Returns the number of rows returned by the last query. In contrast to many other DBD modules, 
the number of rows is available immediately after calling `$sth->execute`. Note that 
the ["execute"](#execute) method itself returns the number of rows itself, which means that this 
method is rarely needed.

### **dump\_results**

    $rows = $sth->dump_results($maxlen, $lsep, $fsep, $fh);

Fetches all the rows from the statement handle, calls `DBI::neat_list` for each row, and 
prints the results to `$fh` (which defaults to `STDOUT`). Rows are separated by `$lsep` (which defaults 
to a newline). Columns are separated by `$fsep` (which defaults to a comma). The `$maxlen` controls 
how wide the output can be, and defaults to 35.

This method is designed as a handy utility for prototyping and testing queries. Since it uses 
"neat\_list" to format and edit the string for reading by humans, it is not recommended 
for data transfer applications.

# SUPPORT

## Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at [https://github.com/giterlizzi/perl-DBD-DuckDB/issues](https://github.com/giterlizzi/perl-DBD-DuckDB/issues).
You will be notified automatically of any progress on your issue.

## Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

[https://github.com/giterlizzi/perl-DBD-DuckDB](https://github.com/giterlizzi/perl-DBD-DuckDB)

    git clone https://github.com/giterlizzi/perl-DBD-DuckDB.git

# AUTHOR

- Giuseppe Di Terlizzi <gdt@cpan.org>

# LICENSE AND COPYRIGHT

This software is copyright (c) 2024-2025 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.
