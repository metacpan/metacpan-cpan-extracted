package DBIx::Broker;

#
#  DBIx::Broker
#  
#  This Perl module provides a cleaner and more manageable API
#  to use for interaction with DBI-compatible databases.  Queries,
#  updates, inserts, counts, deletions, and even arbitrary SQL
#  statements can be executed in one line of top-level code, rather
#  than the usual three or four that contain that ugly ->prepare()
#  and ->execute() clutter.  SELECT row results may be retrieved
#  either all at once (returned as an array of hash/arrayrefs,
#  unless only one column's values are desired) or incrementally (a
#  hash/arrayref at a time).  It is also possible to print debugging
#  messages (the raw SQL statements) to any valid handle.
#
#  This module is released under the GPL, which means that you are
#  not only allowed, but encouraged to modify it to suit your needs
#  and submit enhancements and modifications to the author listed
#  below.  Thank you!
#

#  Copyright (C) 2000 xomina@bitstream.net

#  This program is free software; you can redistribute it and/or
#  modify it under the terms of the GNU General Public License
#  as published by the Free Software Foundation; either version 2
#  of the License, or (at your option) any later version.

#  This program is distributed in the hope that it will be useful,
#  but WITHOUT ANY WARRANTY; without even the implied warranty of
#  MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
#  GNU General Public License for more details.

#  You should have received a copy of the GNU General Public License
#  along with this program, in a file called 'LICENSE'; if not, write
#  to
#
#  Free Software Foundation, Inc.
#  59 Temple Place - Suite 330
#  Boston, MA  02111-1307
#  USA.



use DBI;   #   ...you've got the magic!
use Carp;
use strict;

BEGIN {
    require Exporter;
    use vars qw( $VERSION @ISA );
	$VERSION     = (split ' ', q!$Revision: 1.14 $!)[1];
    @ISA          =  qw( Exporter );
}


sub new {
	my $class  =  shift;
	my ( $self );

	$self   =  { };

	if ( @_ ) {
		my ( $driver, $database, $hostname, $port, $user, $password ) = @_;
		if ( $driver eq 'mysql' ) {
			$self->{'data_source'}  =  "DBI:$driver:$database:$hostname:$port";
		}
		else {
			$self->{'data_source'}  =  "DBI:$driver:$database";
		}

		$self->{'db'}  =  DBI->connect( $self->{'data_source'},
										$user, $password );
		if ( ! $self->{'db'} ) {
			die "Could not open database $database!\n\n";
		}
		$self->{'driver'}    =  $driver;
		$self->{'database'}  =  $database;
		$self->{'hostname'}  =  $hostname;
		$self->{'port'}      =  $port;
		$self->{'user'}      =  $user;
		$self->{'password'}  =  $password;

		$self->{'force_lowercase'}  =  0;
	}

	bless( $self, $class );
}


sub clone {
	my $self  =  shift;
	my ( $class, $clone );

	if ( $class = ref($self) ) {
		$clone  =  { };
		$clone->{'db'}  =  DBI->connect( $self->{'data_source'},
										 $self->{'user'}, $self->{'password'} );
		if ( ! $clone->{'db'} ) {
			die "Could not open database $self->{'database'}!\n\n";
		}
		$clone->{'driver'}    =  $self->{'driver'};
		$clone->{'database'}  =  $self->{'database'};
		$clone->{'hostname'}  =  $self->{'hostname'};
		$clone->{'port'}      =  $self->{'port'};
		$clone->{'user'}      =  $self->{'user'};
		$clone->{'password'}  =  $self->{'password'};
	}
	else {
		#  ...and what would you be doing in here?
		die "\nYou cannot clone an object before one is created!  Use new() first.\n\n";
	}
	bless( $clone, $class );
}


sub set_db_handle {   #   for use with programs which have already connected to the db
	my $self       =  shift;

	$self->{'db'}  =  shift;
}


sub get_db_handle {
	my $self  =  shift;

	return $self->{'db'};
}


