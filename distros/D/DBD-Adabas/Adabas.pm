# $Id: Adabas.pm,v 1.1 1998/08/20 11:31:14 joe Exp $
#
# Copyright (c) 1994,1995,1996,1998  Tim Bunce
# portions Copyright (c) 1997,1998   Jeff Urlwin
# portions Copyright (c) 1997  Thomas K. Wenrich
#
# You may distribute under the terms of either the GNU General Public
# License or the Artistic License, as specified in the Perl README file.

require 5.004;

$DBD::Adabas::VERSION = '0.2003';

{
    package DBD::Adabas;

    use DBI ();
    use DynaLoader ();

    @ISA = qw(DynaLoader);

    my $Revision = substr(q$Revision: 1.1 $, 10);

    require_version DBI 0.86;

    bootstrap DBD::Adabas $VERSION;

    $err = 0;		# holds error code   for DBI::err
    $errstr = "";	# holds error string for DBI::errstr
    $sqlstate = "00000";
    $drh = undef;	# holds driver handle once initialised

    sub driver{
	return $drh if $drh;
	my($class, $attr) = @_;

	$class .= "::dr";

	# not a 'my' since we use it above to prevent multiple drivers

	$drh = DBI::_new_drh($class, {
	    'Name' => 'Adabas',
	    'Version' => $VERSION,
	    'Err'    => \$DBD::Adabas::err,
	    'Errstr' => \$DBD::Adabas::errstr,
	    'State' => \$DBD::Adabas::sqlstate,
	    'Attribution' => 'Adabas DBD, based on ODBC DBD by Tim Bunce',
	    });

	$drh;
    }

    1;
}


{   package DBD::Adabas::dr; # ====== DRIVER ======
    use strict;

    sub connect {
	my $drh = shift;
	my($dbname, $user, $auth)= @_;
	$user = '' unless defined $user;
	$auth = '' unless defined $auth;

	# create a 'blank' dbh
	my $this = DBI::_new_dbh($drh, {
	    'Name' => $dbname,
	    'USER' => $user, 
	    'CURRENT_USER' => $user,
	    });

	# Call ODBC logon func in Adabas.xs file
	# and populate internal handle data.

	DBD::Adabas::db::_login($this, $dbname, $user, $auth) or return undef;

	$this;
    }
}


{   package DBD::Adabas::db; # ====== DATABASE ======
    use strict;

    sub prepare {
	my($dbh, $statement, @attribs)= @_;

	# create a 'blank' dbh
	my $sth = DBI::_new_sth($dbh, {
	    'Statement' => $statement,
	    });

	# Call Adabas OCI oparse func in Adabas.xs file.
	# (This will actually also call oopen for you.)
	# and populate internal handle data.

	DBD::Adabas::st::_prepare($sth, $statement, @attribs)
	    or return undef;

	$sth;
    }


    sub columns {
	my ($dbh, $catalog, $schema, $table, $column) = @_;

	# create a "blank" statement handle
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLColumns" });

	_columns($dbh,$sth, $catalog, $schema, $table, $column)
	    or return undef;

	$sth;
    }


    sub table_info {
	my($dbh) = @_;		# XXX add qualification

	# create a "blank" statement handle
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLTables" });

	# XXX use qualification(s) (qual, schema, etc?) here...
	DBD::Adabas::st::_tables($dbh,$sth, "")
		or return undef;
	$sth;
    }

    sub ping {
 	my $dbh = shift;
 	# should never 'work' but if it does, that's okay!
 	my $sql = "select col_does_not_exist from table_does_not_exist";
 	return 1 if $dbh->prepare($sql);
 	my $state = $dbh->state;
 	return 1 if $state eq 'S0002';	# Base table not found
 	return 1 if $state eq 'S0022';	# Column not found
 	# We assume that any other error means the database
 	# is no longer connected.
 	# Some special cases may need to be added to the code above.
 	return 0;
    }
 
 
    # Call the ODBC function SQLGetInfo
    # Args are:
    #	$dbh - the database handle
    #	$item: the requested item.  For example, pass 6 for SQL_DRIVER_NAME
    # See the ODBC documentation for more information about this call.
    #
    sub GetInfo {
 	my ($dbh, $item) = @_;
 	_GetInfo($dbh, $item);
    }

    sub GetTypeInfo {
 	my ($dbh, $sqltype) = @_;
 	# create a "blank" statement handle
 	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLGetTypeInfo" });
 	# print "SQL Type is $sqltype\n";
 	_GetTypeInfo($dbh, $sth, $sqltype) or return undef;
 	$sth;
    }

    sub quote {
        my($self, $str) = @_;
        if (!defined($str)) {
	    return 'NULL';
	}
	if ($str =~ /\0/) {
	    return "x'" . unpack("H*", $str) . "'";
	}
	$str =~ s/\'/\'\'/g;
	"'$str'";
    }

    sub type_info_all {
	my ($dbh, $sqltype) = @_;
	my $sth = DBI::_new_sth($dbh, { 'Statement' => "SQLGetTypeInfo" });
	_GetTypeInfo($dbh, $sth, $sqltype) or return undef;
	my $info = $sth->fetchall_arrayref;
	unshift @$info, {
	    map { ($sth->{NAME}->[$_] => $_) } 0..$sth->{NUM_OF_FIELDS}-1
	};
	return $info;
    }
}


