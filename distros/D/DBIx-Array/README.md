# NAME

DBIx::Array - DBI Wrapper with Perl style data structure interfaces

# SYNOPSIS

    use DBIx::Array;
    my $dbx   = DBIx::Array->new;
    $dbx->connect($connection, $user, $pass, \%opt); #passed to DBI
    my @array = $dbx->sqlarray($sql, @params);

With a connected database handle

    use DBIx::Array;
    my $dbx   = DBIx::Array->new(dbh=>$dbh);

With stored connection information from a File

    use DBIx::Array::Connect;
    my $dbx   = DBIx::Array::Connect->new(file=>"my.ini")->connect("mydatabase");

# DESCRIPTION

This module provides a Perl data structure interface for Structured Query Language (SQL).  This module is for people who truly understand SQL and who understand Perl data structures.  If you understand how to modify your SQL to meet your data requirements then this module is for you.

This module is used to connect to Oracle 10g and 11g using [DBD::Oracle](https://metacpan.org/pod/DBD::Oracle) on both Linux and Win32, MySQL 4 and 5 using [DBD::mysql](https://metacpan.org/pod/DBD::mysql) on Linux, Microsoft SQL Server using [DBD::Sybase](https://metacpan.org/pod/DBD::Sybase) on Linux and using [DBD::ODBC](https://metacpan.org/pod/DBD::ODBC) on Win32 systems, and PostgreSQL using [DBD::Pg](https://metacpan.org/pod/DBD::Pg) in a 24x7 production environment.  Tests are written against [DBD::CSV](https://metacpan.org/pod/DBD::CSV) and [DBD::XBase](https://metacpan.org/pod/DBD::XBase).

## CONVENTIONS

- Methods are named "type + data structure".
    - sql - Methods that are type "sql" use the passed SQL to hit the database.
    - abs - Methods that are type "abs" use [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract) to build the SQL to hit the database.
    - sqlwhere - Methods that are type "sqlwhere" use the passed SQL appended with the passed where structure with [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract)->where to build the SQL to hit the database.
- Methods data structures are:
    - scalar - which is a single value the value from the first column of the first row.
    - array - which is a flattened list of values from all columns from all rows.
    - hash - which is the first two columns of values as a hash or hash reference
    - arrayarray - which is an array of array references (i.e. data table)
    - arrayhash - which is an array of hash references (works best when used with case sensitive column aliases)
    - hashhash - which is a hash where the keys are the values of the first column and the values are a hash reference of all (including the key) column values.
    - arrayarrayname - which is an array of array references (i.e. data table) with the first row being the column names passed from the database
    - arrayhashname - which is an array of hash references with the first row being the column names passed from the database
    - arrayobject - which is an array of hash references blessed into the passed class namespace
- Methods are context sensitive
    - Methods in list context return a list e.g. (), (\[\],\[\],\[\],...), ({},{},{},...)
    - Methods in scalar context return an array reference e.g. \[\], \[\[\],\[\],\[\],...\], \[{},{},{},...\]

# USAGE

Loop through data

    foreach my $row ($dbx->sqlarrayhash($sql, @bind)) {
      do_something($row->{"id"}, $row->{"column"});
    }

Easily generate an HTML table

    my $cgi  = CGI->new("");
    my $html = $cgi->table($cgi->Tr([map {$cgi->td($_)} $dbx->sqlarrayarrayname($sql, @param)]));

Bless directly into a class

    my ($object) = $dbx->sqlarrayobject("My::Package", $sql, {id=>$id}); #bless({id=>1, name=>'foo'}, 'My::Package');
    my @objects  = $dbx->absarrayobject("My::Package", "myview", '*', {active=>1}, ["name"]); #($object, $object, ...)

# CONSTRUCTOR

## new

    my $dbx = DBIx::Array->new();
    $dbx->connect(...); #connect to database, sets and returns dbh

    my $dbx = DBIx::Array->new(dbh=>$dbh); #already have a handle

## initialize

# METHODS (Properties)

## dbh

Sets or returns the database handle object.

    my $dbh = $dbx->dbh;
    $dbx->dbh($dbh);  #if you already have a connection

## name

Sets or returns a user friendly identification string for this database connection

    my $name = $dbx->name;
    $dbx->name($string);

# METHODS (DBI Wrappers)

## connect

Wrapper around DBI->connect; Connects to the database, sets dbh property, and returns the database handle.

    $dbx->connect($connection, $user, $pass, \%opt); #sets $dbx->dbh
    my $dbh = $dbx->connect($connection, $user, $pass, \%opt);

Examples:

    $dbx->connect("DBI:mysql:database=mydb;host=myhost", "user", "pass", {AutoCommit=>1, RaiseError=>1});
    $dbx->connect("DBI:Sybase:server=myhost;datasbase=mydb", "user", "pass", {AutoCommit=>1, RaiseError=>1}); #Microsoft SQL Server API is same as Sybase API
    $dbx->connect("DBI:Oracle:TNSNAME", "user", "pass", {AutoCommit=>1, RaiseError=>1});

## disconnect

Wrapper around dbh->disconnect

    $dbx->disconnect;

## commit

Wrapper around dbh->commit

    $dbx->commit;

## rollback

Wrapper around dbh->rollback

    $dbx->rollback;

## prepare

Wrapper around dbh->prepare with a [Tie::Cache](https://metacpan.org/pod/Tie::Cache) cache.

    my $sth = $dbx->prepare($sql);

## prepare\_max\_count

Maximum number of prepared statements to keep in the cache.

    $dbx->prepare_max_count(128); #default
    $dbx->prepare_max_count(0);   #disabled

## AutoCommit

Wrapper around dbh->{'AutoCommit'}

    $dbx->AutoCommit(1);
    &doSomething if $dbx->AutoCommit;

For transactions that must complete together, I recommend

    { #block to keep local... well... local.
      local $dbx->dbh->{'AutoCommit'} = 0;
      $dbx->sqlinsert($sql1, @bind1);
      $dbx->sqlupdate($sql2, @bind2);
      $dbx->sqlinsert($sql3, @bind3);
    } #What is AutoCommit now?  Do you care?

If AutoCommit reverts to true at the end of the block then DBI commits.  Else AutoCommit is still false and still not committed.  This allows higher layers to determine commit functionality.

## RaiseError

Wrapper around dbh->{'RaiseError'}

    $dbx->RaiseError(1);
    &doSomething if $dbx->RaiseError;

    { #local block
      local $dbx->dbh->{'RaiseError'} = 0;
      $dbx->sqlinsert($sql, @bind); #do not die
    }

## errstr

Wrapper around $DBI::errstr

    my $err = $dbx->errstr;

# METHODS (Read) - SQL

## sqlcursor

Returns the prepared and executed SQL cursor so that you can use the cursor elsewhere.  Every method in this package uses this single method to generate a sqlcursor.

    my $sth = $dbx->sqlcursor($sql,  @param); #binds are ? values are positional
    my $sth = $dbx->sqlcursor($sql, \@param); #binds are ? values are positional
    my $sth = $dbx->sqlcursor($sql, \%param); #binds are :key

Note: In true Perl fashion extra hash binds are ignored.

    my @foo = $dbx->sqlarray("select :foo, :bar from dual",
                             {foo=>"a", bar=>1, baz=>"buz"}); #returns ("a", 1)

    my $one = $dbx->sqlscalar("select ? from dual", ["one"]); #returns "one"

    my $two = $dbx->sqlscalar("select ? from dual", "two");   #returns "two"

Scalar references are passed in and out with a hash bind.

    my $inout = 3;
    $dbx->sqlexecute("BEGIN :inout := :inout * 2; END;", {inout=>\$inout});
    print "$inout\n";  #$inout is 6

Direct Plug-in for [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract) but no column alias support.

    my $sabs = SQL::Abstract->new;
    my $sth  = $dbx->sqlcursor($sabs->select($table, \@columns, \%where, \@sort));

## sqlscalar

Returns the first row first column value as a scalar.

This works great for selecting one value.

    my $scalar = $dbx->sqlscalar($sql,  @parameters); #returns $
    my $scalar = $dbx->sqlscalar($sql, \@parameters); #returns $
    my $scalar = $dbx->sqlscalar($sql, \%parameters); #returns $

## sqlarray

Returns the SQL result as an array or array reference.

This works great for selecting one column from a table or selecting one row from a table.

    my $array = $dbx->sqlarray($sql,  @parameters); #returns [$,$,$,...]
    my @array = $dbx->sqlarray($sql,  @parameters); #returns ($,$,$,...)
    my $array = $dbx->sqlarray($sql, \@parameters); #returns [$,$,$,...]
    my @array = $dbx->sqlarray($sql, \@parameters); #returns ($,$,$,...)
    my $array = $dbx->sqlarray($sql, \%parameters); #returns [$,$,$,...]
    my @array = $dbx->sqlarray($sql, \%parameters); #returns ($,$,$,...)

## sqlhash

Returns the first two columns of the SQL result as a hash or hash reference {Key=>Value, Key=>Value, ...}

    my $hash = $dbx->sqlhash($sql,  @parameters); #returns {$=>$, $=>$, ...}
    my %hash = $dbx->sqlhash($sql,  @parameters); #returns ($=>$, $=>$, ...)
    my @hash = $dbx->sqlhash($sql,  @parameters); #this is ordered
    my @keys = grep {!($n++ % 2)} @hash;          #ordered keys

    my $hash = $dbx->sqlhash($sql, \@parameters); #returns {$=>$, $=>$, ...}
    my %hash = $dbx->sqlhash($sql, \@parameters); #returns ($=>$, $=>$, ...)
    my $hash = $dbx->sqlhash($sql, \%parameters); #returns {$=>$, $=>$, ...}
    my %hash = $dbx->sqlhash($sql, \%parameters); #returns ($=>$, $=>$, ...)

## sqlhashhash

Returns a hash where the keys are the values of the first column and the values are a hash reference of all (including the key) column values.

    my $hash = $dbx->sqlhashhash($sql, @parameters); #returns {$=>{}, $=>{}, ...}
    my %hash = $dbx->sqlhashhash($sql, @parameters); #returns ($=>{}, $=>{}, ...)
    my @hash = $dbx->sqlhashhash($sql, @parameters); #returns ($=>{}, $=>{}, ...) #ordered

## sqlarrayarray

Returns the SQL result as an array or array ref of array references (\[\],\[\],...) or \[\[\],\[\],...\]

    my $array = $dbx->sqlarrayarray($sql,  @parameters); #returns [[$,$,...],[],[],...]
    my @array = $dbx->sqlarrayarray($sql,  @parameters); #returns ([$,$,...],[],[],...)
    my $array = $dbx->sqlarrayarray($sql, \@parameters); #returns [[$,$,...],[],[],...]
    my @array = $dbx->sqlarrayarray($sql, \@parameters); #returns ([$,$,...],[],[],...)
    my $array = $dbx->sqlarrayarray($sql, \%parameters); #returns [[$,$,...],[],[],...]
    my @array = $dbx->sqlarrayarray($sql, \%parameters); #returns ([$,$,...],[],[],...)

## sqlarrayarrayname

Returns the SQL result as an array or array ref of array references (\[\],\[\],...) or \[\[\],\[\],...\] where the first row contains an array reference to the column names

    my $array = $dbx->sqlarrayarrayname($sql,  @parameters); #returns [[$,$,...],[]...]
    my @array = $dbx->sqlarrayarrayname($sql,  @parameters); #returns ([$,$,...],[]...)
    my $array = $dbx->sqlarrayarrayname($sql, \@parameters); #returns [[$,$,...],[]...]
    my @array = $dbx->sqlarrayarrayname($sql, \@parameters); #returns ([$,$,...],[]...)
    my $array = $dbx->sqlarrayarrayname($sql, \%parameters); #returns [[$,$,...],[]...]
    my @array = $dbx->sqlarrayarrayname($sql, \%parameters); #returns ([$,$,...],[]...)

Create an HTML table with [CGI](https://metacpan.org/pod/CGI)

    my $cgi  = CGI->new;
    my $html = $cgi->table($cgi->Tr([map {$cgi->td($_)} $dbx->sqlarrayarrayname($sql, @param)]));

## sqlarrayhash

Returns the SQL result as an array or array ref of hash references ({},{},...) or \[{},{},...\]

    my $array = $dbx->sqlarrayhash($sql,  @parameters); #returns [{},{},{},...]
    my @array = $dbx->sqlarrayhash($sql,  @parameters); #returns ({},{},{},...)
    my $array = $dbx->sqlarrayhash($sql, \@parameters); #returns [{},{},{},...]
    my @array = $dbx->sqlarrayhash($sql, \@parameters); #returns ({},{},{},...)
    my $array = $dbx->sqlarrayhash($sql, \%parameters); #returns [{},{},{},...]
    my @array = $dbx->sqlarrayhash($sql, \%parameters); #returns ({},{},{},...)

This method is best used to select a list of hashes out of the database to bless directly into a package.

    my $sql     = q{SELECT COL1 AS "id", COL2 AS "name" FROM TABLE1};
    my @objects = map {bless $_, MyPackage} $dbx->sqlarrayhash($sql,  @parameters);
    my @objects = map {MyPackage->new(%$_)} $dbx->sqlarrayhash($sql,  @parameters);

The @objects array is now a list of blessed MyPackage objects.

## sqlarrayhashname

Returns the SQL result as an array or array ref of hash references (\[\],{},{},...) or \[\[\],{},{},...\] where the first row contains an array reference to the column names

    my $array = $dbx->sqlarrayhashname($sql,  @parameters); #returns [[],{},{},...]
    my @array = $dbx->sqlarrayhashname($sql,  @parameters); #returns ([],{},{},...)
    my $array = $dbx->sqlarrayhashname($sql, \@parameters); #returns [[],{},{},...]
    my @array = $dbx->sqlarrayhashname($sql, \@parameters); #returns ([],{},{},...)
    my $array = $dbx->sqlarrayhashname($sql, \%parameters); #returns [[],{},{},...]
    my @array = $dbx->sqlarrayhashname($sql, \%parameters); #returns ([],{},{},...)

## sqlarrayobject

Returns the SQL result as an array of blessed hash objects in to the $class namespace.

    my $array    = $dbx->sqlarrayobject($class, $sql,  @parameters); #returns [bless({}, $class), ...]
    my @array    = $dbx->sqlarrayobject($class, $sql,  @parameters); #returns (bless({}, $class), ...)
    my ($object) = $dbx->sqlarrayobject($class, $sql,  {id=>$id});   #$object is bless({}, $class)

## sqlsort (Oracle Specific?)

Returns the SQL statement with the correct ORDER BY clause given a SQL statement (without an ORDER BY clause) and a signed integer on which column to sort.

    my $sql = $dbx->sqlsort(qq{SELECT 1,'Z' FROM DUAL UNION SELECT 2,'A' FROM DUAL}, -2);

Returns

    SELECT 1,'Z' FROM DUAL UNION SELECT 2,'A' FROM DUAL ORDER BY 2 DESC

Note: The sqlsort method is no longer preferred. It is recommended to use the newer sqlwhere capability.

## sqlarrayarraynamesort

Returns a sqlarrayarrayname for $sql sorted on column $n where n is an integer ascending for positive, descending for negative, and 0 for no sort.

    my $data = $dbx->sqlarrayarraynamesort($sql, $n,  @parameters);
    my $data = $dbx->sqlarrayarraynamesort($sql, $n, \@parameters);
    my $data = $dbx->sqlarrayarraynamesort($sql, $n, \%parameters);

Note: $sql must not have an "ORDER BY" clause in order for this function to work correctly.

Note: The sqlarrayarraynamesort method is no longer preferred. It is recommended to use the newer sqlwherearrayarrayname capability.

# METHODS (Read) - SQL::Abstract

Please note the "abs" API is a 100% pass through to [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract).  Please reference the [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract) documentation for syntax assistance with that API.

## abscursor

Returns the prepared and executed SQL cursor.

    my $sth = $dbx->abscursor($table, \@columns, \%where, \@order);
    my $sth = $dbx->abscursor($table, \@columns, \%where);          #no order required defaults to storage
    my $sth = $dbx->abscursor($table, \@columns);                   #no where required defaults to all
    my $sth = $dbx->abscursor($table);                              #no columns required defaults to '*' (all)

## absscalar

Returns the first row first column value as a scalar.

This works great for selecting one value.

    my $scalar = $dbx->absscalar($table, \@columns, \%where, \@order); #returns $

## absarray

Returns the SQL result as a array.

This works great for selecting one column from a table or selecting one row from a table.

    my @array = $dbx->absarray($table, \@columns, \%where, \@order); #returns ()
    my $array = $dbx->absarray($table, \@columns, \%where, \@order); #returns []

## abshash

Returns the first two columns of the SQL result as a hash or hash reference {Key=>Value, Key=>Value, ...}

    my $hash = $dbx->abshash($table, \@columns, \%where, \@order); #returns {}
    my %hash = $dbx->abshash($table, \@columns, \%where, \@order); #returns ()

## abshashhash

Returns a hash where the keys are the values of the first column and the values are a hash reference of all (including the key) column values.

    my $hash = $dbx->abshashhash($table, \@columns, \%where, \@order); #returns {}
    my %hash = $dbx->abshashhash($table, \@columns, \%where, \@order); #returns ()

## absarrayarray

Returns the SQL result as an array or array ref of array references (\[\],\[\],...) or \[\[\],\[\],...\]

    my $array = $dbx->absarrayarray($table, \@columns, \%where, \@order); #returns [[$,$,...],[],[],...]
    my @array = $dbx->absarrayarray($table, \@columns, \%where, \@order); #returns ([$,$,...],[],[],...)

## absarrayarrayname

Returns the SQL result as an array or array ref of array references (\[\],\[\],...) or \[\[\],\[\],...\] where the first row contains an array reference to the column names

    my $array = $dbx->absarrayarrayname($table, \@columns, \%where, \@order); #returns [[$,$,...],[],[],...]
    my @array = $dbx->absarrayarrayname($table, \@columns, \%where, \@order); #returns ([$,$,...],[],[],...)

## absarrayhash

Returns the SQL result as an array or array ref of hash references ({},{},...) or \[{},{},...\]

    my $array = $dbx->absarrayhash($table, \@columns, \%where, \@order); #returns [{},{},{},...]
    my @array = $dbx->absarrayhash($table, \@columns, \%where, \@order); #returns ({},{},{},...)

## absarrayhashname

Returns the SQL result as an array or array ref of hash references ({},{},...) or \[{},{},...\] where the first row contains an array reference to the column names.

    my $array = $dbx->absarrayhashname($table, \@columns, \%where, \@order); #returns [[],{},{},...]
    my @array = $dbx->absarrayhashname($table, \@columns, \%where, \@order); #returns ([],{},{},...)

## absarrayobject

Returns the SQL result as an array of blessed hash objects in to the $class namespace.

    my $array = $dbx->absarrayobject($class, $table, \@columns, \%where, \@order); #returns [bless({}, $class), ...]
    my @array = $dbx->absarrayobject($class, $table, \@columns, \%where, \@order); #returns (bless({}, $class), ...)

# METHODS (Read) - SQL + SQL::Abstract->where

## sqlwhere

Returns SQL part appended with the WHERE and ORDER BY clauses

    my ($sql, @bind) = $sql->sqlwhere($sqlpart, \%where, \@order);

Note: sqlwhere function should be ported into [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract) RT125805

## sqlwherecursor

    my $return = $sql->sqlwherecursor($sqlpart, \%where, \@order);

## sqlwherescalar

    my $return = $sql->sqlwherescalar($sqlpart, \%where, \@order);

## sqlwherearray

    my $return = $sql->sqlwherearray($sqlpart, \%where, \@order);

## sqlwherehash

    my $return = $sql->sqlwherehash($sqlpart, \%where, \@order);

## sqlwherehashhash

    my $return = $sql->sqlwherehashhash($sqlpart, \%where, \@order);

## sqlwherearrayarray

    my $return = $sql->sqlwherearrayarray($sqlpart, \%where, \@order);

## sqlwherearrayarrayname

    my $return = $sql->sqlwherearrayarrayname($sqlpart, \%where, \@order);

## sqlwherearrayhash

    my $return = $sql->sqlwherearrayhash($sqlpart, \%where, \@order);

## sqlwherearrayhashname

    my $return = $sql->sqlwherearrayhashname($sqlpart, \%where, \@order);

## sqlwherearrayobject

    my $return = $sql->sqlwherearrayobject($class, $sqlpart, \%where, \@order);

# METHODS (Write) - SQL

Remember to commit or use AutoCommit

Note: It appears that some drivers do not support the count of rows.

## sqlinsert, insert

Returns the number of rows inserted by the SQL statement.

    my $count = $dbx->sqlinsert( $sql,   @parameters);
    my $count = $dbx->sqlinsert( $sql,  \@parameters);
    my $count = $dbx->sqlinsert( $sql,  \%parameters);

## sqlupdate, update

Returns the number of rows updated by the SQL statement.

    my $count = $dbx->sqlupdate( $sql,   @parameters);
    my $count = $dbx->sqlupdate( $sql,  \@parameters);
    my $count = $dbx->sqlupdate( $sql,  \%parameters);

## sqldelete, delete

Returns the number of rows deleted by the SQL statement.

    my $count = $dbx->sqldelete($sql,   @parameters);
    my $count = $dbx->sqldelete($sql,  \@parameters);
    my $count = $dbx->sqldelete($sql,  \%parameters);

Note: Some Oracle clients do not support row counts on delete instead the value appears to be a success code.

## sqlexecute, execute, exec

Executes stored procedures and generic SQL.

    my $out;
    my $return = $dbx->sqlexecute($sql, $in, \$out);            #pass in/out vars as scalar reference
    my $return = $dbx->sqlexecute($sql, [$in, \$out]);
    my $return = $dbx->sqlexecute($sql, {in=>$in, out=>\$out});

Note: Currently sqlupdate, sqlinsert, sqldelete, and sqlexecute all point to the same method.  This may change in the future if we need to change the behavior of one method.  So, please use the correct method name for your function.

# METHODS (Write) - SQL::Abstract

## absinsert

Returns the number of rows inserted.

    my $count = $dbx->absinsert($table, \%column_values);

## absupdate

Returns the number of rows updated.

    my $count = $dbx->absupdate($table, \%column_values, \%where);

## absdelete

Returns the number of rows deleted.

    my $count = $dbx->absdelete($table, \%where);

# METHODS (Write) - Bulk - SQL

## bulksqlinsertarrayarray

Insert records in bulk.

    my @arrayarray = (
                      [$data1, $data2, $data3, $data4, ...],
                      [@row_data_2],
                      [@row_data_3], ...
                     );
    my $count      = $dbx->bulksqlinsertarrayarray($sql, \@arrayarray);

## bulksqlinsertarrayhash

Insert records in bulk.

    my @columns   = ("Col1", "Col2", "Col3", "Col4", ...);                         #case sensitive with respect to @arrayhash
    my @arrayhash = (
                     {C0l1=>data1, Col2=>$data2, Col3=>$data3, Col4=>$data4, ...}, #extra hash items ignored when sliced using @columns
                     \%row_hash_data_2,
                     \%row_hash_data_3, ...
                    );
    my $count     = $dbx->bulksqlinsertarrayhash($sql, \@columns, \@arrayhash);

## bulksqlinsertcursor

Insert records in bulk.

Step 1 select data from table 1 in database 1

    my $sth1  = $dbx1->sqlcursor('Select Col1 AS "ColA", Col2 AS "ColB", Col3 AS "ColC" from table1');

Step 2 insert in to table 2 in database 2

    my $count = $dbx2->bulksqlinsertcursor($sql, $sth1);

Note: If you are inside a single database, it is much more efficient to use insert from select syntax as no data needs to be transferred to and from the client.

## bulksqlupdatearrayarray

Update records in bulk.

    my @arrayarray   = (
                        [$data1, $data2, $data3, $data4, $id],
                        [@row_data_2],
                        [@row_data_3], ...
                       );
    my $count        = $dbx->bulksqlupdatearrayarray($sql, \@arrayarray);

# METHODS (Write) - Bulk - SQL::Abstract-like

These bulk methods do not use [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract) but our own similar SQL insert and update methods.

## bulkabsinsertarrayarray

Insert records in bulk.

    my @columns    = ("Col1", "Col2", "Col3", "Col4", ...);
    my @arrayarray = (
                      [data1, $data2, $data3, $data4, ...],
                      [@row_data_2],
                      [@row_data_3], ...
                     );
    my $count      = $dbx->bulkabsinsertarrayarray($table, \@columns, \@arrayarray);

## bulkabsinsertarrayhash

Insert records in bulk.

    my @columns   = ("Col1", "Col2", "Col3", "Col4", ...);                           #case sensitive with respect to @arrayhash
    my @arrayhash = (
                     {C0l1=>data1, Col2=>$data2, Col3=>$data3, Col4=>$data4, ...}, #extra hash items ignored when sliced using @columns
                     \%row_hash_data_2,
                     \%row_hash_data_3, ...
                    );
    my $count     = $dbx->bulkabsinsertarrayhash($table, \@columns, \@arrayhash);

## bulkabsinsertcursor

Insert records in bulk.

Step 1 select data from table 1 in database 1

    my $sth1  = $dbx1->sqlcursor('Select Col1 AS "ColA", Col2 AS "ColB", Col3 AS "ColC" from table1');

Step 2 insert in to table 2 in database 2

    my $count = $dbx2->bulkabsinsertcursor($table2, $sth1);

    my $count = $dbx2->bulkabsinsertcursor($table2, \@columns, $sth1); #if your DBD/API does not support column alias support

Note: If you are inside a single database, it is much more efficient to use insert from select syntax as no data needs to be transferred to and from the client.

## bulkabsupdatearrayarray

Update records in bulk.

    my @setcolumns   = ("Col1", "Col2", "Col3", "Col4");
    my @wherecolumns = ("ID");
    my @arrayarray   = (
                        [$data1, $data2, $data3, $data4, $id],
                        [@row_data_2],
                        [@row_data_3], ...
                       );
    my $count        = $dbx->bulkabsupdatearrayarray($table, \@setcolumns, \@wherecolumns, \@arrayarray);

# Constructors

## abs

Returns a [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract) object

# Methods (Informational)

## dbms\_name

Return the DBMS Name (e.g. Oracle, MySQL, PostgreSQL)

# Methods (Session Management)

These methods allow the setting of Oracle session features that are available in the v$session table.  If other databases support these features, please let me know.  But, as it stands, these methods are non operational unless SQL\_DBMS\_NAME is Oracle.

## module

Sets and returns the v$session.module (Oracle) value.

Note: Module is set for you by DBD::Oracle.  However you may set it however you'd like.  It should be set once after connection and left alone.

    $dbx->module("perl@host");      #normally set by DBD::Oracle
    $dbx->module($module, $action); #can set initial action too.
    my $module = $dbx->module();

## client\_info

Sets and returns the v$session.client\_info (Oracle) value.

    $dbx->client_info("Running From crontab");
    my $client_info = $dbx->client_info();

You may use this field for anything up to 64 characters!

    $dbx->client_info(join "~", (ver => 4, realm => "ldap", grp =>25)); #tilde is a fairly good separator
    my %client_info = split(/~/, $dbx->client_info());

## action

Sets and returns the v$session.action (Oracle) value.

    $dbx->action("We are Here");
    my $action = $dbx->action();

Note: This should be updated fairly often. Every loop if it runs for more than 5 seconds and may end up in V$SQL\_MONITOR.

    while ($this) {
      local $dbx->{'action'} = "This Loop"; #tied to the database with a little Perl sugar
    }

## client\_identifier

Sets and returns the v$session.client\_identifier (Oracle) value.

    $dbx->client_identifier($login);
    my $client_identifier = $dbx->client_identifier();

Note: This should be updated based on the login of the authenticated end user.  I use the client\_info->{'realm'} if you have more than one authentication realm.

For auditing add this to an update trigger

    new.UPDATED_USER = sys_context('USERENV', 'CLIENT_IDENTIFIER');

# TODO

Sort functions sqlsort and sqlarrayarraynamesort may not be portable. It is now recommend to use sqlwhere methods instead.

Add some kind of capability to allow hash binds to bind as some native type rather than all strings.

Hash binds scan comments for bind variables e.g. /\* :variable \*/

Improve error messages

# BUGS

Please open on GitHub

# AUTHOR

    Michael R. Davis

# COPYRIGHT

MIT License

Copyright (c) 2023 Michael R. Davis

# SEE ALSO

## The Competition

[DBIx::DWIW](https://metacpan.org/pod/DBIx::DWIW), [DBIx::Wrapper](https://metacpan.org/pod/DBIx::Wrapper), [DBIx::Simple](https://metacpan.org/pod/DBIx::Simple), [Data::Table::fromSQL](https://metacpan.org/pod/Data::Table::fromSQL), [DBIx::Wrapper::VerySimple](https://metacpan.org/pod/DBIx::Wrapper::VerySimple), [DBIx::Raw](https://metacpan.org/pod/DBIx::Raw), [Dancer::Plugin::Database](https://metacpan.org/pod/Dancer::Plugin::Database) quick\_\*, [Mojo::Pg::Results](https://metacpan.org/pod/Mojo::Pg::Results) (arrays & hashes)

## The Building Blocks

[DBI](https://metacpan.org/pod/DBI), [SQL::Abstract](https://metacpan.org/pod/SQL::Abstract)