sub debug_on {        #   call it like this, e.g.:  $db->debug_on( \*STDERR );
	my $self          =  shift;
	my $debug_handle  =  shift;

	#   we check to see if it's valid before agreeing to use it
	if ( (ref($debug_handle) eq 'Fh')  ||  (ref($debug_handle) eq 'GLOB') ) {
		$self->{'debug'}         =  1;
		$self->{'debug_handle'}  =  $debug_handle;
	}
}


sub debug_off {
	my $self  =  shift;

	$self->{'debug'}  =  0;
	undef( $self->{'debug_handle'} );
}


sub force_lowercase_fields {
	my $self  =  shift;

	$self->{'force_lowercase'}  =  1;
}


sub use_db {          #   for some reason there's no built-in DBI method for this..
    my $self      =  shift;
    my $database  =  shift;

	return  if  ( $self->{'driver'} ne 'mysql' );

    $self->{'sql'}  =  "USE $database";

    print { $self->{'debug_handle'} } "$self->{'sql'}\n"  if  $self->{'debug'};

    $self->__sql_execute();

	$self->{'database'}  =  $database;
}


sub finish {
	my $self  =  shift;

	$self->{'statement'}->finish();
}


sub disconnect {
	my $self  =  shift;

	$self->{'db'}->disconnect();
}


sub is_active {
	my $self  =  shift;

	return  if  ( $self->{'driver'} ne 'mysql' );

	return $self->{'db'}->{'Active'};
}


sub select {
    my $self          =  shift;
	my $fields        =  shift;
	my $tables        =  shift;
    my $stipulations  =  shift;
    my $wants_a_hash  =  shift;
	my ( @fields, @tables );

	$self->__add_to_array( $fields, \@fields );
	$self->__add_to_array( $tables, \@tables );

    if ( ! defined($self->{'db'}) ) {
		die "There is not a valid DB handle from which to select data.\n";
    }
	
    local $"  =  ", ";
    $self->{'sql'}   =  "SELECT @fields FROM @tables ";
    $self->{'sql'}  .=  $stipulations  if  $stipulations;

    print { $self->{'debug_handle'} } "$self->{'sql'}\n"  if  $self->{'debug'};

    $self->__sql_execute( $wants_a_hash );
}


sub select_one_value {
    my $self          =  shift;
	my $field         =  shift;
    my $tables        =  shift;
    my $stipulations  =  shift;
	my ( @tables );

	$self->__add_to_array( $tables, \@tables );

    local $"  =  ', ';
    $self->{'sql'}   =  "SELECT $field FROM @tables ";
    $self->{'sql'}  .=  $stipulations  if  $stipulations;

    print { $self->{'debug_handle'} } "$self->{'sql'}\n"  if  $self->{'debug'};

    my @query_results  =  $self->__sql_execute();
    return $query_results[0]->[0];
}


sub select_one_row {
    my $self          =  shift;
	my $fields        =  shift;
    my $tables        =  shift;
    my $stipulations  =  shift;
    my $wants_a_hash  =  shift;
	my ( @fields, @tables );

	$self->__add_to_array( $fields, \@fields );
	$self->__add_to_array( $tables, \@tables );

    local $"  =  ", ";
    $self->{'sql'}   =  "SELECT @fields FROM @tables ";
    $self->{'sql'}  .=  $stipulations  if  $stipulations;

    print { $self->{'debug_handle'} } "$self->{'sql'}\n"  if  $self->{'debug'};

    my @query_results  =  $self->__sql_execute( $wants_a_hash );
    return $query_results[0];
}


sub select_one_column {
    my $self          =  shift;
	my $field         =  shift;
	my $tables        =  shift;
    my $stipulations  =  shift;
	my ( @tables );

	$self->__add_to_array( $tables, \@tables );

    local $"  =  ", ";
    $self->{'sql'}   =  "SELECT $field FROM @tables ";
    $self->{'sql'}  .=  $stipulations  if  $stipulations;

    print { $self->{'debug_handle'} } "$self->{'sql'}\n"  if  $self->{'debug'};

    my @query_results  =  $self->__sql_execute( 1 );   #  TODO:  find out why this didn't work with arrayrefs!!
	my ( $result_data, @array_of_scalars );
	$field  =~  s/^\s*distinct\s+(\S+)/$1/i;
	$field  =~  s/.*\.(.*)/$1/;
	foreach $result_data ( @query_results ) {
		push( @array_of_scalars, $result_data->{$field} );
	}
    return @array_of_scalars;	
}