{   package DBD::Adabas::st; # ====== STATEMENT ======
    use strict;

    sub ColAttributes {		# maps to SQLColAttributes
 	my ($sth, $colno, $desctype) = @_;
 	# print "before ColAttributes $colno\n";
 	my $tmp = _ColAttributes($sth, $colno, $desctype);
 	# print "After ColAttributes\n";
 	$tmp;
    }
}

1;
__END__


=head1 NAME

DBD::Adabas - Adabas Driver for DBI

=head1 SYNOPSIS

  use DBI;

  $dbh = DBI->connect('dbi:Adabas:DSN', 'user', 'password');

See L<DBI> for more information.

=head1 DESCRIPTION

=head2 Recent Updates

=item DBD::Adabas 0.21

Fixed blob handling.

=item DBD::ODBC 0.20

SQLColAttributes fixes for SQL Server and MySQL. Fixed tables method
by renaming to new table_info method. Added new tyoe_info_all method.
Improved Makefile.PL support for Adabase.

=item DBD::ODBC 0.19

Added iODBC source code to distribution.Fall-back to using iODBC header
files in some cases.

=item DBD::Adabas 0.18

Enhancements to build process. Better handling of errors in
error handling code.

=item DBD::Adabas 0.17

This release is mostly due to the good work of Jeff Urlwin.
My eternal thanks to you Jeff.

