# $Id: DBMaker.pm,v 0.13 1999/01/29 00:34:39 $
#
# Copyright (c) 1999 DBMaker team
# portions Copyright (c) 1994,1995,1996,1998  Tim Bunce
# portions Copyright (c) 1997,1998  Jeff Urlwin
# portions Copyright (c) 1997  Thomas K. Wenrich
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.
#
require 5.003;

$DBD::DBMaker::VERSION = '0.13';

{
    package DBD::DBMaker;

    use DBI ();
    use DynaLoader ();

    @ISA = qw(DynaLoader);

    my $Revision = substr(q$Revision: 1.12 $, 10);

    require_version DBI 0.86;

    bootstrap DBD::DBMaker $VERSION;

    $err = 0;            # holds error code   for DBI::err
    $errstr = "";        # holds error string for DBI::errstr
    $sqlstate = "00000";
    $drh = undef;        # holds driver handle once initialised

    sub driver{
    return $drh if $drh;
    my($class, $attr) = @_;

    $class .= "::dr";

    # not a 'my' since we use it above to prevent multiple drivers

    $DBD::DBMaker::drh = DBI::_new_drh($class, {
        'Name' => 'DBMaker',
        'Version' => $DBD::DBMaker::VERSION,
        'Err'    => \$DBD::DBMaker::err,
        'Errstr' => \$DBD::DBMaker::errstr,
        'State' => \$DBD::DBMaker::sqlstate,
        'Attribution' => 'DBMaker DBD by DBMaker team',
        });

    $drh;
    }

    1;
}


{   package DBD::DBMaker::dr; # ====== DRIVER ======
    use strict;

#    sub errstr {
#    DBD::DBMaker::errstr(@_);
#    }
#    sub err {
#    DBD::DBMaker::err(@_);
#    }

    sub data_sources {
      my (%sources, @ini, $dmini);
      $dmini = 'dmconfig.ini';
      if ($^O eq "MSWin32") {
        push(@ini, "$ENV{'windir'}/dmconfig.ini");
      }
      else {
        my $ddir;
        foreach $ddir ( '.', $ENV{'DBMAKER'}, (getpwnam('dbmaker'))[7]."/data") {
          push(@ini, "$ddir/$dmini") if($ddir && -f "$ddir/$dmini" && -r "$ddir/$dmini");
        }
      }

      foreach $dmini (@ini) {
        open(INF, $dmini) || next;
        while(<INF>) {
          $sources{uc($1)} = 1 if (/^\s*\[([^\]]+)\]\s*$/);
        }
      }
      return sort keys %sources;
    }

    sub connect {
    my $drh = shift;
    my ($dbname, $user, $auth)= @_;

    if ($dbname){    # application is asking for specific database
    }

    # create a 'blank' dbh

    my $this = DBI::_new_dbh($drh, {
        'Name' => $dbname,
        'USER' => $user, 
        'CURRENT_USER' => $user,
        });

    # Call DBMaker logon func in DBMaker.xs file
    # and populate internal handle data.

#    print "Warn: DBI_DSN not defined\n" unless defined($dbname);
#    print "Warn: DBI_USER not defined\n" unless defined($user);
#   print "Warn: DBI_PASS not defined\n" unless defined($auth);

    $dbname = '' unless(defined($dbname));    # hate strict -w
    $user = '' unless(defined($user));      
    $auth = '' unless(defined($auth));      

    DBD::DBMaker::db::_login($this, $dbname, $user, $auth)
        or return undef;

    $this;
    }

}