sub select_all {
    my $self          =  shift;
	my $tables        =  shift;
    my $stipulations  =  shift;
    my $wants_a_hash  =  shift;
	my ( @tables );

	$self->__add_to_array( $tables, \@tables );

    $self->select( [ "*" ], \@tables, $stipulations, $wants_a_hash );
}


sub select_incrementally {
    my $self          =  shift;
	my $fields        =  shift;
	my $tables        =  shift;
    my $stipulations  =  shift;
	my ( @fields, @tables );

	$self->__add_to_array( $fields, \@fields );
	$self->__add_to_array( $tables, \@tables );

    if ( ! defined($self->{'db'}) ) {
		die "There is not a valid DB handle from which to select data.\n";
    }

    local $"  =  ", ";
    $self->{'sql'}   =  "SELECT @fields FROM @tables ";
    $self->{'sql'}  .=  $stipulations  if  $stipulations;

    print { $self->{'debug_handle'} } "$self->{'sql'}\n"  if  $self->{'debug'};

    $self->{'statement'}  =  $self->{'db'}->prepare( $self->{'sql'} );
    if  ( ! defined $self->{'statement'} ) {
		die "Cannot prepare statement (error ".$self->{'db'}->err."): ".$self->{'db'}->errstr."\n";
    }    
    $self->{'statement'}->execute();
    #   we now leave the $self->{'statement'} object "hanging open" for use by &get_next_row()
}


sub select_all_incrementally {
    my $self          =  shift;
	my $tables        =  shift;
    my $stipulations  =  shift;
	my ( @tables );

	$self->__add_to_array( $tables, \@tables );

    $self->select_incrementally( [ "*" ], \@tables, $stipulations );
}


sub get_next_row {
    my $self          =  shift;
    my $wants_a_hash  =  shift;
	
    if ( ! defined($self->{'db'}) ) {
		die "There is not a valid DB handle from which to select another row of results.\n";
	}
	
    if ( $wants_a_hash ) {
		return $self->{'statement'}->fetchrow_hashref();
    }
	else {
		return $self->{'statement'}->fetchrow_arrayref();
    }   #   i personally have no use for fetchrow[_array]... ( does anybody? )
}


sub rows {
	my $self  =  shift;

	if ( $self->{'statement'} ) {
		return $self->{'statement'}->rows();
	}
	else {
		return 0;
	}
}


sub count {
    my $self          =  shift;
    my $tables        =  shift;
    my $stipulations  =  shift;
	my ( @tables );

	$self->__add_to_array( $tables, \@tables );

    if ( ! defined($self->{'db'}) ) {
		die "There is not a valid DB handle from which to select a count.\n";
	}

    local $"  =  ", ";
    $self->{'sql'}  =  "SELECT COUNT(*) FROM @tables $stipulations";

    print { $self->{'debug_handle'} } "$self->{'sql'}\n"  if  $self->{'debug'};

    my @query_results  =  $self->__sql_execute();
    return $query_results[0]->[0];
}


sub insert {
    my $self            =  shift;
    my $table           =  shift;                #   send only one table
    my %new_data        =  %{ shift @_ };
    my @fields          =  keys( %new_data );       #   these are promised to be in the same order,
    my @values          =  values( %new_data );     #   according to the docs
	my @question_marks  =  ( "?" ) x @values;
	
    if ( ! defined($self->{'db'}) ) {
		die "There is not a valid DB handle into which to insert data.\n\n";
    }
	
    local $"  =  ", ";
    $self->{'sql'} = "INSERT INTO $table ( @fields ) VALUES ( @question_marks )";

    print { $self->{'debug_handle'} } "sql: $self->{'sql'}\nvalues: @values\n"  if  $self->{'debug'};

    $self->__sql_execute( \@values );
	return $self->{'statement'}->{'mysql_insertid'}  if  ( $self->{'driver'} eq 'mysql' );
}