Fixed "SQLNumResultCols err" on joins and 'order by' with some
drivers (see Microsoft Knowledge Base article #Q124899).
Thanks to Paul O'Fallon for that one.

Added more (probably incomplete) support for unix Adabas in Makefile.PL

Increased default SQL_COLUMN_DISPLAY_SIZE and SQL_COLUMN_LENGTH to 2000
for drivers that don't provide a way to query them dynamically. Was 100!

When fetch reaches the end-of-data it automatically frees the internal
ODBC statement handle and marks the DBI statement handle as inactive
(thus an explicit 'finish' is *not* required).

Also:

  LongTruncOk for Oracle ODBC (where fbh->datalen < 0)
  Added tracing into SQLBindParameter (help diagnose oracle odbc bug)
  Fixed/worked around bug/result from Latest Oracle ODBC driver where in
     SQLColAttribute cbInfoValue was changed to 0 to indicate fDesc had a value
  Added work around for compiling w/ActiveState PRK (PERL_OBJECT)
  Updated tests to include date insert and type
  Added more "backup" SQL_xxx types for tests                                  
  Updated bind test to test binding select
  NOTE: bind insert fails on Paradox driver (don't know why)

Added support for: (see notes below)

  SQLGetInfo       via $dbh->func(xxx, GetInfo)
  SQLGetTypeInfo   via $dbh->func(xxx, GetTypeInfo)
  SQLDescribeCol   via $sth->func(colno, DescribeCol)
  SQLColAttributes via $sth->func(xxx, colno, ColAttributes)
  SQLGetFunctions  via $dbh->func(xxx, GetFunctions)
  SQLColumns       via $dbh->func(catalog, schema, table, column, 'columns')

Fixed $DBI::err to reflect the real ODBC error code
which is a 5 char code, not necessarily numeric.

Fixed fetches when LongTruncOk == 1.

Updated tests to pass more often (hopefully 100% <G>)

Updated tests to test long reading, inserting and the LongTruncOk attribute.

Updated tests to be less driver specific.  

They now rely upon SQLGetTypeInfo I<heavily> in order to create the tables.
The test use this function to "ask" the driver for the name of the SQL type
to correctly create long, varchar, etc types.  For example, in Oracle the
SQL_VARCHAR type is VARCHAR2, while MS Access uses TEXT for the SQL Name.  
Again, in Oracle the SQL_LONGVARCHAR is LONG, while in Access it's MEMO.
The tests currently handle this correctly (at least with Access and Oracle,
MS SQL server will be tested also).

=head2 Private functions for ODBC API access

It is anticipated that at least some of the functions currently
implemented via the C<func> interface be "moved" into a more formal,
DBI specification.  This will be when the DBI specification
supports/formalizes the meta-data to implement.  Most of these
functions are to obtain more information from the driver and the data
source.

=over 4

=item GetInfo

This function maps to the ODBC SQLGetInfo call.  This is a Level 1 ODBC
function.  An example of this is:

  $value = $dbh->func(6, GetInfo);

This function returns a scalar value, which can be a numeric or string value.  
This depends upon the argument passed to GetInfo. 

=item SQLGetTypeInfo

This function maps to the ODBC SQLGetTypeInfo call.  This is a Level 1
ODBC function.  An example of this is:

  use DBI qw(:sql_types);

  $sth = $dbh->func(SQL_ALL_TYPES, GetInfo);
  while (@row = $sth->fetch_row) {
    ...
  }

This function returns a DBI statement handle, which represents a result
set containing type names which are compatible with the requested
type.  SQL_ALL_TYPES can be used for obtaining all the types the ODBC
driver supports.  NOTE: It is VERY important that the use DBI includes
the qw(:sql_types) so that values like SQL_VARCHAR are correctly
interpreted.  This "imports" the sql type names into the program's name
space.  A very common mistake is to forget the qw(:sql_types) and
obtain strange results.

=item GetFunctions

This function maps to the ODBC API SQLGetFunctions.  This is a Level 1
API call which returns supported driver funtions.  Depending upon how
this is called, it will either return a 100 element array of true/false
values or a single true false value.  If it's called with
SQL_API_ALL_FUNCTIONS (0), it will return the 100 element array.
Otherwise, pass the number referring to the function.  (See your ODBC
docs for help with this).

=item SQLColumns

Support for this function has been added in version 0.17, however, it
couldn't be tested properly using the ODBC drivers I have.  Neither
(Oracle or Access) supported this.  I can tell you that it fails
properly, though <G>

=item Others/todo?

Level 1

    SQLColumns	
    SQLSpecialColumns
    SQLStatistics
    SQLTables (use tables()) call

Level 2

    SQLColumnPrivileges
    SQLForeignKeys
    SQLPrimaryKeys
    SQLProcedureColumns
    SQLProcedures
    SQLTablePrivileges
    SQLDataSources
    SQLDrivers
    SQLNativeSql

=back

=head2 Using DBD::Adabas with web servers under Win32. 

=over 4

=item General Commentary re web database access

This should be a DBI faq, actually, but this has somewhat of an
Win32/ODBC twist to it.

Typically, the Web server is installed as an NT service or a Windows
95/98 service.  This typically means that the web server itself does
not have the same environment and permissions the web developer does.
This situation, of course, can and does apply to Unix web servers.
Under Win32, however, the problems are usually slightly different.

=item Defining your DSN -- which type should I use?

Under Win32 take care to define your DSN as a system DSN, not as a user
DSN.  The system DSN is a "global" one, while the user is local to a
user.  Typically, as stated above, the web server is "logged in" as a
different user than the web developer.  This helps cause the situation
where someone asks why a script succeeds from the command line, but
fails when called from the web server.

=item Defining your DSN -- careful selection of the file itself is important!

For file based drivers, rather than client server drivers, the file
path is VERY important.  There are a few things to keep in mind.  This
applies to, for example, MS Access databases.

1) If the file is on an NTFS partition, check to make sure that the Web
B<service> user has permissions to access that file.

2) If the file is on a remote computer, check to make sure the Web
B<service> user has permissions to access the file.

3) If the file is on a remote computer, try using a UNC path the file,
rather than a X:\ notation.  This can be VERY important as services
don't quite get the same access permissions to the mapped drive letters
B<and>, more importantly, the drive letters themselves are GLOBAL to
the machine.  That means that if the service tries to access Z:, the Z:
it gets can depend upon the user who is logged into the machine at the
time.  (I've tested this while I was developing a service -- it's ugly
and worth avoiding at all costs).

Unfortunately, the Access ODBC driver that I have does not allow one to
specify the UNC path, only the X:\ notation.  There is at least one way
around that.  The simplest is probably to use Regedit and go to
(assuming it's a system DSN, of course)
HKEY_LOCAL_USERS\SOFTWARE\ODBC\"YOUR DSN" You will see a few settings
which are typically driver specific.  The important value to change for
the Access driver, for example, is the DBQ value.  That's actually the
file name of the Access database.

=head2 Random Links

These are in need of sorting and annotating. Some are relevant only
to ODBC developers (but I don't want to loose them).

	http://www.ids.net/~bjepson/freeODBC/index.html

	http://dataramp.com/

	http://www.openlink.co.uk

	http://www.syware.com

	http://www.microsoft.com/odbc

=cut
