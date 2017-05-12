package DBIx::MySperql;

use 5.008005;
use strict;
use warnings;
use DBI;
use vars qw($dbh);

require Exporter;

our @ISA = qw(Exporter);

our %EXPORT_TAGS = ( 'all' => [ qw(DBConnect SQLExec SQLExecute SQLParse SQLFetch GetRowCount GetColumnCount GetFieldNames IsHandle) ] );
our @EXPORT_OK   = qw(DBConnect SQLExec SQLExecute SQLParse SQLFetch GetRowCount GetColumnCount GetFieldNames IsHandle);
our @EXPORT      = qw($dbh);

our $VERSION     = '1.01';

sub DBConnect {
	my %parms = @_;

	# Database dsn
	my $dsn = "DBI:mysql:database=$parms{database};host=$parms{host}";
	
	# Either connect or quit with error
	$dbh = DBI->connect($dsn, $parms{user}, $parms{pass});
	
	# Emit error string if connect failed
	if ($DBI::err) { return "ERROR: $DBI::err : $DBI::errstr [DBConnect failed]"; }
	
	return $dbh;
}

sub SQLExec {
	my ($sql, $type, %parameters) = @_;

	$type = $type ? $type : '$sth';        

	# Execute the sql with the given params
	my $sth = &SQLExecute($sql, %parameters);

	# Check for type of return
	if ($type =~ m/sth/) {
		# Return the handle
		return $sth;
	} else {
		# Return the data per type
		return &SQLFetch($sth, $type);
	}
}

sub SQLExecute {
	# Check parameters and prepare
	my $sth = &SQLParse(@_);

	# Execute
	$sth->execute() or return "ERROR: [database.pl:SQLExecute]$DBI::err : $DBI::errstr [SQLExecute failed]";

	# Return statement handle
	return $sth;
}

sub SQLFetch {
	my ($sth, $type) = @_;

	my %return = (
		'\@@'  => \&FetchAllArrayRef,
		'\@'   => \&FetchRowArrayRef,
		'@'    => \&FetchRowArray,
		'\%'   => \&FetchRowHashRef,
	);

	if ($return{$type}) {
		return $return{$type}->($sth);
	} else {
	 	return "ERROR: type($type) [SQLFetch failed]";
	}
}

sub FetchAllArrayRef {
	my ($sth) = @_;
	my ($ref) = $sth->fetchall_arrayref;
	if ($DBI::err) { return "ERROR: Fetching Error($DBI::err) $DBI::errstr [FetchAllArrayRef failed]"; }
	return $ref;
}

sub FetchRowArrayRef {
	my ($sth) = @_;
	my ($ref) = $sth->fetchrow_arrayref;
	if ($DBI::err) { return "ERROR: Fetching Error($DBI::err) $DBI::errstr [FetchRowArrayRef failed]"; }
	return $ref;
}

sub FetchRowArray {
	my ($sth) = @_;
	my (@array) = $sth->fetchrow_array;
	if ($DBI::err) { return "ERROR: Fetching Error($DBI::err) $DBI::errstr [FetchRowArray failed]"; }
	return @array;
}

sub FetchRowHashRef {
	my ($sth) = @_;
	my ($ref) = $sth->fetchrow_hashref;
	if ($DBI::err) { return "ERROR: Fetching Error($DBI::err) $DBI::errstr [FetchRowHashRef failed]"; }
	return $ref;
}

sub SQLParse {
	my ($test, @parameters) = @_;
	my ($sth);

	if (&IsHandle($test)) {
		# = handle
		$sth = $dbh->prepare($_[0]->{Statement}) or return "ERROR: Could not prepare handle [SQLParse failed]";
	} else {
		# = string
		# Get database handle
		if (!($dbh->{Active})) { $dbh = &DBConnect; }

		#Prepare the statement
		$sth = $dbh->prepare("$_[0]") or return "ERROR: Could not prepare statement [SQLParse failed]";
	}

	return $sth;
}

sub GetRowCount {
	my $ref = $_[0];

	# Check to see if it is a non array reference 
	if (($ref =~ /SCALAR/) or ($ref =~ /HASH/)) {
		if ($ref =~ /HASH/) {
			# It is a reference to a hash
			# Return the number of keys for hash
			return keys(%$ref);
		} else {
			# It is a scalar
			# Return 1 for scalar
			return 1;
		}
	} else {
		if ($ref =~ /ARRAY/) {
			if (@{ $ref->[0] }) {
				return @$ref;
		} else {
		  return 0;
		}
		} else {
			# It is a simple array or scalar
			return 1;
		}
	}
}