{   package DBD::DBMaker::db; # ====== DATABASE ======
    use strict;

#    sub errstr {
#    DBD::DBMaker::errstr(@_);
#    }

    sub prepare {
    my($dbh, $statement, @attribs)= @_;

    # create a 'blank' dbh

    my $sth = DBI::_new_sth($dbh, {
        'Statement' => $statement,
        });

    # Call DBMaker OCI oparse func in DBMaker.xs file.
    # (This will actually also call oopen for you.)
    # and populate internal handle data.

    DBD::DBMaker::st::_prepare($sth, $statement, @attribs)
        or return undef;

    $sth;
    }

    sub columns {     # return sth
    my ($dbh, $catalog, $schema, $table, $column) = @_;

    # create a "blank" statement handle
    my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLColumns" });

    _columns($dbh,$sth, $catalog, $schema, $table, $column)
        or return undef;

    $sth;
    }

    sub table_info {    # return sth
    my($dbh) = @_;        # XXX add qualification

    # create a "blank" statement handle
    my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLTables" });

    # XXX use qaulification(s) (qual, schema, etc?) here...
    DBD::DBMaker::db::_table_info($dbh,$sth, "")
        or return undef;

    $sth;
    }

    sub ping {
        # assuming a prepare will need a connection to the database
        #
    my($dbh) = @_;
    my $old_sigpipe = $SIG{PIPE};
    $SIG{PIPE} = sub { } ; # in case DBMaker UPIPE connection is down
    my $rv;
    eval {
        my $sth = $dbh->prepare("select VERSION from SYSINFO");
        if ($sth) {
        $rv = $sth->execute();
        $sth->finish();
        }

    } or $rv = undef;
    $SIG{PIPE} = $old_sigpipe;
    return defined $rv;
    }

    sub type_info_all {
    my ($dbh, $sqltype) = @_;
    my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLGetTypeInfo" });
    DBD::DBMaker::db::_get_type_info($dbh,$sth, "")
        or return undef;
    my $info = $sth->fetchall_arrayref;
    unshift @$info, {
        map { ($sth->{NAME}->[$_] => $_) } 0..$sth->{NUM_OF_FIELDS}-1
    };
    return $info;
    }

    # Call the ODBC function SQLGetInfo
    # Args are:
    #    $dbh - the database handle
    #    $item: the requested item.  For example, pass 6 for SQL_DRIVER_NAME
    # See the ODBC documentation for more information about this call.
    #
    sub GetInfo {
    my ($dbh, $item) = @_;
    _GetInfo($dbh, $item);
    }

    sub GetFunctions {
    my ($dbh, $item) = @_;
    _GetFunctions($dbh, $item);
    }

    sub GetTypeInfo {
    my ($dbh, $sqltype) = @_;
    # create a "blank" statement handle
    my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLGetTypeInfo" });
    # print "SQL Type is $sqltype\n";
    _get_type_info($dbh, $sth, $sqltype) or return undef;
    $sth;
    }

    # Call the ODBC function SQLStatistics
    # Args are:
    # See the ODBC documentation for more information about this call.
    #
    sub GetStatistics {
            my ($dbh, $Catalog, $Schema, $Table, $Unique) = @_;
            # create a "blank" statement handle
            my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLStatistics" });
            _GetStatistics($dbh, $sth, $Catalog, $Schema, $Table, $Unique) or return undef;
            $sth;
    }

    # Call the ODBC function SQLForeignKeys
    # Args are:
    # See the ODBC documentation for more information about this call.
    #
    sub GetForeignKeys {
            my ($dbh, $PK_Catalog, $PK_Schema, $PK_Table, $FK_Catalog, $FK_Schema, $FK_Table) = @_;
            # create a "blank" statement handle
            my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLForeignKeys" });
            _GetForeignKeys($dbh, $sth, $PK_Catalog, $PK_Schema, $PK_Table, $FK_Catalog, $FK_Schema, $FK_Table) or return undef;
            $sth;
    }

    # Call the ODBC function SQLPrimaryKeys
    # Args are:
    # See the ODBC documentation for more information about this call.
    #
    sub GetPrimaryKeys {
            my ($dbh, $Catalog, $Schema, $Table) = @_;
            # create a "blank" statement handle
            my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLPrimaryKeys" });
            _GetPrimaryKeys($dbh, $sth, $Catalog, $Schema, $Table) or return undef;
            $sth;
    }

}


{   package DBD::DBMaker::st; # ====== STATEMENT ======
    use strict;

    sub errstr {
    DBD::DBMaker::errstr(@_);
    }

    sub ColAttributes {        # maps to SQLColAttributes
    my ($sth, $colno, $desctype) = @_;
    my $tmp = _ColAttributes($sth, $colno, $desctype);
    $tmp;
    }

    # DBMaker private function for output column content to a user file
    # Args are:
    #
    sub BindColToFile {
    my ($sth, $colno, $file_prefix, $fgOverwrite) = @_;
    _BindColToFile($sth, $colno, $file_prefix, $fgOverwrite);
    }

}

1;

__END__

# Below is the stub of documentation for your module. You better edit it!

=head1 NAME

DBD::DBMaker - DBD driver to access DBMaker database

=head1 SYNOPSIS

  require DBI;

  $dbh = DBI->connect('DBI:DBMaker:' . $database, $user, $pass);
  $dbh = DBI->connect($database, $user, $pass, 'DBMaker');

See the DBI module documentation for more information.

=head1 DESCRIPTION

This module is the low-level driver to access the DBMaker database 
using the DBI interface. Please refer to the DBI documentation
for using it.

=head1 The DBI Interface

This documentation describes driver specific behavior and restrictions,
and a brief description of each method and attribute. It is not supposed to 
be used as the only reference for the user. In any case consult the DBI 
documentation first !

=head2 The DBI Class Methods

=over 4

=item connect

Establishes a connection to a database server

To connect to a database with a minimum of parameters, use the
following syntax: 

  $dbh = DBI->connect('DBI:DBMaker:$dbname', $user, $pass);
  $dbh = DBI->connect($dbname, $user, $pass, 'DBMaker');