sub update {
    my $self            =  shift;
    my $table           =  shift;                #   send only one table
    my %new_data        =  %{ shift @_ };
    my $stipulations    =  shift;
    my @fields          =  keys( %new_data );       #   these are promised to be in the same order,
    my @values          =  values( %new_data );     #   according to the docs
	
    if ( ! defined($self->{'db'}) ) {
		die "There is not a valid DB handle to update.\n";
    }
	
    $self->{'sql'} = "UPDATE $table SET ";
    foreach ( @fields ) {
		$self->{'sql'}  .=  "$_ = ?, ";
    }
    $self->{'sql'}   =~  s/\,\s$/ /;                           #   chop off the last comma
    $self->{'sql'}  .=   $stipulations  if  $stipulations;
	
    print { $self->{'debug_handle'} } "sql: $self->{'sql'}\nvalues: @values\n"  if  $self->{'debug'};

    $self->__sql_execute( \@values );
}


sub delete {
    my $self          =  shift;
    my $table         =  shift;
    my $stipulations  =  shift;
	
    if ( ! defined($self->{'db'}) ) {
		die "There is not a valid DB handle from which to delete data.\n";
	}

    $self->{'sql'}  =  "DELETE FROM $table $stipulations";

    print { $self->{'debug_handle'} } "$self->{'sql'}\n"  if  $self->{'debug'};
	
    $self->__sql_execute();
}


sub delete_all {
    my $self   =  shift;
    my $table  =  shift;
	
    if ( ! defined($self->{'db'}) ) {
		die "There is not a valid DB handle from which to delete data.\n";
    }
	
    $self->{'sql'}  =  "DELETE FROM $table";
    print { $self->{'debug_handle'} } "$self->{'sql'}\n"  if  $self->{'debug'};
	
    $self->__sql_execute();
}


sub get_table_schema {
	my $self   =  shift;
	my $table  =  shift;

	$self->{'sql'}  =  "SHOW COLUMNS FROM $table";

    print { $self->{'debug_handle'} } "$self->{'sql'}\n"  if  $self->{'debug'};

    $self->{'statement'}  =  $self->{'db'}->prepare( $self->{'sql'} );
    if ( ! defined $self->{'statement'} ) {
		die "Cannot prepare statement (error ".$self->{'db'}->err."): ".$self->{'db'}->errstr."\n";
    }
    $self->{'statement'}->execute();

	my ( %table_schema, $column_info, $field_name );
	while ( $column_info = $self->{'statement'}->fetchrow_hashref() ) {
		$field_name  =  delete( $column_info->{'Field'} );
		$table_schema{$field_name}  =  $column_info;
	}
	return %table_schema;
}


sub get_primary_key {
	my $self   =  shift;
	my $table  =  shift;

	my @keys;
	my %table_schema  =  $self->get_table_schema( $table );

	foreach ( keys(%table_schema) ) {
		push( @keys, $_ )  if  ( $table_schema{$_}->{'Key'} =~ /pri/i );
	}
	return wantarray ? @keys : $keys[0];
}


sub get_auto_increments {
	my $self   =  shift;
	my $table  =  shift;
	my ( %table_schema, @auto_increments );

	%table_schema  =  $self->get_table_schema( $table );
	foreach ( keys(%table_schema) ) {
		if ( $table_schema{$_}->{'Extra'} =~ /auto_increment/i ) {
			push( @auto_increments, $_ );
		}
	}
	return @auto_increments;
}


#  this is merely a convenience wrapper method..
sub func {
	my $self  =  shift;

	#  the last parameter is the function name ( e.g., '_ListTables' )
	my $func_name  =  pop @_;

	#  anything else is the initial argument list
	my @func_arguments  =  @_;

	$self->{'db'}->func( @func_arguments, $func_name );
}


