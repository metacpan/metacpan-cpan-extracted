package DBIx::MySQLSequence;

=pod

=head1 NAME

DBIx::MySQLSequence - Proper and correct (emulated) sequence support for MySQL

=head1 SYNOPSIS
 
  # Get a handle to a new or existing sequence
  $dbh      = DBI->connect( 'dbi:mysql:db:host', 'user', 'pass' );
  $sequence = DBIx::MySQLSequence->new( $dbh, 'sequence_name' );
  
  # Does the sequence already exist?
  if ( $sequence->exists ) {
  	die "Sequence already exists";
  }
  
  # Create the sequence
  unless ( $sequence->create ) {
  	die "Failed to create sequence";
  }
  
  # Get the next value off the sequence
  $id = $sequence->nextval;
  
  # Drop the sequence
  unless ( $sequence->drop ) {
  	die "Failed to drop sequence";
  }
  
  # Remove sequence emulation support entirely
  DBIx::MySQLSequence->remove_sequence_support( $dbh );

=head1 STATUS

C<DBIx::MySQLSequence> is complete and has been used to real application, but
does not have paranoidly thorough unit testing (yet).

Please report any issues you encounter.

=head1 DESCRIPTION

The C<DBIx::MySQLSequence> package implements an emulation layer that
provides "real" sequences on MySQL. The module works by creating a
"sequence table", a single table where each record represents a single
sequence, and performing some "magic" MySQL specific SQL to ensure the
sequences will work correctly.

=head2 What is a sequence?

A sequence is a source of guarenteed unique numbers within a particular
context. These may or may not be in order, and in fact in typical database
systems they are rarely perfectly incremental. It is much more preferrable
that they are strictly unique than that they are perfectly in order. In any
case, DBIx::MySQLSequence does actually return sequence values in order,
but this will probably change once caching is implemented.

In short, this is AUTO_INCREMENT done right. Oracle, PostgreSQL and
practically all other major database support sequences. MySQL does not.

=head2 Why do I need sequences? Isn't AUTO_INCREMENT enough?

MySQL provides its own AUTO_INCREMENT extention to SQL92 to
implement incrementing values for primary keys.

However, this is not a very nice way to do them. I won't get into
the reasoning in depth here, but primarily there are huge advantages
to be had by knowing the value you are going to use BEFORE you
insert the record into the database. Additionally, if records with
the highest value for the AUTO_INCREMENT are deleted, their values
will (in some versions of MySQL) be re-used for the next record.
This is B<very very bad>.

=head2 DBIx::MySQLSequence Feature Summary

  - Sequence names are case insensitive.
  - Sequence names can be any string 1 to 32 chars in length.
  - Sequence names can include spaces and other control characters.
  - Sequence values use BIGINT fields, so the start, increment
    and current values can be any integer between 
    -9223372036854775808 and 9223372036854775807.
  - The module is safe for multiple database users or connections.
  - The module is not transaction friendly. ( See below )
  - The module is probably NOT thread safe.

=head2 Transaction Safety

Because the sequences are emulated through tables, they will have
problems with transactions, if used inside the same database connection
as your normal code. This is not normally a problem, since MySQL
databases are not historically used for transaction based database
work.

If you are using transactions in MySQL, you can and should ensure
have a seperate connection open to do additional statements outside
the scope of the task the transaction is being used for.

You should use that connection to get the sequence values.

Any C<DBIx::MySQLSequence> methods called on a handle that isn't
in an autocommit state will cause a fatal error.

It is highly recommended that if you need to do transactions, you
should consider looking at something ore robust that supports suequences
properly. Most people running up against the limits and idiosyncracies
of MySQL tend to be much more relaxed once they discover PostgreSQL.

=head2 MySQL Permissions

At the time the first sequence is created, you will need C<CREATE>
permissions in the database. After this, you will need C<INSERT>, 
C<UPDATE> and C<DELETE> on the sequence table. Should you want to remove
sequence support completely, the C<DROP> permission will also be needed.

The default name for the sequence table is contained in the variable 
C<$DBIx::MySQLSequence::MYSQL_SEQUENCE_TABLE>.

=head1 INTERFACE