Or you can set environment variable DBI_DSN, DBI_USER, DBI_PASS and 
use the following syntax:

The DBI environment variable:

  In CSH,TCSH
  setenv DBI_DSN 'dbi:DBMaker:DBNAME'
  setenv DBI_USER 'SYSADM'
  setenv DBI_PASS ''
 
  In SH, BASH
  export DBI_DSN='dbi:DBMaker:DBNAME'
  export DBI_USER='SYSADM'
  export DBI_PASS=''
 
  $dbh = DBI->connect();

If you cannot connect to the specified $dbname, please check if related
database config is located at the following path or not.  For detail 
setting for DBMaker's database config please reference DBMaker's DBA 
manual. 

The search order for DBMaker's config file (dmconfig.ini) is listed as
follows:

  (1) Your local directory which you run your perl program.
  (2) DBMAKER environment variable for indicating where your 
      dmconfig.ini located.
  (3) ~dbmaker/data

If you want your database to be able to be accessed by others, you can 
append your database section to ~dbmaker/data/dmconfig.ini by editor. 
Or you can tell user to append the database section in their local 
dmconfig.ini.

=item disconnect

Disconnects from the database server.

  Usage:
  $rc = $dbh->disconnect();  

=item data_sources

Returns a list of all data sources (databases) available via the DBMaker 
driver. The search order is same as the search for DBMaker's dmconfig.ini 
file.

  Example:  For list all database avaiable for DBMaker
  my @ary =DBI->data_sources("DBMaker");
  my $i=0;
  print "Show a list of all data sources availabled via the DBMaker:\n";
  while($ary[$i]){
    print "$ary[$i]\n";
    $i=$i+1;
  }

The following DBI class method are handled by the DBI, no driver-specific 
impact.

=item available_drivers

Returns a list of all available drivers by searching for DBD::* modules
through the directories in @INC.

  Usage:
  @ary = DBI->available_drivers;

=item trace

Perform tracing for debugging.

  Usage:
  DBI->trace($trace_level)
  DBI->trace($trace_level, $trace_filename)

=item connect_cached

Database handle returned will be stored in a hash associated with the given
parameters.

=back

=head2 The DBI database handle Methods

=over 4

=item prepare

Prepares a SQL statement for execution.

  Usage:
  $sth = $dbh->prepare($statement)        
  $sth = $dbh->prepare($statement, \%attr);

  DBD::DBMaker note: As the DBD driver looks for placeholders within
  the statement, additional to the ANSI style '?' placeholders
  the DBMaker driver can parse :1, :2 and :foo style placeholders
  (like Oracle).

  Example:
  my $sth1=$dbh->prepare("SELECT id,name,title,phone FROM employees1 where id = ?");
  or
  my $sql=qq{INSERT INTO employees1 values(:c1,:c2,:c3,:c4)};
  my $sth = $dbh->prepare($sql);

=item do

Prepares and executes a SQL statement.

  Usage:
  $rv  = $dbh->do($statement);

=item commit

Commit the most recent series of database changes if the database support
transaction.

  Usage:
  $rc  = $dbh->commit;

=item rollback

Rollback the most recent series of uncommitted database changes if the
database support transaction.  The default commit mode is on.

  Usage:
  $rc  = $dbh->rollback;

=item ping

Attempts to determine, if the database server is still running and the 
connection still working.

  Usage:
  $rc = $dbh->ping;

=item table_info

Returns an active statement handle that can be used to fetch information 
about tables and views that exist in the database.

  Example:
  $sth = $dbh->table_info();
  while (my @ary=$sth->fetchrow_array)
  {
  print "$ary[0],$ary[1],$ary[2],$ary[3],$ary[4]\n";
  }

=item type_info_all

Returns a reference to an array which holds information about each data 
variant supported by the database and driver.

  Example:
  my $type_info_all = $dbh->type_info_all;
  my $iname = $type_info_all->[0]{TYPE_NAME};
  my $itype = $type_info_all->[0]{DATA_TYPE};
  my $icolsize = $type_info_all->[0]{COLUMN_SIZE};

  shift @$type_info_all;
  foreach $rtype ( @$type_info_all ) {
     print "$$rtype[$iname],$$rtype[$itype],$$rtype[$icolsize]\n";
  }

=item The following Database handle methods are handled by DBI.

=item prepare_cached

Like the prepare except that the statement handled returned will be stored 
in a hash associated with the $dbh.

=item selectrow_array 

Combines prepare, execute and fetchrow_array into a single call. Fetch first 
row's result into an array.

  Example:
  my @ary = $dbh->selectrow_array("select * from t1");
  foreach my $i (@ary) {
  print "$i, ";
  }

=item selectall_arrayref

