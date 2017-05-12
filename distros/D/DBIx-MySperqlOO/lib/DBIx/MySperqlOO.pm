package DBIx::MySperqlOO;
use Class::Std;
use Class::Std::Utils;
use strict;
use warnings;
use DBI;

use version; our $VERSION = qv('1.0.1');

{
	my %dbh_of  : ATTR();
	my %sth_of  : ATTR();
	my %dbd_of  : ATTR();
	my %db_of   : ATTR();
	my %host_of : ATTR();
	my %user_of : ATTR();
	my %pass_of : ATTR();
	my %dsn_of  : ATTR();

	sub BUILD {      
		my ( $self, $ident, $arg_ref ) = @_;

		$dbd_of{$ident}  = $arg_ref->{dbd}  ? $arg_ref->{dbd}  : 'mysql'; 
		$db_of{$ident}   = $arg_ref->{db}   ? $arg_ref->{db}   : $arg_ref->{database}; 
		$host_of{$ident} = $arg_ref->{host} ? $arg_ref->{host} : 'localhost'; 
		$user_of{$ident} = $arg_ref->{user} ? $arg_ref->{user} : ''; 
		$pass_of{$ident} = $arg_ref->{pass} ? $arg_ref->{pass} : ''; 
		$dsn_of{$ident}  = $arg_ref->{dsn} ?  $self->_build_dsn() : ''; 

		$self->connect();

		return;
	}

	sub set_dbd  { my ($self, $value) = @_; $dbd_of{ident $self} = $value; $self->_build_dsn(); return $self; } 
	sub set_db   { my ($self, $value) = @_; $db_of{ident $self} = $value; $self->_build_dsn(); return $self; } 
	sub set_host { my ($self, $value) = @_; $host_of{ident $self} = $value; $self->_build_dsn(); return $self; } 
	sub set_user { my ($self, $value) = @_; $user_of{ident $self} = $value; $self->_build_dsn(); return $self; } 
	sub set_pass { my ($self, $value) = @_; $pass_of{ident $self} = $value; $self->_build_dsn(); return $self; } 
	sub set_dsn  { my ($self, $value) = @_; $dsn_of{ident $self} = $value; return $self; } 

	sub get_user { my ($self)  = @_; return $user_of{ident $self}; } 
	sub get_pass { my ($self)  = @_; return $pass_of{ident $self}; } 
	sub get_dsn  { my ($self)         = @_; my ($ident)        = ident $self; if (! $dsn_of{$ident} ) { $self->_build_dsn(); } return $dsn_of{$ident}; }

	sub _build_dsn { my ($self)       = @_; my ($ident) = ident $self; $dsn_of{$ident} = 'DBI:' . $dbd_of{$ident} . ':database=' . $db_of{$ident} . ';host=' . $host_of{$ident}; }

	sub connect {
		my ($self) = @_;
		my ($ident) = ident $self;

		# Either connect or quit with error
		$dbh_of{$ident} = DBI->connect( $self->get_dsn(), $self->get_user(), $self->get_pass() );
		
		# Emit error string if connect failed
		if ($DBI::err) { warn "ERROR: $DBI::err : $DBI::errstr [DBConnect failed]"; }
		
		return $dbh_of{$ident};
	}
	
	sub sqlexec {
		my ( $self, $sql, $type, $parameters ) = @_;
	
		$type = $type ? $type : '$sth';        
	
		# Execute the sql with the given params
		$sth_of{ident $self} = $self->_sqlexecute( $sql, $parameters );
	
		# Check for type of return
		if ($type =~ m/sth/) {
			# Return the handle
			return $sth_of{ident $self};
		} else {
			# Return the data per type
			return $self->_sqlfetch( $type );
		}
	}
	
	sub _sqlexecute {
		my ( $self, $sql, $parameters ) = @_;
		my $ident = ident($self);

		# Check parameters and prepare
		$sth_of{$ident} = $self->_sqlparse( $sql, $parameters );
	
		# Execute
		$sth_of{$ident}->execute() or return "ERROR: [database.pl:_sqlexecute]$DBI::err : $DBI::errstr [_sqlexecute failed]";
	
		# Return statement handle
		return $sth_of{ident $self};
	}
	
	sub _sqlparse {
		my ( $self, $test, $parameters) = @_;
		my $ident = ident($self); 
	
		if ($self->_is_handle($test)) {
			# Handle
			$sth_of{$ident} = $dbh_of{$ident}->prepare($test->{Statement}) or return "ERROR: Could not prepare handle [_sqlparse failed]";
		} else {
			# SQL string
			# Get database handle
			if (!($dbh_of{$ident}->{Active})) { $dbh_of{$ident} = &DBConnect; }
	
			# Prepare the statement
			$sth_of{$ident} = $dbh_of{$ident}->prepare($test) or return "ERROR: Could not prepare statement [_sqlparse failed]";
		}
	
		return $sth_of{ident $self};
	}
	
	sub _sqlfetch {
		my ( $self, $type ) = @_;
	
		if    ($type eq '\@@') { $self->_fetch_all_array_ref(); }
		elsif ($type eq '\@')  { $self->_fetch_row_array_ref(); }
		elsif ($type eq '@')   { $self->_fetch_row_array();     }
		elsif ($type eq '\%')  { $self->_fetch_row_hash_ref();  }
		else                   { return "ERROR: type($type) [_sqlfetch failed]"; }
	}
	
	sub _fetch_all_array_ref {
		my ( $self ) = @_;
		my ($ref)    = $sth_of{ident $self}->fetchall_arrayref;
		if ($DBI::err) { return "ERROR: Fetching Error($DBI::err) $DBI::errstr [_fetch_all_array_ref failed]"; }
		return $ref;
	}
	
	sub _fetch_row_array_ref {
		my ( $self ) = @_;
		my ($ref)    = $sth_of{ident $self}->fetchrow_arrayref;
		if ($DBI::err) { return "ERROR: Fetching Error($DBI::err) $DBI::errstr [_fetch_row_array_ref failed]"; }
		return $ref;
	}
	
	sub _fetch_row_array {
		my ( $self ) = @_;
		my (@array)  = $sth_of{ident $self}->fetchrow_array;
		if ($DBI::err) { return "ERROR: Fetching Error($DBI::err) $DBI::errstr [_fetch_row_array failed]"; }
		return @array;
	}
	
	sub _fetch_row_hash_ref {
		my ( $self ) = @_;
		my ($ref)    = $sth_of{ident $self}->fetchrow_hashref;
		if ($DBI::err) { return "ERROR: Fetching Error($DBI::err) $DBI::errstr [_fetch_row_hash_ref failed]"; }
		return $ref;
	}
	
	sub get_row_count {
		my $self = shift @_;
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
	
	sub get_col_count {
		my $self = shift @_; 
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
	
	sub get_field_names { my ( $self ) = @_; my $ref = $sth_of{ident $self}->{NAME}; return @$ref; }
	
	sub _is_handle { my $self = shift @_; return ($_[0] =~ m/^DBI/); }
	
}

1; # Magic true value required at end of module

__END__

=head1 NAME

MySperqlOO - OO Module to simplify DBI MySQL statements

=head1 SYNOPSIS

  use DBIx::MySperqlOO;
    
  my $mysperql = DBIx::MySperqlOO->new( $parameters );
  
  $return = $mysperql->sqlexec($sql, $type, $parms);
  @return = $mysperql->sqlexec($sql, $type, $parms);
  
  $sth = $mysperql->sqlexecute($sql, $parms);
  $sth = $mysperql->sqlparse($test, $parms);
  $ref = $mysperql->sqlfetch($sth, $type);

=head1 DESCRIPTION

MySperqlOO enables one line sql statements when using perl with DBI
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
Roger Hall (Little Rock, AR) and Eric Goldbrenner (San Francisco, CA), and 
was upgraded to Class::Std style OO in 2008 by Roger Hall and Michael Bauer. 

=head2 Methods

=over 4

=item * new() / connect()

  my $mysperql = DBIx::MySperqlOO->new({ db => $db, host => $host, user => $user, pass => $pass });

The parameters hash should include the following minimum keys for 
DBI connections: db, host, user, pass. The database must exist on the 
host, and the user must have permissions using the pass. Note that the 
hash is referenced.

The connect() method is called within new(). You should not use the connect() method 
directly. It is included in the title to help you understand what new() does.

=item * sqlexec()

  my $dataref = $mysperql->sqlexec( $sql, $type, $parms );

This is the workhorse statement, and for most applications, 
the only "sqlX" function you will use.

A typical statement might be:

  my $dataref = $mysperql->sqlexec( $sql, '\@@' );

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
       $parms  database specific parameters
 Note: Remember to single-quote the $type character
       string (because "$sth" != '$sth')!

=item * _sqlexecute()

  my $sth = $mysperql->_sqlexecute( $sql, $parms);

Handles the parsing, binding and execution of a sql 
statement.

=item * _sqlfetch()

  my $dataref = $mysperql->_sqlfetch( $sth, $type );

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

=item * _sqlparse()

  my $sth = $mysperql->_sqlparse( $test, $parms );

Encapsulates DBI prepare() function.

 Parm: $test is either a(n) sql statement with zero
       or more named parameters or an active 
       statement handle
       $parms is a hash reference with parameter names 
       as keys and parameter values as values. 
       Only the word part of the names should be 
       used as keys (ie leave off the leading ':').
 Note: 1. _sqlparse is responsible for making sure an 
       active global database handle ($dbh) exists
       2. _sqlparse prepare()s the statement to check 
       for parsing errors.

=item * get_row_count()

  my $count = $mysperql->get_row_count( $dataref );

Returns the row count of a record object.

 Parm: $dataref    a reference to a table (array of arrays)
       $count      the number of rows
 Note: Handles Scalars, Arrays, and all references.

=item * get_column_count()

  my $count = $mysperql->get_column_count( $dataref );

Returns the column count of a record object.

 Parm: $dataref    a reference to a table (array of arrays)
       $count      the number of columns
 Note: Handles Scalars, Arrays, and all references.

=item * get_field_names()

  my @fields = $mysperql->get_field_names( $sth );

Returns the names of the table columns.

 Parm: $sth    a valid dbi statement handle
       @fields the returned list of field names
 
=item * _is_handle()

  my $boolean = $mysperql->_is_handle( $test );

Tests if an object is a statement handle. Used to tell 
handles and sql strings apart.

  if ( $self->_is_handle( $test ) ) { ... }

 Parm: $test   the handle or string

=back

=head2 EXAMPLES

=over 4

=item * Top-Of-The-File Requirements

  use DBIx::MySperqlOO;
  
  my $mysperql = DBIx::MySperqlOO->new({ db   => 'mydb', 
                                         host => 'localhost', 
					 user => 'myuser', 
					 pass => 'mypass' });
  
=item * Insert a record

  # Insert record
  $mysperql->sqlexec( "insert into table(field1, field2) values ('$field1', '$field2')" );

=item * Update a record

  # Update record
  $mysperql->sqlexec( "update table set field1 = '$field1' where id = $id" );

=item * Delete a record

  # Delete record
  $mysperql->sqlexec( "delete from table where id = $id" );

=item * Select single record

  # Get record
  my $sql = "select * from table where id = $id";
  my ($id, $field1, $field2) = $mysperql->sqlexec( $sql, '@' );
  
=item * Select table with fields-on-the-fly

  # Create handle
  my $sql = "select * from table where id = $id";
  $mysperql->sqlexec( $sql, '$sth' );
  
  # Or optionally get the handle
  my $sth = $mysperql->sqlexec( $sql, '$sth' );

  # Get field names
  my @fields = $mysperql->get_field_names();

  # Get records for a saved statement handle
  my $dataref = $mysperql->sqlexec( $sth, '@' );
  
=item * Select multiple records

  # Get table
  my $sql = "select * from table";
  my $rows = $mysperql->sqlexec( $sql, '\@@' );
  foreach $row (@$rows) {
  	my ($id, $field1, $field2) = @$row;
  
  	print "($id) $field1 = $field2\n";
  }
  
=item * Using multiple MySQL connections

  # Open the first connection
  my $myperql1 = DBIx::MySperql->new( $parameters1 );

  # Make statements on db 1
  my $sql = "...
  $mysperql1->sqlexec( $sql ...);

  # Open an additional connection
  my $myperql2 = DBIx::MySperql->new( $parameters2 );

  # Make statements on db 2
  $sql = "...
  $mysperql2->sqlexec( $sql ...);

  # Make statements on db 1
  $sql = "...
  $mysperql1->sqlexec( $sql ...);

  ...

=back

=head2 EXPORT

  None.

=head1 SEE ALSO

http://www.iosea.com/mysperqloo

=head1 ABSTRACT

MySperqlOO enables one line sql statements with DBI and MySQL.

=head1 AUTHOR

Roger A Hall <roger@iosea.com>

=head1 COPYRIGHT AND LICENSE

Copyleft (C) 2007 by Roger Hall

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

=cut