sub execute_sql {
	my $self          =  shift;
	$self->{'sql'}    =  shift;
    my $wants_a_hash  =  shift;

    print { $self->{'debug_handle'} } "$self->{'sql'}\n"  if  $self->{'debug'};

    $self->__sql_execute( $wants_a_hash );
	return $self->{'statement'}->{'mysql_insertid'}  if  ( $self->{'driver'} eq 'mysql' );
}


sub __sql_execute {
    my $self  =  shift;
	my ( @values, $wants_a_hash );
	
	if ( @_ eq 2 ) {
		@values        =  @{ shift @_ };   #   the @values fill in the ?s
		$wants_a_hash  =  shift @_;
	}
	else {
		if ( ref($_[0]) eq 'ARRAY' ) {
			@values        =  @{ shift @_ };
		}
		else {
			$wants_a_hash  =  shift @_;
		}
	}
	
    $self->{'statement'}  =  $self->{'db'}->prepare( $self->{'sql'} );
    if ( ! defined $self->{'statement'}  ||  $DBI::err ) {
		die "Cannot prepare statement (error ".$self->{'db'}->err."): ".$self->{'db'}->errstr."\n";
    }
	
	$self->{'statement'}->execute( @values );   #   ignores @values if undefined  ( right? )
	
	if ( $DBI::err ) {
		die "Cannot execute statement (error ".$self->{'db'}->err."): ".$self->{'db'}->errstr."\n";
	}

    my @results;
	
    #   the following if() strikes me as really stupid, as i must avoid the block
    #   so that the fetchrow calls do not error for non-SELECT statements...
    #   best to me would be for fetchrow to quietly do nothing if there are
    #   no rows... but hey.
	
    if ( $self->{'statement'}->{'NUM_OF_FIELDS'} ) {
		if ( $wants_a_hash ) {
			my $hash_ref;
			while ( $hash_ref  =  $self->{'statement'}->fetchrow_hashref() ) {
				if ( $self->{'force_lowercase'} ) {
					my %lc_hash;
					@lc_hash{ map { lc($_) } keys(%{$hash_ref}) }  =  values(%{$hash_ref});
					$hash_ref  =  \%lc_hash;
				}
				push @results, $hash_ref;
			}
		} else {
			my $array_ref;
			while ( $array_ref  =  $self->{'statement'}->fetchrow_arrayref() ) {
				push @results, $array_ref;
			}
		}
    }
    return @results;
}


sub __add_to_array {
	my $self          =  shift;
	my $array_or_not  =  shift;
	my $target_array  =  shift;

	if ( ref($array_or_not) eq 'ARRAY' ) {
		push( @{$target_array}, @{$array_or_not} );
	}
	else {
		push( @{$target_array}, $array_or_not );
	}
}


1;

__END__


=head1 NAME

DBIx::Broker - a little layer somewhere between top-level code and raw DBI calls

=head1 SYNOPSIS

  use DBIx::Broker;

  $db  =  DBIx::Broker->new( $DBI_driver, $database, $hostname, $port, $user, $password );

  $db  =  DBIx::Broker->new( );

  $db->is_active( );

  $db->set_db_handle( $classic_dbi_handle );
  $classic_dbi_handle  =  $db->get_db_handle( );

  $another_db_obj  =  $db->clone();

  $db->debug_on( \*DEBUG_OUTPUT_HANDLE );
  $db->debug_off( );

  @query_results  =  $db->select( \@desired_fields, \@desired_tables, $stipulations, $hash_or_not );
  @query_results  =  $db->select( \@desired_fields, $desired_table, $stipulations, $hash_or_not );
  [..etc..]

  @query_results  =  $db->select_all( \@desired_tables, $stipulations, $hash_or_not );

  $db->select_incrementally( \@desired_fields, \@desired_tables, $stipulations );
  $db->select_all_incrementally( \@desired_tables, $stipulations );

  $next_row_ref  =  $db->get_next_row( $hash_or_not );

  $number_of_rows  =  $db->count( $desired_table, $stipulations );

  $a_single_value  =  $db->select_one_value( $desired_field, $desired_table, $stipulations );

  @scalar_query_results  =  $db->select_one_column( $desired_field, \@desired_tables, $stipulations );

  $single_row_ref  =  $db->select_one_row( \@desired_fields, \@desired_tables, $stipulations, $hash_or_not );

  $db->delete( $desired_table, $stipulations );
  $db->delete_all( $desired_table );

  $db->insert( $desired_table, \%new_data );
  $insert_id  =  $db->insert( $desired_table, \%new_data );  # MySQL only!!
  $db->update( $desired_table, \%new_data, $stipulations );

  $db->use_db( "another_database" );

  $db->execute_sql( $some_raw_sql );

  %table_schema  =  $db->get_table_schema( $table );

  $primary_key   =  $db->get_primary_key( $table );

  @auto_increment_fields  =  $db->get_auto_increments( $table );

  #  Oracle users may find this one handy..
  $db->force_lowercase_fields( );

  #  this is just a wrapper around the corresponding DBI function
  $db->func( @func_arguments, $func_name );

  $db->disconnect( );

  $db->finish( );