Combines prepare, execute and fetchall_arrayref into a single call.

  Example:
  my $aryref = $dbh->selectall_arrayref("select * from employees1");
 
  my $i = 0;
  while (defined($aryref->[$i][0])) {
        printf("%s,%s,%s,%s\n", $aryref->[$i][0], $aryref->[$i][1],
                                $aryref->[$i][2], $aryref->[$i][3]);
        $i++;
  }

=item selectcol_arrayref

Combines prepare,execute and fetch one column from all the rows into single 
call.  It returns a reference to an array contain the values of the first 
column from each row.

  Example:
  my $aryref = $dbh->selectcol_arrayref("select * from employees1");

  my $i = 0;
  while (defined($aryref->[$i])) {
         print "$aryref->[$i]\n";  
         $i++;
  }

=item quote

Quote a string literal for use as a literal value in an SQL statement.

  Usage:
  $sql = $dbh->quote($string);

=item tables

Returns a list of table and view names (see table_info).

  Example:
  @rowdata = $dbh->tables();
  my $table;
  foreach $table (@rowdata)
  {
  print "table = $table\n";
  }

=item type_info

Returns a list of hash references holding information about one or more
variant of $data_type (see type_info_all).

  Example:
  my $typref = $dbh->type_info(4);
  print  $typref->{"TYPE_NAME"}.",";
  print  $typref->{"DATA_TYPE"}.",";
  print  $typref->{"COLUMN_SIZE"}.",";
  print  $typref->{"LITERAL_PREFIX"}.",";
  print  $typref->{"LITERAL_SUFFIX"}.",";
  print  $typref->{"CREATE_PARAMS"}.","; 
  print  $typref->{"NULLABLE"}.",";
  print  $typref->{"CASE_SENSITIVE"}.",";
  print  $typref->{"SEARCHABLE"}.",";
  print  $typref->{"UNSIGNED_ATTRIBUTE"}.",";
  print  $typref->{"FIXED_PREC_SCALE"}.",";  
  print  $typref->{"AUTO_UNIQUE_VALUE"}.","; 
  print  $typref->{"LOCAL_TYPE_NAME"}.",";   
  print  $typref->{"MINIMUM_SCALE"}.",";     
  print  $typref->{"MAXIMUM_SCALE"}.",";     
  print  $typref->{"NUM_PREC_RADIX"}.",";    

=back

=head2 The Statement Handle Methods

=over 4

=item bind_param

Bind a value with a placeholder embedded in the prepared statement.

  Example:

  . To bind a parameter and specify the SQL type:

  $rc = $sth->bind_param($p_num,$bind_var, {TYPE => DBI::SQL_INTEGER});
  $rc = $sth->bind_param($p_num,$bind_var, DBI::SQL_INTEGER);

  . To bind a parameter without specifying the SQL type:

  $rc = $sth->bind_param($p_num,$bind_var);

=item bind_param_inout

Like bind_param but also enables values to be output from the statement.

  Example:
  my $sql=qq{call sp1(?)};
  my $sth = $dbh->prepare($sql);
  my $outparm;
  $sth->bind_param_inout(1, \$outparm, 20);
  $sth->execute()||die "$DBI::errstr";
  print "OutParam = $outparm\n";
  $sth->finish();

=item execute

Execute the prepared statement.

  Usage:
  $rv = $sth->execute;
  $rv = $sth->execute(@bind_values);

  Example:
  $sth->execute(1,"aaa","bbb","02-1234567");

=item finish

Finishes a statement and let the system free resources (SQL_CLOSE).

  Usage:
  $rc  = $sth->finish;

=item rows

Returns the number of rows affected.

=item fetch

Fetch a row into bound variable.

  Example:
  $sth->bind_col( 1, \$c1);
  while( $sth->fetch() ) {  
      print "c1 = $c1\n";   
  }

=item bind_col

Binds an output column of select statement to a perl var.  You don't need 
to do this but it can be useful for some application.

  Usage:
  $rc = $sth->bind_col($col_num, \$col_variable);

  Example:
  $sth->bind_col(1, \$c1);

=item The following Statement handle methods are handled by DBI:

=item bind_columns

Calls bind_col for each column of the select statement.

  Usage:
  $rc = $sth->bind_columns(@list_of_refs_to_vars_to_bind);

  Example:
  $sql = qq{ SELECT Id,Name,Title,Phone FROM Employees };
  my $sth = $dbh->prepare( $sql );
  $sth->execute()||die "$DBI::errstr";
  my( $Id, $Name, $Title, $Phone );
  $sth->bind_columns( undef, \$Id, \$Name, \$Title, \$Phone );

=item fetchrow_array