The interface for C<DBIx::MySQLSequence> is very flexible, and largely
inspired by the interface to C<DBIx::OracleSequence>. It is somewhat
simpler though, as we don't need or aren't capable of everything Oracle
does.

To quickly summarise the main methods.

  exists  - Does a sequence exist
  create  - Create a sequence
  drop    - Drop a sequence
  reset   - Resets the current value to the start value
  currval - Get the current value
  nextval - Get the next value
  errstr  - Retrieve an error message should one occur
  remove_sequence_support - Removes the sequence table completely

=head2 Hybrid Interface

Most of the methods in C<DBIx::MySQLSequence> will act in a hybrid manner,
allowing you to interact with an object or directly with the class
(statically).

For example, the following two code fragments are equivalent.

  # Instantiation and Object Method
  $sequence = DBIx::MySQLSequence->new( $dbh, 'sequence_name' );
  $sequence->create( $start_value );
  
  # Static Method
  DBIx::MySQLSequence->create( $dbh, 'sequence_name', $start_value );

As demonstated here, when calling a method statically, you should prepend
a L<DBI> database handle and sequence name to the method's arguments.

Note: C<remove_sequence_support> can ONLY be called as a static method.

=head1 METHODS

=cut

use 5.005;
use strict;
use Params::Util '_ARRAY0', '_INSTANCE';
use DBI          ();

use vars qw{$VERSION $errstr $MYSQL_SEQUENCE_TABLE};
BEGIN {
	$VERSION              = '1.04';

	# Class-level error string
	$errstr               = '';

	$MYSQL_SEQUENCE_TABLE = "_sequences";
}





#####################################################################
# Constructor and Accessors

=pod

=head2 new $dbh, $name

The C<new> constructor creates a handle to a new or existing sequence. It is
passed as arguments a valid autocommit state MySQL DBI handle, and the name
of the sequence. Returns a new DBIx::MySQLSequence object, or undef on error.

=cut

sub new {
	my $class = shift;
	my $dbh   = shift or return $class->_error( "Missing database handle argument" );
	my $name  = shift or return $class->_error( "Missing sequence name argument" );

	# Check that it is a mysql database handle
	unless ( _INSTANCE($dbh, 'DBI::db') ) {
		return $class->_error( "The database handle argument is not a DBI database handle" );
	}
	unless ( $dbh->{Driver}->{Name} eq 'mysql' ) {
		return $class->_error( "The database handle argument is not a MySQL database" );
	}

	# Create the object
	my $self = bless {
		dbh  => $dbh,
		name => $name,
		}, $class;

	# Check that the database is in auto-commit mode.
	# See notes in POD below on why this module doesn't work with transactions.
	$class->_autocommit_error unless $self->dbh->{AutoCommit};

	$self;
}

=pod

=head2 dbh

The C<dbh> object method returns the L<DBI> handle of the database the object
is using.

=cut

sub dbh { $_[0]->{dbh} }

=pod

=head2 name

The C<name> object method returns the sequence name for the handle

=cut

sub name { $_[0]->{name} }





#####################################################################
# DBIx::MySQLSequence Methods

=pod

=head2 exists

Static Syntax: C<DBIx::MySQLSequence->exists( $dbh, $name );>

Examines the database to determine if a sequence exists in the database.
Returns true if the sequence exists. Returns false if the sequence does
not exists, or sequence support has not been created in the database.

=cut

sub exists {
	my $self = ref $_[0] ? shift : $_[0]->new( @_ ) or return undef;

	# Does the sequence table exist?
	my $rv = $self->_sequence_table_exists;
	return $rv unless $rv;

	# Is the sequence entry in the table
	$self->_sequence_exists;
}

=pod

=head2 create [ $start ][, $increment ]

Static Syntax: C<DBIx::MySQLSequence->create( $dbh, $name [, $start ][, $increment ] );>

Creates a sequence in the database. The create method takes optional arguments of the
value you want to sequence to start at, and the amount you want the value to increment
( or decrement ) by.

For example

C<$sequence->create( 10, 5 )>

The above would create a new sequence whose value starts at 10, and increments by 5 each
time a value is returned. If not passed, the default is a starting value of 1, and an 
increment of 1. These are the defaults typically used by databases internally.