sub GetColumnCount {
	my $ref = $_[0];

	# Check to see if it is a non array reference 
	if (($ref =~ /SCALAR/) or ($ref =~ /HASH/)) {
		if ($ref =~ /HASH/) {
			# It is a reference to a hash
			# Return the number of keys for hash
			return keys(%$ref);
		} else {
			# It is a scalar
			# Return 1 for scalar
			return 1;
		}
	} else {
		# Evaluates the length of the first row
		# Only non zero for actual array of arrays
		if (@{ $ref->[0] }) {
			# It is a reference to an array of arrays
			# Return the length of the first row 
			return @{ $ref->[0] };
		} else {
			# Regular arrays, array references, and 
			# scalars land here 
			# An array would have at least two elements
			# A reference or scalar would have one
			if (@_ > 1) {
				# It is an array
				# Return the length of the input array
				return @_;
			} else {
				if (@$ref) {
					# It is a reference to an array
					# Return the length of the input array
					return @$ref;
				} else {
					# It is a scalar
					# Return 1 for scalar
					return 1;
				}
			}
		}
	}
}

sub GetFieldNames {
  my $ref = $_[0]->{NAME};
  return @$ref;
}

sub IsHandle { return ($_[0] =~ m/^DBI/); }


return 1;

__END__

=head1 NAME

MySperql - Module to simplify DBI MySQL statements

=head1 SYNOPSIS

  use DBIx::MySperql qw(DBConnect SQLExec $dbh);
    
  $dbh = &DBConnect(%parameters);
  
  $return = &SQLExec($sql, $type, \%parameters);
  @return = &SQLExec($sql, $type, \%parameters);
  
  $sth = &SQLExecute($sql, %parameters);
  $sth = &SQLParse($test, %parameters);
  $ref = &SQLFetch($sth, $type);

=head1 DESCRIPTION

MySperql enables one line sql statements when using perl with DBI
and MySQL. It supports single or multiple connections to both local 
and remote databases.