Fetches the next row as an array of fields.

  Example:
  my $sth=$dbh->prepare("SELECT id,name,title,phone FROM employees1");
  $sth->execute();
  while(my @ary=$sth->fetchrow_array){
  print "$ary[0],$ary[1],$ary[2],$ary[3]\n";
  }
  $sth->finish();

=item fetchrow_arrayref

Fetches next row as a reference array of fields.

  Example: (prepare,execute same as above example)
  while (my $ary_ref=$sth->fetchrow_arrayref){
  print "$ary_ref->[0],$ary_ref->[1],$ary_ref->[2]\n";
  }

=item fetchrow_hashref

Fetches next row as a reference to a hash table.

  Example:
  while (my $hash_ref=$sth->fetchrow_hashref){
        print $hash_ref->{"id"},",", $hash_ref->{"name"},
        ",",$hash_ref->{"title"},",",$hash_ref->{"phone"},"\n";
  }

=item fetchall_arrayref

Fetches all data as an array of arrays.

  Example:
  my $i=0;
  while($tb1_ary_ref->[$i][0]){
       print $tb1_ary_ref->[$i][0],",",$tb1_ary_ref->[$i][1],",",
             $tb1_ary_ref->[$i][2],",",$tb1_ary_ref->[$i][3],"\n";
       $i++;
  }

=item dump_results

Fetches all the rows from $sth and prints the result to $fh or STDOUT.

  Example:
  my $sql=qq{SELECT id,name,title,phone FROM employees1 };
  my $sth=$dbh->prepare($sql); 
  $sth->execute(); 
  $dbh->dump_results();

=back

=head2 Method common to all handles

=over 4

=item err

Returns the native database engine error code from the last driver function
called.

=item errstr

Returns the native database engine error message from the last driver
function called.

=item state

Returns an error code in the standard SQLSTATE five character format.

=item trace

DBI trace information can be enabled for a specific handle (and any future 
children of that handle) by setting the trace level using the trace method.

=item trace_msg

Writes $message_text to trace file if trace is enabled for $h or for the
DBI as a whole.

=item func

The func method can be used to call private non-standard and non-portable
methods implemented by the driver.  This is not related to calling Stored
procedure nor is DBI support stored procedure.

=back
 
=head1 Attributes

=head2 The DBI Dynamic Attributes

These attributes are always associated with the last handle used.  They
should be used immediately after calling the method which 'sets' them.

=over 4

=item $DBI::err

Equivalent to $dbh->err

=item $DBI::errstr

Equivalent to $dbh->errstr

=item $DBI::state

Equivalent to $dbh->state

=item $DBI::rows

Equivalent to $dbh->rows

=back

=head2  Attributes common to all handles

=over 4

These attributes are common to all types of DBI handles.

Example:
 
  $h->{AttributeName} = ...;    # set/write
  ... = $h->{AttributeName};    # get/read 

=item Warn(boolean) default: enabled

Enables useful warnings for certain bad practices.

=item Active (read-only)

True if the handle object is 'active'.

=item Kids (read-only)

For a driver handle, Kids is the number of current existing database handle. 
For a database handle, Kids is the number of current existing statement 
handle.  

=item ActiveKids (read-only)

Like Kids (above), but only count those that are Active.

=item CachedKids (hash ref)

For a database/driver handle, returns a reference to the cache (hash) of
statement handles created by the prepare_cached/connect_cached method.

=item CompatMode (boolean)   default: off and no effect with DBMaker.

Used by emulation layers (such as Oraperl) to enable compatible behaviour
in the underlying driver (e.g., DBD::Oracle) for this handle. Not normally
set by application code.

=item InactiveDestroy (boolean) default: off

The attribute can be used to disable the database related effect of 
DESTROY'ing a handle.

=item PrintError (boolean)   default: on

This attribute can be used to force errors to generate warnings (using warn)
in addition to returning error codes in the normal way.

=item RaiseError (boolean)   default: off

This attribute can be used to force errors to raise exceptions rather than 
simply return error codes in the normal way. 

=item ChopBlanks (boolean)   default: false

This attribute can be used to control the trimming of trailing space 
characters from *fixed width* character (CHAR) fields. No other field 
types are affected.

=item LongReadLen (unsigned integer) default: 80

This attribute may be used to control the maximum length of LONG VARCHAR, 
LONG VARBINARY ('blob', 'memo' etc.) fields which the driver will *read* 
from the database automatically when it fetches each row of data. The
LongReadLen attribute only relates to fetching/reading long values it is 
*not* involved in inserting/updating them.

  Example:
  $sth = $dbh->prepare("select * from foo",
                     { 'LongReadLen' => 4096, }
                      );