If called as an object method, returns a true if the sequence is created, or undef if an
error occurs, or the sequence already exists.

If called as a static method, it will return a new handle to the created sequence, or undef
if an error occurs, or the sequence already exists. You can use this as a sort of alternate 
constructor.

C<my $sequence = DBIx::MySQLSequence->create( $dbh, $name, 5 );>

DBIx::MySQLSequence will work quite happily without the sequence table existing. It will be
automatically created for you the first time that you create a sequence. Please note that
this will mean that you need CREATE and INSERT permissions when you create the first sequence.

Once the first sequence is created, you will only need INSERT permissions.

DBIx::MySQLSequence will not check for permissions for you, as the MySQL process for checking
permissions is a bit too involved, so you will most likely only find out about this when
the SQL statement fails. You should check that you have CREATE permissions before you start
using the database.

=cut
	
sub create {
	my $self = ref $_[0] ? shift : $_[0]->new( @_ ) or return undef;

	# Does the sequence table exist?
	my $rv = $self->_sequence_table_exists;
	return undef unless defined $rv;
	unless ( $rv ) {
		# Create the sequence table
		$rv = $self->_create_sequence_table or return undef;
	}

	# Add the sequence to the table
	$rv = $self->_create_sequence( $_[3], $_[4] );
	$rv ? ref $self ? 1 : $self : undef;
}

=pod

=head2 drop

Static Syntax: C<DBIx::MySQLSequence->drop( $dbh, $name );>

The C<drop> method will drop a sequence from the database. It returns true on success, or undef
on error.

Please note that when the last sequence is removed, the module will NOT remove the sequence
table. This is done in case you are operating on a database, and do not have CREATE permissions.
In this situation, the module would not be able to re-create the sequence table should it need to.

To remove the sequence table completely, see the C<remove_sequence_support> method.

=cut
	
sub drop {
	my $self = ref $_[0] ? shift : $_[0]->new( @_ ) or return undef;

	# Does the sequence table exist?
	my $rv = $self->_sequence_table_exists or return undef;

	# Remove the sequence from the table
	$self->_drop_sequence;
}

=pod

=head2 reset

Static Syntax: C<DBIx::MySQLSequence->reset( $dbh, $name );>

The C<reset> method will return the sequence to the state it was in when it was originally created.
Unlike Oracle, we do not need to drop and re-create the sequence in order to do this. Returns true
on success, or undef on error.

=cut

sub reset {
	my $self = ref $_[0] ? shift : $_[0]->new( @_ ) or return undef;

	# Does the sequence exist?
	my $rv = $self->_sequence_exists;
	return undef unless defined $rv;
	return $self->_error( "Sequence '$self->{self}' does not exist" ) unless $rv;

	# Set its value to the start value
	$self->_db_void( qq{update $MYSQL_SEQUENCE_TABLE
		set sequence_value = sequence_start - sequence_increment
		where sequence_name = ?}, [ $self->{name} ] );	
}

=pod

=head2 currval

Static Syntax: C<DBIx::MySQLSequence->currval( $dbh, $name );>

The C<currval> method retrieves the current value of a sequence from the database.
The value that this returns is currently unreliable, but SHOULD match the last
value returned from the sequence. Returns the sequence value, or undef on error.

=cut

sub currval {
	my $self = ref $_[0] ? shift : $_[0]->new( @_ ) or return undef;

	# Assume the sequence table exists, as we will return an error
	# if the table doesn't exist OR if the record does not exist.
	my $rv = $self->_db_value( qq{select sequence_value
		from $MYSQL_SEQUENCE_TABLE
		where sequence_name = ?}, [ lc $self->{name} ] );
	$rv ? $$rv : undef;
}

=pod

=head2 nextval

Static Syntax: C<DBIx::MySQLSequence->nextval( $dbh, $name );>

The C<nextval> method retrieves the next value of a sequence from the database.
Returns the next value, or undef on error.

=cut