Using the module requires that you understand: 
    1) how to write the SQL statments you need
    2) perl lists ('@') and references ('\')

The second concept is necessary to both understand the "$type" parameter 
and handle the results. The types are strings that represent the 
data type expected to be returned. They logically match the data 
structure returned: '@' is a one-row list, '\@' is a one row reference 
to a list, and '\@@' is a (potentially) multi-row reference. See below 
for included examples of each type.

This module was originally created as a database library in 2001 by 
Roger Hall (Little Rock, AR) and Eric Goldbrenner (San Francisco, CA). 

(Thanks again Eric! :)

=head2 FUNCTIONS

=over 4

=item * DBConnect

  $dbh = DBConnect(database => $db, host => $host, user => $user, pass => $pass);

The parameters hash should include the following minimum 
keys for DBI connections: database, host, user, pass. The database must exist on the host, and the user must have permissions using the pass. Note 
that the hash is not referenced.

The handle is both saved in the global variable $dbh and also 
returned by the function, so DBConnect may be called like 
this:

  my $dbh = DBConnect(%parameters);

or this:

  DBConnect(%parameters);

but it must be called before SQLExec().

You might use the former method to open multiple connections 
(i.e. $dbh1, $dbh2) and the latter for more simple workflows. When using 
multiple connections, remember to assign the handle you want back to 
the global $dbh variable before using SQLExec. See "Using Multiple MySQL Connections" below.


=item * SQLExec

  $ref = SQLExec($sql, $type, %parms);

This is the workhorse statement, and for most applications, 
the only "SQLX" function you will use.

A typical statement might be:

  $ref = SQLExec($sql, '\@@');

with other examples below.

 Parm: $sql    a sql statement string
       $type   a character string that determines 
               the data type of the return:
               \@@   reference to an array of arrays (all 
                     rows fetch)
               \@    reference to an array (one row fetch)
               @     an array (one row fetch)
               \%    reference to a hash with field names
                     as keys (one row fetch)
               $sth  statement handle
               other scalar value
       %parms  database level parameters
 Note: Remember to single-quote the $type character
       string (because "$sth" != '$sth')!

=item * SQLExecute

  $sth = SQLExecute($sql, %parameters);

Handles the parsing, binding and execution of a sql 
statement.

=item * SQLFetch

  $ref = SQLFetch($sth, $type);

Fetches rows based on $type specified.

 Parm: $sth    a valid dbi statement handle
       $type   a string that determines the type of return
               \@@   reference to an array of arrays (all 
                     rows fetch)
               \@    reference to an array (one row fetch)
               @     an array (one row fetch)
               \%    reference to a hash with field names
                     as keys (one row fetch)
               $sth  statement handle
               other scalar value

=item * SQLParse

  $sth = SQLParse($test, %parameters);

Encapsulates DBI prepare() function.

 Parm: $test is either a(n) sql statement with zero
       or more named parameters or an active 
       statement handle
       %parameters is a hash with parameter names 
       as keys and parameter values as values. 
       Only the word part of the names should be 
       used as keys (ie leave off the leading ':').
 Note: 1. SQLParse is responsible for making sure an 
       active global database handle ($dbh) exists
       2. SQLParse prepare()s the statement to check 
       for parsing errors.

=item * GetRowCount

  $count = GetRowCount($ref);

Returns the row count of a record object.

 Parm: $ref    a reference to a table (array of arrays)
       $count  the number of rows
 Note: Handles Scalars, Arrays, and all references.

=item * GetColumnCount

  $count = GetColumnCount($ref);

Returns the column count of a record object.

 Parm: $ref    a reference to a table (array of arrays)
       $count  the number of columns
 Note: Handles Scalars, Arrays, and all references.

=item * GetFieldNames

  @fields = GetFieldNames($sth);

Returns the names of the table columns.

 Parm: $sth    a valid dbi statement handle
       @fields the returned list of field names
 
=item * IsHandle

  $boolean = IsHandle($test);

Tests if an object is a statement handle. Used to tell 
handles and sql strings apart.

  if (&IsHandle($test)) { ... }

 Parm: $test   the handle or string

=back

=head2 EXAMPLES

=over 4

=item * Top-Of-The-File Requirements

  use DBIx::MySperql qw(DBConnect SQLExec $dbh);
  
  # Open connect
  $dbh = DBConnect(database => 'mydb', host => 'localhost', user => 'myuser', pass => 'mypass');
  
=item * Insert a record

  # Insert record
  SQLExec("insert into table(field1, field2) values ('$field1', '$field2')");

=item * Update a record

  # Update record
  SQLExec("update table set field1 = '$field1' where id = $id");

=item * Delete a record

  # Delete record
  SQLExec("delete from table where id = $id");

=item * Select single record

  # Get record
  $sql = "select * from table where id = $id";
  my ($id, $field1, $field2) = SQLExec($sql, '@');
  
=item * Select table with fields-on-the-fly

  use DBIx::MySperql qw(DBConnect SQLExec GetFieldNames);

  # Get handle
  $sql = "select * from table where id = $id";
  $sth = SQLExec($sql, '$sth');
  
  # Get field names
  @fields = GetFieldNames($sth);

  # Get records
  $ref = SQLExec($sth, '@');
  
=item * Select multiple records

  # Get table
  $sql = "select * from table";
  $rows = SQLExec($sql, '\@@');
  foreach $row (@$rows) {
  	my ($id, $field1, $field2) = @$row;
  
  	print "($id) $field1 = $field2\n";
  }
  
=item * Using multiple MySQL connections

  # Open the first connection
  $dbh = my $dbh1 = DBConnect(%parms1);

  # Make statements
  $sql = "...
  &SQLExec($sql ...);

  # Open an additional connection
  $dbh = my $dbh2 = DBConnect(%parms2);

  # Make statements
  $sql = "...
  &SQLExec($sql ...);

  # Return to previous connection
  $dbh = $dbh1;

  # Make statements
  $sql = "...
  &SQLExec($sql ...);

  ...

=back

=head2 EXPORT

  $dbh      # Database Handle

=head1 SEE ALSO

http://www.iosea.com/mysperql

=head1 AUTHOR

Roger Hall <roger@iosea.com>

=head1 COPYRIGHT AND LICENSE

Copyleft (C) 2007 by Roger Hall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