A value of 0 means don't automatically fetch any long data.  You may use 
blob_read to read the whole long data after fetch.

  Example:
  $sth = $dbh->prepare("SELECT memo FROM tab1 WHERE id = 12345",
                     { 'LongReadLen' => 0 });
  $sth->execute();
  @row=$sth->fetchrow();
  my $offset = 100;
  my $blob = "";
  # Read 100 bytes and concate the data to $blob
  while ($frag = $sth->blob_read(1, $offset, 100)) {
      $offset += length($frag);
      $blob .= $frag;
  }
  $sth->finish();

=item LongTruncOk (boolean)   default: false

This attribute may be used to control the effect of fetching a long field 
value which has been truncated (typically because it's longer than the 
value of the LongReadLen attribute).
 
By default LongTruncOk is false and fetching a truncated long value will 
cause the fetch to fail.

=back

=head2  Database Handle Attributes

This section describes attributes specific to database handles.

=over 4

=item AutoCommit (boolean)    default: on

If true then database changes cannot be rolled-back (undone). If false 
then database changes automatically occur within a 'transaction' which
must either be committed or rolled-back using the commit or rollback
methods.

=item Driver (handle)

Holds the handle of the parent Driver. The only recommended use for
this is to find the name of the driver using:

  $dbh->{Driver}->{Name}

=item Name (string)

Holds the 'name' of the database. Usually (and recommended to be) the same
as the "dbi:DriverName:..." string used to connect to the database but
with the leading "dbi:DriverName:" removed.

=item RowCacheSize (integer) undef

A hint to the driver indicating the size of local row cache the application
would like the driver to use for future select statements. This value is
undef because currently DBMaker does not allow setting for the prefetched
row size.

=back

=head2 Statement Handle Attributes

This section describes attributes specific to statement handles. Most of
these attributes are read-only.
 
Example:
 
  ... = $h->{NUM_OF_FIELDS};    # get/read

=over 4

=item NUM_OF_FIELDS (integer)  read-only

Number of fields (columns) the prepared statement will return. Non-select
statements will have NUM_OF_FIELDS = 0.

=item NUM_OF_PARAMS (integer)  read-only

The number of parameters (placeholders) in the prepared statement.

=item NAME (array-ref)         read-only

Returns a *reference* to an array of field names for each column.

  Example: 
  print "First column name: $sth->{NAME}->[0]\n";

=item NAME_lc (array-ref)      read-only

Like the NAME entry elsewhere in this document but always returns lowercase 
names.

=item NAME_uc (array-ref)      read-only

Like the NAME entry elsewhere in this document but always returns uppercase
names.

=item TYPE (array-ref)         read-only

Returns a *reference* to an array of integer values for each column.  The
value indicates the data type of the corresponding column.

=item PRECISION (array-ref)    read-only

Returns a *reference* to an array of integer values for each column.  For
nonnumeric columns the value generally refers to either the maximum length
or the defined length of the column. For numeric columns the value refers 
to the maximum number of significant digits used by the data type (without
considering a sign character or decimal point). 

=item SCALE (array-ref)        read-only

Returns a *reference* to an array of integer values for each column.  NULL
(undef) values indicate columns where scale is not applicable. 

=item NULLABLE (array-ref)     read-only

Returns a *reference* to an array indicating the possibility of each column
returning a null: 0 = no, 1 = yes.

  Example: 
  print "First column may return NULL\n" if $sth->{NULLABLE}->[0];

=item CursorName (string)      read-only

Returns the name of the cursor associated with the statement handle if
available.

=item Statement (string)       read-only

Returns the statement string passed to the the prepare entry elsewhere in
this document method.

=item RowsInCache (integer)    read-only, currently return undef.

If the driver supports a local row cache for select statements then this
attribute holds the number of un-fetched rows in the cache.  Currently
DBMaker will return undef for this value, while DBMaker will prefetch about
8K size's data into client side.

=back

=head2 Handling BLOB Fields with DBMaker

DBMaker support LONG VARCHAR, LONG VARBINARY and FILE data type
for user to store BLOB in the database.  For easier handling with
blob input/output, DBMaker support the following method for user to
store their blob file into the database or retrieve their blob data
to a user local file.

=over 4

=item Use file as input parameter to a BLOB column

Statement Attribute: dbmaker_file_input (default is 1)

a. Store file content for BLOB field

When this attribute value is 1 and user add quote for a file name as 
input parameter value, and the parameter's SQL type is SQL_LONGVARCHAR/
SQL_LONGVARBINARY/SQL_FILE, DBMaker will store the file's content into
database.

  Example:
  $dbh->do("create table blobt1 (c1 long varchar)");
  my $sql=qq{INSERT INTO blobt1 values(?)};
  my $sth = $dbh->prepare($sql);
 
  # By default, DBMaker will try to open a blob file name (for example: test.gif), 
  # read the file and then store into the database
  $sth->bind_param(1,"'test.gif'");
  $sth->execute();

  # If you want to store a blob file name (for example: test.gif) with string quote 
  # into database
  $sth->{dbmaker_file_input} = 0;
  $sth->bind_param(1,"'test.gif'");
  $sth->execute();