sub nextval {
	my $self = ref $_[0] ? shift : $_[0]->new( @_ ) or return undef;

	# Assume the sequence table exists, as we will return an error
	# if the table doesn't exist OR if the record does not exist.

	# Increment the sequence
	my $rv = $self->_db_void( qq{update $MYSQL_SEQUENCE_TABLE
		set sequence_value = last_insert_id(sequence_value + sequence_increment)
		where sequence_name = ?}, [ lc $self->{name} ] ) or return undef;

	# Get the next value
	my $value = $self->_db_value( "select last_insert_id()" );
	$value ? $$value : undef;
}

=pod

=head2 remove_sequence_support

The C<remove_sequence_support> method is a static only method that is used to remove
sequence support completely from a database, should you no longer need it. 
Effectively, this just deletes the sequence table. Once you have removed sequence
support, any existing sequence object will most likely throw errors should you
try to use them.

=cut

sub remove_sequence_support {
	my $class = shift;

	# Make sure we are called as a static method
	if ( ref $class ) {
		return $class->_error( "remove_sequence_support cannot be called as an object method" );
	}
	my $dbh = shift or return $class->_error( "Missing database handle argument" );

	# Cheat a little to actually become an object, so the handle
	# provisioning in _execute works
	my $self = bless \{ dbh => $dbh, name => undef }, $class;
	$self->_drop_sequence_table;
}

BEGIN {
	*removeSequenceSupport = *remove_sequence_support;
}





#####################################################################
# Support Methods

# Does the sequence table exist
sub _sequence_table_exists {
	my $self = shift;

	# Get the list of tables
	my $tables = $self->_db_list( 'show tables' );
	return undef unless defined $tables;
	return 0 unless $tables;
	foreach ( @$tables ) {
		# Found the table
		return 1 if $_ eq $MYSQL_SEQUENCE_TABLE;
	}

	0;
}

# Does a single sequence exist within the sequence table
sub _sequence_exists {
	my $self = shift;

	# Try to find the record
	my $rv = $self->_db_value( qq{select count(*) from $MYSQL_SEQUENCE_TABLE
		where sequence_name = ?}, [ lc $self->{name} ] );
	return undef unless defined $rv;
	(ref $rv && $$rv) ? 1 : 0;
}
	
# Create the sequence table
sub _create_sequence_table {
	my $self = shift;
	$self->_db_void( qq{create table $MYSQL_SEQUENCE_TABLE (
		sequence_name char(32) not null primary key,
		sequence_start bigint not null default 1,
		sequence_increment bigint not null default 1,
		sequence_value bigint not null default 1
		)} );
}

# Drop the sequence table
sub _drop_sequence_table {
	my $self = shift;
	$self->_db_void( qq{drop table $MYSQL_SEQUENCE_TABLE} );
}

# Add a single sequence to the table
sub _create_sequence {
	my $self      = shift;
	my $start     = defined $_[0] && $_[0] =~ /^-?\d+$/ ? shift : 1;
	my $increment = defined $_[0] && $_[0] =~ /^-?\d+$/ ? shift : 1;
	
	# Assume the sequence table exists
	$self->_db_void( qq{insert into $MYSQL_SEQUENCE_TABLE
		( sequence_name, sequence_start, sequence_increment, sequence_value )
		values ( ?, $start, $increment, $start - $increment )}, [ lc $self->{name} ] );
}

# Remove a single sequence from the table
sub _drop_sequence {
	my $self = shift;

	# Assume the sequence table exists
	$self->_db_void( qq{delete from $MYSQL_SEQUENCE_TABLE
		where sequence_name = ?}, [ lc $self->{name} ] );
}

# Get the entire record hash for a sequence
sub _get_sequence_details {
	my $self = shift;

	# Pull the entire record
	my $record = $self->_db_record( qq{select * FROM $MYSQL_SEQUENCE_TABLE
		where sequence_name = ?}, [ lc $self->{name} ] );
	return undef unless defined $record;
	$record or $self->_error( "Sequence '$self->{name}' does not exist" );
}





#####################################################################
# Database Methods

use constant FORMAT_VOID      => 0;
use constant FORMAT_VALUE     => 1;
use constant FORMAT_LIST      => 2;
use constant FORMAT_RECORD    => 3;