=head1 DESCRIPTION

  DBIx::Broker does what it says, it breaks databases (using DBI!).
Or else you can use it to unclutter your code of its annoying
and ugly ->execute()s and ->prepare()s and the like.  It will 
work using any Perl DBI driver (via ->new()) or database handle
(via ->set_db_handle()).  The most common usage is to store the
query results in an array of references, each corresponding to
a row of results.  You may retrieve the results as array refs or
hash refs, depending upon whether you supplied 0 or 1,
respectively, as the $hash_or_not parameter.  For almost all
operations, you are able to supply the desired fields and
relevant tables either as a scalar (if there is just one value)
or as an array reference. i.e., you can say

  $db->select( 'login', 'mail_accounts', 'WHERE status > 0', 1 )

  or else set up something more complicated with field and table
arrays, like

  @desired_fields  =  ( "c.firstName", "c.lastName", "c.customerID", "m.login" );
  @desired_tables  =  ( "customers c", "mail_accounts m" );
  $stipulations    =  'WHERE m.status > 0 AND m.assoc_customerID = c.customerID';
  @query_results   =  $db->select( \@desired_fields, \@desired_tables, $stipulations, 1 );


  For inserting and updating rows, you send a hashref whose keys are
the table field names and whose values are the new entries.  You may
also retrieve the insert ID for a new row upon $db->insert(); however,
this feature is currently only available with MySQL databases.

  The *_incrementally() routines retrieve the same results as their
counterparts, but rather than returning all rows at once in an
array, the statement handle is left hanging and rows may be
retrieved one at a time, like

  $next_row_ref  =  $db->get_next_row( $hash_or_not ).

  It is recommended that you almost always use C<$hash_or_not = 1>,
for calling-level code readability, as well as extensibility.
Array references are supported only to avoid the inevitable
complaints that they are not supported.

  The most common usage of $db->debug_on( ) is to send it \*STDERR
or \*STDOUT, but you can always have some fun and use a file
handle or a named pipe or something.  While debugging is on, all
SQL statements are printed to the debugging output handle for
examination.  This can be very handy.

  Most of the time you\'ll be using this module something like

  @customers  =  $db->select_all( 'customers', "WHERE age < 30", 1 );
  foreach my $customer ( @customers ) {
      print "Customer $customer->{'customerID'}: ";
      print "$customer->{'last_name'}, $customer->{'first_name'}";
  }


  And if none of the existing functions are adequate, you can send
a raw SQL statement if you\'d like, by using

  $db->execute_sql( "SELCET name FORM mailbox_tabel WHEER login = 'binkler'" );

  You may retrieve table schema information in the form of a
hashtable, whose keys are the field names and whose values are
hashrefs to the various characteristics of each field, such as
'Type', 'Key', etc.  For convenience, the ->get_primary_key()
and ->get_auto_increments() methods have also been added.

=head1 AUTHOR

  xomina@bitstream.net

=head1 SEE ALSO


perl(1), DBI(3).

=cut