You can select c1 from this table and see what's the difference between these two
insert.

b. Store file name only for FILE column

When dbmaker_file_input statement attribute sets on, there are 
difference when you input file name with or without single quote for
DBMaker's SQL_FILE type.  When you do not add single quote with
the input string,  DBMaker will check if the file name is accessible
by DBMaker server, and store the file name into the database.  For
detail description for DBMaker's SQL_FILE type, please reference 
DBMaker's manual.

NOTE: In order to tell DBMaker to store file name, you should make
sure you have set DB_USRFO=1 in dmconfig.ini, and the input file name
must be full path with file name.

  Example:
  $dbh->do("create table filet1 (c1 file)");
  my $sql=qq{INSERT INTO filet1 values(?)};
  my $sth = $dbh->prepare($sql);
 
  # Test input file name with single quote
  # You can test with a file in current directory
  $sth->bind_param(1,"'test.gif'");
  $sth->execute();

  # Test input file name without single quote
  # Although test.gif is in current directory, you must specify 
  # full path with file name.
  $sth->bind_param(1,"/full_path/test.gif");
  $sth->execute();
    
  # If you want to store a data with or without single quote 
  # into database's FILE column, you should set 
  # the attribute dbmaker_file_input = 0
  $sth->{dbmaker_file_input} = 0;
  $sth->bind_param(1,"test.gif");
  $sth->execute();

  $sth->bind_param(1,"'test.gif'");
  $sth->execute();

You can select c1 or select filename(c1) from this table to see what's the difference
with these inserts.

=item Output BLOB to user's file

In DBI, you can set LongReadLen to set the buffer length for getting
your blob data.  However, BLOB field's data maybe too large to malloc
buffer for storing it, and it may be a little troublesome to call
blob_read many times.  By BindColToFile, you can redirect the
column's output to a file, and you can continue to access the blob
on the local file.  Because this function will create many files
when you try to fetch result from a table which holds many rows, you
should remember to clean up the files when you finish your program.

$sth->func($colno, $prefix_filename, $fgOverwrite, 'BindColToFile')

NOTE: set fgOverwrite 1 or 0 to specify whether your local file with same
name be overwritten or not.

  Example:
  $sql = qq{ SELECT c1 FROM blobt1};
  $sth = $dbh->prepare( $sql );
 
  $sth->func(1, "perl_outfile.txt", 1, 'BindColToFile');
 
  $sth->execute()||die "$DBI::errstr";
 
  my $c1;
 
  $sth->bind_columns( undef, \$c1);
  while( $sth->fetch() ) {  
      print "c1 = $c1\n"; 
  }

After running this program, you will notice there's many file called
perl_outfile.txt, perl_outfile1.txt,...perl_outfilen.txt in your local
directory.  You need to remember to delete these files if they are no
longer necessary.

=back

=head2 Private functions for DBMaker API access

The following catalog functions are based on the DBD::ODBC.  Please check ODBC API document
for detailed function specification.

=over 4

=item GetInfo

This function maps to the ODBC SQLGetInfo call.  This is a Level 1 ODBC
function.  An example of this is:

  $value = $dbh->func(6, 'GetInfo');

This function returns a scalar value, which can be a numeric or string value.  
This depends upon the argument passed to GetInfo. 

=item GetTypeInfo

This function maps to the ODBC SQLGetTypeInfo call.  This is a Level 1
ODBC function.  An example of this is:

  use DBI qw(:sql_types);
  use strict;

  $sth = $dbh->func(SQL_ALL_TYPES, 'GetInfo');
  while (@row = $sth->fetch_row) {
    ...
  }

This function returns a DBI statement handle, which represents a result
set containing type names which are compatible with the requested
type.  SQL_ALL_TYPES can be used for obtaining all the types the ODBC
driver supports.  NOTE: It is VERY important that the use DBI includes
the qw(:sql_types) so that values like SQL_VARCHAR are correctly
interpreted.  This "imports" the SQL type names into the program's name
space.  A very common mistake is to forget the qw(:sql_types) and
obtain strange results.

=item GetFunctions

This function maps to the ODBC API SQLGetFunctions.  This is a Level 1
API call which returns supported driver functions.  Depending upon how
this is called, it will either return a 100 element array of true/false
values or a single true false value.  If it's called with
SQL_API_ALL_FUNCTIONS (0), it will return the 100 element array.
Otherwise, pass the number referring to the function.  (See your ODBC
docs for help with this).

  Example:
  print "\nGetfunctions: ", join(",", $dbh->func(0, 'GetFunctions')), "\n\n";

=item columns