sub _db_void {
	my ($self, $sql, $arguments) = @_;
	$self->_execute( $sql, $arguments || [], FORMAT_VOID );
}

sub _db_value {
	my ($self, $sql, $arguments) = @_;
	$self->_execute( $sql, $arguments || [], FORMAT_VALUE );
}

sub _db_list {
	my ($self, $sql, $arguments) = @_;
	$self->_execute( $sql, $arguments || [], FORMAT_LIST );
}

sub _db_record {
	my ($self, $sql, $arguments) = @_;
	$self->_execute( $sql, $arguments || [], FORMAT_RECORD );
}

sub _execute {
	my $self      = shift;
	my $sql       = shift;
	my $arguments = shift;
	my $rformat   = shift;
	unless ( _ARRAY0($arguments) ) {
		return $self->_error( "Arguments list is not an array reference" );
	}
	
	# Make sure we have a connection,
	# and arn't in a transaction.
	return $self->_error( "Database connection missing" ) unless $self->{dbh};
	$self->_autocommit_error unless $self->{dbh}->{AutoCommit};

	# Create the statement handle using the sql
	my $sth = $self->{dbh}->prepare( $sql );
	return $self->_error( "SQL error during prepare: " . $self->{dbh}->errstr ) unless $sth;
	
	# Looks good. Execute the statement
	my $result = $sth->execute( @$arguments);
	unless ( $result ) {
		$self->_error( "SQL error during execute: " . $sth->errstr );
		$sth->finish;
		return undef;
	}
	
	# Format the response data
	my $data;
	if ( $rformat == FORMAT_VOID ) {
		# It worked, return true
		$data = 1;

	} elsif ( $rformat == FORMAT_VALUE ) {
		# Get a single value
		my $rv = $sth->fetch;
		$data = $rv ? \$rv->[ 0 ] : 0;
		
	} elsif ( $rformat == FORMAT_LIST ) {
		# Get a list
		my ($rv, @list) = ();
		push @list, $rv->[ 0 ] while $rv = $sth->fetch;
		$data = scalar @list ? \@list : 0;
		
	} elsif ( $rformat == FORMAT_RECORD ) {
		# Get a single hash reference
		my $rv = $sth->fetchrow_hashref( 'NAME_lc' );
		$data = $rv ? $rv : 0;
		
	} else {
		$sth->finish;
		$self->_error( "Statement executed successfully, but return format is invalid" );
	}

	# Finish and return
	$sth->finish;	
	$data;
}





#####################################################################
# Error handling

# Set an error string and return
sub _error {
	my $either = shift;
	if ( ref $either ) {
		$either->{_errstr} = shift;
	} else {
		$errstr = shift;
	}
	undef;
}

# This module will not work inside a transaction.
# This is a fatal error.
sub _autocommit_error {
	die "You cannot use DBIx::MySQLSequence inside a transaction. See the documentation for details.";
}

=pod

=head2 errstr

Static Syntax: C<DBIx::MySQLSequence->errstr;>

When an error occurs ( usually indicated by a method return value of C<undef> ),
the C<errstr> method is used to retrieve any error message that may be available.
Any error message specific to a object method will be available from that object
using.

C<$sequence->errstr;>

If you use a static method, or one of the above object method in its static form,
you should retrieve the error message from the class statically, using

C<DBIx::MySQLSequence->errstr;>

=cut

sub errstr {
	my $either = shift;
	ref $either ? $either->{_errstr} : $errstr;
}

1;

=pod

=head1 TO DO

- More testing, but then there's ALWAYS more testing to do

In Oracle, sequence values are cached server side. We can emulate this by
creating a DBIx::MySQLSequence::Cache object to do caching client side, for
when people want to get a lot of sequence values without having to go back
to the server all the time.

This would be a good thing. It would make things MUCH faster.

=head1 AUTHORS

Adam Kennedy E<lt>adamk@cpan.orgE<gt>

Patches are welcome

=head1 SEE ALSO

DBIx::OracleSequence

=head1 COPYRIGHT

Copyright 2002, 2007 Adam Kennedy.

This program is free software; you can redistribute
it and/or modify it under the same terms as Perl itself.

The full text of the license can be found in the
LICENSE file included with this module.

=cut