This function maps to the ODBC API SQLColumns.

  Usage:
  $dbh->($catalog, $schema, $table, $column, columns);

  Example:
  # dump all column information for table employees1 by columns
  my $sth = $dbh->func('','SYSADM', 'employees1','', 'columns');
  while (@row = $sth->fetchrow()) {
     print "\t", join(', ', @row), "\n";
  }
  $sth->finish;


=item ColAttributes

This function maps to the ODBC API SQLColAttributes. 

  Usage:
  $sth->func($colno, $desctype, 'ColAttributes'); 

  Example:
  my $colcount = $sth->func(1, 0, 'ColAttributes');
  # 1 for col (unused) 0 for SQL_COLUMN_COUNT
  print "Column count is $colcount\n";

=item GetPrimaryKeys

This function maps to the ODBC API SQLPrimaryKeys.

  Usage:
  $sth = $dbh->func($catalog, $schema, $table, 'GetPrimaryKeys');

  Example:
  $dbh->do("create table pkt1 (c1 int, c2 float,c3 char(5), primary key (c1, c2))");
  $dbh->do("create unique index ix1 on pkt1 (c1)");
  print "Check Primary Key\n";
  my $sth = $dbh->func('','SYSADM','pkt1', 'GetPrimaryKeys');
  my @row;
  while (@row = $sth->fetchrow()) {
     print "$row[0], $row[1] , $row[2] , $row[3] , $row[4] , $row[5]\n";
  }
  $sth->finish();

=item GetStatistics

This function maps to the ODBC API SQLStatistics.

  Usage:
  $sth = $dbh->func($catalog, $schema, $table, $unique, 'GetStatistics');

  Example:
  print "\nCheck Index by SQLStatistics\n";
  $sth = $dbh->func('','SYSADM','pkt1',SQL_INDEX_UNIQUE, 'GetStatistics');
  while (@row = $sth->fetchrow()) {
     foreach $i (0..12) {
        print "$row[$i] ";
     }
     print "\n";
  }
  $sth->finish();

=item GetForeignKeys

This function maps to the ODBC API SQLForeignKeys.

  Usage:
  $sth = $dbh->func($pkcatalog, $pkschema, $pktable,
                 $fkcatalog, $fkschema, $fktable, 'GetForeignKeys');

  Example:
  $dbh->do("create table fkt1 (flt float, i int, foreign key fk1(i, flt) references pkt1(c1, c2))");
  print "\nCheck Foreign Key\n";
  $sth = $dbh->func('','SYSADM','pkt1','','SYSADM','fkt1', 'GetForeignKeys');
  while (@row = $sth->fetchrow()) {
    foreach $i (0..13) {
      print "$row[$i] ";
  }
  print "\n"; 
  }
  $sth->finish();

=back

=head1 Recent Updates

=over 4

=item DBD::DBMaker 0.13

This version is based on DBD::DBMaker 0.12a, and DBD::ODBC 0.2x:

  . Add support file name in bind_param for blob column, user
    can specify 'file name' as input parameter, and DBMaker will
    store the file's content into blob column.  User can use 
    $sth->{dbmaker_file_input}= 0 to turn off this option. Default is on.

  . Add $sth->func($colno, $prefix_filename, 'BindColToFile')
    for user to specify output column to a file, the output 
    file will be named starting by $prefix_filename and the following file
    will append a sequential number starting from 1.  The existing file with
    same file name will not be overwritten.

  . Rename dbh->tables() to dbh->table_info().

  . Fix return error when fetch boundary float/double value.

  . Ignore warning return in sth->execute() will close statement
    which result in next execute fail.

  . Add warning for commit() when AutoCommit on.

  . Add support bind_param_inout.

  . Add ODBC catalog functions based on DBD-ODBC 0.20, 0.21
    SQLGetInfo,SQLGetTypeInfo,SQLColAttributes,
    SQLGetFunctions,SQLColumns,SQLStatistics,SQLPrimaryKeys,
    SQLForeignKeys.

=item DBD::DBMaker 0.07 and above: 

  . the attribute 'blob_size' triggers a 'depreciated feature' warning 
    when warnings are enabled.

=item DBD::DBMaker 0.08 and above:

  . the attribute 'dbmaker_blob_size' triggers a depreciated feature' 
    warning when warnings are enabled (because DBI 0.86+ specifies a 
    LongReadLen attribute).

=back

=head1 Relative Links

For more information on the Perl5 DBI, please visit the following related web page:

DBI web site:
http://www.symbolstone.org/technology/perl/DBI/index.html

DBMaker web site:
http://www.dbmaker.com

Microsoft ODBC:
http://www.microsoft.com/odbc

=head1 AUTHOR

DBMaker Team: dbmaker@lion.syscom.com.tw

=head1 SEE ALSO

perl(1), DBI(perldoc), DBMaker documentation

=cut

