# BingoX::Carbon
# -----------------
# $Revision: 2.36 $
# $Date: 2001/12/20 19:22:38 $
# ---------------------------------------------------------

=head1 NAME

BingoX::Carbon - An object oriented database abstraction superclass

=head1 SYNOPSIS

use BingoX::Carbon ( [ ':cache_all', ] [ ':no_dynmeth' ] );

  # $BR - Blessed Reference
  # $SV - Scalar Value
  # @AV - Array Value
  # $HR - Hash Ref
  # $AR - Array Ref
  # $SR - Stream Ref

  # $proto - BingoX::Carbon object OR sub-class
  # $object - BingoX::Carbon object

CONSTRUCTORS

  $BR = $proto->new( $dbh, \%data );
  $BR = $proto->get( $dbh, $ID );
  $BR = $object->duplicate;

STREAM CONSTRUCTOR METHODS

  $SR = $proto->stream_obj( $dbh, \%params, [\@fields,] [\@sort] );
  $SR = $proto->stream_hash( $dbh, \%params, [\@fields,] [\@sort] );
  $SR = $proto->stream_array( $dbh, \%params, [\@fields,] [\@sort] );

LIST CONSTRUCTOR METHODS

  $AR = $proto->list_obj( $dbh, \%params, [\@fields,] [\@sort] );
  $AR = $proto->list_hash( $dbh, \%params, [\@fields,] [\@sort] );
  $AR = $proto->list_array( $dbh, \%params, [\@fields,] [\@sort] );

RELATION METHODS

  $SV = $object->relate( $fobject | \@fobjects | (\@fids, $fclass, $fcolumn) );
  $SV = $object->unrelate( $fobject | \@fobjects | (\@fids, $fclass, $fcolumn) );
  $SV = $object->isrelated( $fobject );
  $AR = $object->list_related( $fclass [, \@fields] [, \@sort] );
  $SR = $object->stream_related( $fclass [, \@fields] [, \@sort] );
  $SV = $proto->unrelate_all( $fclass )

DATABASE MANIUPLATION METHODS

  $BR = $object->modify( \%new_data );
  $SV = $proto->modify( $dbh, \%params, \%new_data );
  $SV = $object->rm;
  $SV = $proto->rm( $dbh, \%params );

CLASS DATA ACCESSOR METHODS

  $SV = $proto->table( $dbh );
  $SV = $proto->identity( $dbh );
  $AR = $proto->primary_keys( $dbh );
  $HR = $proto->def_fields( $dbh );
  $AR = $proto->field_order( $dbh );
  $SV = $proto->identity( $dbh );
  $SV = $proto->sequence( $dbh );
  $SV = $proto->seqcol( $dbh );

DATABASE/SQL METHODS

  $SR = $proto->sql_select( $dbh );
  @AV = $proto->format_select( $dbh, \%params, \@fields, \@sort [,$alias] );
  @AV = $proto->format_conditions( $dbh, \%params [,$alias] );

=head1 REQUIRES

DBI, Carp, strict, Date::Parse, BingoX::Time

=head1 EXPORTS

Nothing

=head1 DESCRIPTION

BingoX::Carbon provides a database abstraction in which each row of data is represented
by an object blessed into a class representing the table.  Each Carbon Class represents
a table or view in the database.  The database and classes are described by variables
in said classes.  After Carbon classes have been set up to represent tables in a
database, creating, retrieving and modifying data is simply a matter of method calls
against Carbon objects and classes.  For a tutorial on setting up a Carbon project,
see L<carbontut> packaged with BingoX.

=head1 DATABASE SUPPORT

Currently, Carbon has been tested and is known to work with B<Sybase>, B<Oracle>, and
B<PostgreSQL>.  Carbon should with minimal change be able to support many other databases.

Due to Carbon's extensive use of transactions, it will not currently work with database engines that
do not support transactions - most notably MySQL.  

We tried to keep Carbon/BingoX as database agnostic as possible, but had to put some database specific
code to support such things as Sybase's Indentity columns, Oracles Sequences, the different date formats,
and Oracles use of all caps.

If you would like to help Carbon support MySQL or other database engines, feel free to send patches
or contact us for help.

=head1 CLASS VARIABLES

=head2 REQUIRED

Classes that inherit from BingoX::Carbon must have the following class variables:

=over 4

=item * $table

A scalar that contains the table name the class represents.

=item * @primary_keys

An array containing the primary key colulmn names.

=item * @field_order

An array containing all the table's column names in perferred order of use.  
Was formerly  used for order of display, but has since been replaced by the 
BingoX Display namespace modules.

=back

=head2 OPTIONAL

=over 4

=item * $identity

A scalar that contains the name of the column which is a Sybase IDENTITY column.  
There can be only one identity column per table.

=item * $seqcol

A scalar that contains the name of the column which should be populated by a sequence.

=item * $sequence

A scalar that contains the name of the sequence object in the database which new() 
will poll to determine what to populate $seqcol with.

=item * %relations

A hash containing relational data. The keys to the hash are class names of 
foreign objects. The values are class names that represents the referential class 
for any object blessed in the class of the key.

e.g. :

  %relations = ( ClassOne => 'ClassOne_ClassTwo' );

=item * %foreign_keys

A hash containing relational data present in referential classes.  The keys to the hash 
are class names representing the classes referred to.  The values are the names of the 
columns which contain the foreign key to the referred table.

e.g. :

 %foreign_keys = ( ClassOne => 'one', ClassTwo => 'two' );

=item * $title_field

The column which should be used to display the object in a list.

=item * %content_fields

This hash lets Carbon classes have virtual columns to hold large amounts of 
content data. The keys of this hash are virtual colum names whose values 
are Carbon classnames that handle those content columns.

e.g. :

 %content_fields = ( content	=> 'Class::Data::Content' );

=item * %date_fields

The keys of this hash are column names from the fieldorder array that have a 
database type of date.  Putting those columns in here make sure that you will 
get Unix time when asking for those columns.

e.g. :

 %date_fields = ( showdate	=> 1 );

=back

=head1 METHODS

=head2 CONSTRUCTORS AND STATIC METHODS

=over 4

=cut

package BingoX::Carbon;

use DBI;
use Carp qw(:DEFAULT cluck);
use strict;
use Date::Parse;
use BingoX::Time;
use vars qw($AUTOLOAD $debug);

BEGIN {
	$BingoX::Carbon::REVISION	= (qw$Revision: 2.36 $)[-1];
	$BingoX::Carbon::VERSION	= '1.92';

	$debug	= undef;

	if ($debug) {
		require Data::Dumper;
	}
}

=item C<import> (  )

Called from 'use BingoX::Carbon;'

Possible arguments are as follows:

=back

=over 4

=item * :cache_all

flag will put all data into the object at time of construction.  
The default action is to store only primary_keys in the object 
until data is needed, but this approach proved very inefficient 
in certain situations.

=item * :no_dynmeth

flag will stop the creation of methods in calling class for all 
the elements of the class' fieldorder.

=item * :full_dynmeth

flag will avoid using 'forwarder' methods and instead use full 
dynamic methods - each with it's own code resembling AUTOLOAD.  
By default, forwarder methods are used and all call 
_old_school_autoload

Any other element, not starting with the ':' character will be interpreted 
as a method name with which to create an access method in the calling class.

=back

=cut
sub import {
	my $self	= shift;
	my $myclass	= ref($self) || $self;
	my $class	= (caller)[0];
	my @args	= @_;
	warn "BingoX::Carbon: import: class=$class: @args myclass=$myclass" if ($debug);

	## Initialize special content and date field methods
	no strict 'refs';
	@{"${class}::ISA"}	= ( __PACKAGE__ ) unless ($class->isa( __PACKAGE__ ));
	BingoX::Carbon::_content_meth_init( $class );
	BingoX::Carbon::_date_meth_init( $class );

	my $no_dynmeth		= 0;
	my $full_dynmeth	= 0;
	## BingoX::Carbon methods are called as functions, passing $class (caller[0]).		##
	## This is needed because import is called before the $class @ISA is set.			##
	## Therefore, calling $class->method wouldn't work because $class doesn't inherit	##
	## from anything yet!																##
	my @fields	= ( );
	foreach (@args) {
		if (substr($_, 0, 1) eq ':') {
			if ($_ eq ':cache_all') {
				$BingoX::Carbon::cache_all{ $class }++;
			} elsif ($_ eq ':full_dynmeth') {
				$full_dynmeth	= 1;
			} elsif ($_ eq ':no_dynmeth') {
				$no_dynmeth		= 1;
				&BingoX::Carbon::_create_access_method( $class, 'AUTOLOAD' );
			}
		} else {
			warn "explicitly creating method $_ in class $class" if ($debug);
#			&BingoX::Carbon::_create_access_method( $class, $_ );
#			&BingoX::Carbon::_create_forwarder_method( $class, $_ );
			push(@fields, $_);

		}
	} # END foreach block

	push(@fields, @{ &BingoX::Carbon::fieldorder( $class ) || [] }) unless ($no_dynmeth);
	foreach my $name (@fields) {
		if ($full_dynmeth) {
			&BingoX::Carbon::_create_access_method( $class, $name );
		} else {
			&BingoX::Carbon::_create_forwarder_method( $class, $name );
		}
	}
} # END sub import


=over 4

=item C<new> ( [ $dbh, ] \%data )

Constructs a new object with the data in the hashref passed to it.  
You must supply a value for all primary key columns, unless the database 
provides a method for autogenerating this value.  If an ID isn't specified 
the ID will be the next number in the database sequence :

Sybase

Class data $identity contains name of column which is a Sybase IDENTITY.  
The IDENTITY field will be omitted from the insert statement so Sybase can autogenerate it. 
New will then select @@identity to retreive the result of triggering IDENTITY.  
Because it does this within a single statement, it will get the correct value.  

Oracle, Postgres

Class data $sequence contains name of Sequence object in database, and 
class data $seqcol contains name of column where BingoX::Carbon will insert the value 
returned by triggering $sequence.

=cut
sub new {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	ref($dbh) || return $self->error_handler("In ${class}::new() called without dbh object");
	my $data	= shift;
	ref($data) || return $self->error_handler("In ${class}::new() called without data hash");
	my ($sth, @insert_fields, @insert_values);		# used to hold data for INSERT
	$self		= { };								# initialize self

	## Get data out of data hash which should go in a content table. ##
	my %content;
	if (my $contentfields = $class->contentfields) {
		foreach (keys %$contentfields) {
			$content{$_} = delete $data->{$_};
		}
	}

	## Get data out of data hash which are date fields. ##
	if (my $datefields = $class->datefields) {
		foreach (keys %$datefields) {
			$data->{$_} = $data->{$_}->time2str( $class->date_format ) if (ref $data->{$_});
			warn "datefield $_ ==> " . $data->{$_} . "\n" if ($debug > 1);
		}
	}

	## Get data out of data hash which is for a related class. ##
	my %selected;
	if ($class->relations) {
		warn "In class->relations == \n" . Data::Dumper::Dumper( $data ) if ($debug > 1);
		foreach (keys %{ $class->relations }) {
			warn "relations $_ ==> [$_]\n" if ($debug > 1);
			$selected{$_} = { map{ $_ => 1 } @{ delete $data->{$_} } } if ($data->{$_});
		}
	}

	## prepare data to be inserted and build object ##
	foreach (keys %$data) {
		## make sure field exists in class deffields ##
		next if (/^_/);
		exists($class->deffields->{$_}) || return $class->error_handler("In ${class}::new : $_ doesn't exist in deffields [$class]\n");
		my $value	= $self->{$_} = $data->{$_};
		push(@insert_fields, (defined $value ? $_ : ( )));
		push(@insert_values, (defined $value ? $value : ( )));
	}

	local $dbh->{'AutoCommit'} = 0 if (%selected || %content);		# BEGIN TRANSACTION (if needed)
	eval {
		local $dbh->{'RaiseError'} = 1;
		## If ID not specified, get next ID from sequence ##
		foreach (@{ $class->primary_keys || [ ] }) {
			warn "Primary Key: $_... " if ($debug);
			next if ((defined $self->{$_}) || ($class->identity eq $_));
			my $sql;
			if (($class->seqcol eq $_) && defined(my $sequence = $class->sequence)) {
				## get the ID from the database sequence ##
				if ($dbh->{'Driver'}->{'Name'} eq 'Oracle') {
					$sql = 'SELECT ' . $sequence . '.nextval FROM DUAL';
				} elsif ($dbh->{'Driver'}->{'Name'} eq 'Pg') {
					$sql = "SELECT nextval('" . $sequence . "')";
				} else {
					die "don't know how to read sequences for database driver $dbh->{'Driver'}->{'Name'}\n";
				}
			} else {
				die "no data supplied for primary key $_\n";
			}
			$sth = $dbh->prepare( $sql )	|| croak "prepare\n$sql;\n" . $dbh->errstr . "\n\n";
			$sth->execute					|| croak "execute\n$sql;\n" . $sth->errstr . "\n\n";
			$self->{$_} = $sth->fetch->[0]	|| croak "fetch\n$sql;\n" . $sth->errstr . "\n\n";
			$sth->finish();
			push(@insert_fields, $_);
			push(@insert_values, $self->{$_});
		}

		## make INSERT statement ##
		my $INSERT = "INSERT INTO " . $class->table;
		$INSERT .= ' (' . join(',', @insert_fields). ')' if (@insert_fields); 
		$INSERT .= ' VALUES (' . join(',', ('?') x scalar(@insert_values)) . ')';
		$INSERT .= ' SELECT @@identity' if (($dbh->{'Driver'}->{'Name'} eq 'Sybase') && $class->identity && !defined($self->{$class->identity}));	# SYBASE IDENTITY support
		warn "$class->new:\t\t\t\"$INSERT\" [ @insert_values ]\n" if ($debug);

		## INSERT data or freak out! ##
		$sth = $dbh->prepare( $INSERT )	|| croak "prepare\n$INSERT;\n" . $dbh->errstr . "\n\n";
		$sth->execute( @insert_values )	|| croak "execute\n$INSERT\nwith VALUES: " . join(',', @insert_values) . "\n" . $sth->errstr . "\n\n";

		## GET SYBASE IDENTITY COLUMN VALUE ##
		if (($dbh->{'Driver'}->{'Name'} eq 'Sybase') && $class->identity && !defined($self->{$class->identity})) {
			$self->{ $class->identity } = $sth->fetch->[0];
			die "Sybase Identity failed\n" unless (defined($self->{$class->identity}));
		}
		$sth->finish;

		## bless object ##
		$self->{'_dbh'} = $dbh;
		bless $self, $class;

		## Start Relation Code ##
		if (%selected) {
			foreach my $relclass (keys %selected) {					# Itterates through classnames in $selected
				my %local_selected = %{ $selected{ $relclass } };	# puts cpkeys of $_ classname

				## Here we relate all newly related items (we also might			##
				## be related objects which are already related, but it won't mind)	##
				foreach my $cpk (keys %local_selected) {			# goes through all newly related cpkeys
					my %params;
					@params{ @{ $relclass->primary_keys } } = split($self->pkd,$cpk);
					$self->relate( $relclass->get( $dbh, \%params ) );
				}
			}
		}

		## Save content data. ##
		foreach (keys %content) {
			$self->$_( $content{$_} ) || die "Could not add content field $_";
		}
	}; # END of eval

	## Caught exception, ROLLBACK TRANSACTION ##
	if ($@) {
		$class->errors( $@ );
		$dbh->rollback if (%selected || %content);
		return $class->error_handler("In ${class}::new - $@")
	}
	warn 'in new self ==> ' . Data::Dumper::Dumper( $self ) if ($debug);
	$dbh->commit if (%selected || %content);	## No errors ## COMMIT TRANSACTION ##

	return $self;
} # END sub new

=item C<get> ( [ $dbh, ] \%params )

Constructs an object from the database using the parameters passed.  
NOTE: Passing one scalar variable as an ID to get has been deprecated!  
get will assume the parameters { $self->primary_keys->[0] => shift() } 
if a scalar is passed in place of \%params. Future version of BingoX::Carbon 
will not support this!

For instructions on the format of \%params, see L<"item_format_conditions">.

=cut
sub get {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	my $params	= shift || return undef;
	unless (ref($params) eq 'HASH') {
		$params	= { $self->primary_keys->[0] => $params };
	}

	my $code = $class->stream_obj( $dbh, $params, @_ ) || return undef;
	my $obj = $code->();
	$code->(1);			# finish
	undef $code;
	return $obj;
} # END sub get


=item C<modify> ( \%new_data )

Object method:

Modify instance data with \%new_data and sync with database.
Returns $self if success, undef if failure.

=item C<modify> ( $dbh, \%params, \%new_data )

Static method:

Modify all rows satisfied by conditions in \%params with \%new_data
Returns true if success, undef if failure.

N.B. - You CAN NOT modify non-columnar information (i.e., relationships or extra-tabular "content" fields)
for multiple rows simultaneously.

For instructions on the format of \%params, see L<"item_format_conditions">.

=cut
sub modify {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	ref($dbh) || return $class->error_handler("In ${class}::modify() called without dbh object");
	my ($data, $params);

	return undef unless ref($dbh);
	#### Object method section
	if (ref $self) {
		$data	= shift || return undef;
		return undef unless (ref($data) eq 'HASH');
		## Use values of primary keys as conditional parameters (to effect this row only) ##
		$params = { map { $_ => $self->$_() } @{ $self->primary_keys } };

	## Static method section ##
	} else {
		$params = shift;
		$data   = shift;
		ref($data) || return $class->error_handler("In ${class}::modify() called without data hash");
		## Must have all three of these, and $data must contain something ##
		return undef unless (((ref($params) eq 'HASH') || (ref($params) eq 'ARRAY')) && (ref($data) eq 'HASH') && %$data);
	}

	## Start Content Fields Code ##
	my %content;
	if (my $contentfields = $class->contentfields) {
		foreach (keys %$contentfields) {
			$content{$_} = delete $data->{$_};
			warn "contentfield $_ ==> " . $content{$_} . "\n" if ($debug > 1);
		}
		(%content && !ref($self)) && return $class->error_handler("In ${class}::modify() - static (group) modify called specifying special content fields");
	}
	## End Content Fields Code ##

	## Start Date Fields Code ##
	if (my $datefields = $class->datefields) {
		foreach (keys %$datefields) {
			$data->{$_} = $data->{$_}->time2str( $self->date_format ) if (ref $data->{$_});
			warn "datefield $_ ==> " . $data->{$_} . "\n" if ($debug > 1);
		}
	}
	## End Date Fields Code ##

	## Start Relation Code ##
	my %selected;
	if (ref $class->relations) {
		foreach (keys %{ $class->relations }) {
			$selected{$_} = { map{ $_ => 1 } @{ delete $data->{$_} } } if ($data->{$_});
		}
		(%selected && !ref($self)) && return $class->error_handler("In ${class}::modify() - static (group) modify called specifying relationships");
	}
	## End Relation Code ##

	local $dbh->{'AutoCommit'} = 0 if (%selected || %content);		# BEGIN TRANSACTION (if needed)
	eval {
		local $dbh->{'RaiseError'} = 1;
		if (keys %$data) {
			my (@update_fields, @update_values);
			foreach (keys %{ $data }) {
				next if ({map { $_ => 1 } @{ $self->primary_keys || []}}->{$_});
				exists($class->deffields->{$_}) || croak "method $_ doesn't exist in \%${class}::deffields\n"; 

				my $value = $data->{$_};
				$self->{$_} = $value if (ref $self);

				if (index($value, '##') != -1) {
					while ($value =~ s/##(.+?)##/?/o) {
						push(@update_values, $1);
					}
					push(@update_fields, $_ . ' = ' . $value);
					$self->{$_} = '' if (ref $self);
				} else {
					push(@update_fields, $_ . ' = ' . (defined $value ? '?' : 'NULL'));
					push(@update_values, (defined $value ? $value : ( )));
				}
			}

			## make UPDATE statement ##
			my ($where, @wherevals)	= $class->format_conditions( $dbh, $params );
			my $UPDATE = "UPDATE " . $class->table . " SET " . join(',', @update_fields) . " $where";
			warn "$class->modify :\t\t\t\"$UPDATE\" [@update_values] [@wherevals]\n" if ($debug);

			## UPDATE data ##
			my $sth = $dbh->prepare( $UPDATE )			|| croak "$UPDATE;\n" . $dbh->errstr . "\n";
			$sth->execute( @update_values, @wherevals )	|| croak "execute\n$UPDATE;\n" . $sth->errstr . "\n";
			$sth->finish;
		}	

		######################### BEGIN Relations Code ########################
		###	This next block itterates through the class names in $selected	###
		###	hashref and does the following:									###
		###		1. Gets previously related objects of said class.			###
		###		2. Compares previously related objects to new list of		###
		###			related objects.										###
		###			-	In order to do this it gets the cpkey() of each		###
		###				previously related object and puts					###
		###				them all in a hash.									###
		###		3. Unrelates no longer related objects.						###
		###		4. Relates all newly related objects.						###
		#######################################################################
		if (%selected) {
			## Iterates through classnames in $selected ##
			foreach my $relclass (keys %selected) {
				## puts cpkeys of $_ classname ##
				my %local_selected	= %{ $selected{$relclass} };

				## get already related objects ##
				my $current_objs	= $self->list_related( $relclass );

				## creates a hash of cpkeys => objects. ##
				my %cpkeys			= map { $_->cpkey => $_ } @$current_objs;

				## remove keys from cpkeys that are also in local selected. ##
				%cpkeys = map { $_ => $cpkeys{$_} } grep {!$local_selected{$_}} keys %cpkeys;
				foreach my $cpk (keys %cpkeys) {			# go through previously related cpkeys
					$self->unrelate( $cpkeys{$cpk} );		# unrelate
				}

				## Here we relate all newly related items (we also might be related objects	##
				## which are already related, but it won't mind)							##
				foreach my $cpk (keys %local_selected) {			# goes through all newly related cpkeys
					my %params;
					@params{ @{ $relclass->primary_keys } } = split($self->pkd,$cpk);
					$self->relate( $relclass->get( $dbh, \%params ) );
				}
			}
		}
		################################### END RELATIONS CODE ################################################

		## Save content data. ##
		foreach (keys %content) {
			warn "Saving content: $_ ==> $content{$_}" if ($debug > 1);
			$self->$_( $content{$_} );
		}
	}; # END of eval

	## Caught exception, ROLLBACK TRANSACTION ##
	if ($@) {
		$self->errors( $@ );
		$dbh->rollback if (%selected || %content);
		return $class->error_handler("In ${class}::modify() - $@");
	}
	$dbh->commit if (%selected || %content);

	return ref($self) ? $self : 1;
} # END sub modify

=item C<duplicate> ( [ $dbh, ] [ $object ] )

Returns a duplicate object, differing only by the primary key.

=cut
sub duplicate {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;

	$self		= ref($self) ? $self : $class->get( shift() );
	my $data	= { %$self };
	foreach (@{ $self->primary_keys }) {
		delete $data->{$_};
	}

	$class->new( $dbh, $data );
} # END sub duplicate

=item C<rm> ( )

Object method:

Deletes the object and all database records associated with it.

=item C<rm> ( $dbh, \%params )

Static method:

Deletes all database rows satisfied by the conditions in \%params.

For instructions on the format of \%params, see L<"item_format_conditions">.

=cut
sub rm {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	ref($dbh) || return $class->error_handler("In ${class}::rm() called without dbh object");
	my $params;

	local $dbh->{'AutoCommit'} = 0;					# BEGIN TRANSACTION
	eval {
		local $dbh->{'RaiseError'} = 1;

		## Object method section ##
		if (ref $self) {
			## Use values of primary keys as conditional parameters	##
			## (to effect this row only)							##
			$params = { map { $_ => $self->$_() } @{ $self->primary_keys } };

			## Start Content Fields Code ##
			my @contentfields = keys %{ $class->contentfields };
			map { $self->$_('') } @contentfields;	# this deletes the content fields
			## End Content Fields Code ##

			## Start Unrelate related objects Code ##
			if ($class->relations) {
				foreach (keys %{ $class->relations }) {
					$self->unrelate( $self->list_related( $_ ) );
				}
			}
			## End Unrelate related objects Code ##

		## Static method section ##
		} else {
			$params	= shift;
			return undef unless (ref($params) eq 'HASH' || ref($params) eq 'ARRAY');
		}

		my ($where, @wherevals)	= $class->format_conditions( $dbh, $params );
		die "invalid conditions\n" unless ($where);

		my $DELETE	= 'DELETE FROM ' . $class->table . ' ' . $where;
		warn "$class->rm :\t\t\t\"$DELETE\" [@wherevals]\n" if ($debug);

		## execute statement or error out ##
		my $sth	= $dbh->prepare( $DELETE )	|| croak "$DELETE;\n" . $dbh->errstr . "\n";
		$sth->execute( @wherevals )			|| croak "$DELETE;\n" . $sth->errstr . "\n";
		$sth->finish;
	}; # END of eval

	## Caught exception, ROLLBACK TRANSACTION ##
	if ($@) {
		$self->errors( $@ );
		$dbh->rollback;
		return $class->error_handler("In ${class}::rm() - $@");
	}
	$dbh->commit;

	## delete sucessful ##
	ref($self) && undef( %{ $self } );				# Scoop out creamy filling
	return 1;
} # END sub rm

=back

=cut

################################################################################
############################## Data List Methods: ##############################
################################################################################


=head2 DATA LIST CONSTRUCTOR METHODS

=over 4

=item C<list_obj> ( [ $dbh, ] \%params, \@fields, \@sort )

Returns an arrayref of objects meeting all specifications in \%params.

For instructions on the format of \%params, see L<"item_format_conditions">.

=cut
sub list_obj {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	ref($dbh)	|| return $self->error_handler('BingoX::Carbon::list_obj called without dbh object');
	my $params	= shift || { };
	my $fields	= shift;
	if (!$BingoX::Carbon::cache_all{ $class } && ref($fields) eq 'ARRAY') {
		## Make sure primary keys are included in $fields (map construct removes duplicates) ##
		$fields 	= [
						keys %{
								{
									map { $_ => 1 } (@$fields, @{ $class->primary_keys })
								}
							}
					];
	} else {
		## No fields passed, use the default ##
		$fields		= $BingoX::Carbon::cache_all{$class} ? $class->fieldorder : $class->primary_keys;
	}
	my $sort	= shift || $class->primary_keys;
	my ($SELECT, @bindings)	= $class->format_select( $dbh, $params, $fields, $sort );
	unless ($SELECT) {
		warn "no select statement" if ($debug);
		return undef;
	}
	warn "list_obj: $SELECT" if ($debug);
	my $code	= $class->sql_select( $dbh, $SELECT, \@bindings );
	return undef unless (ref $code);
	my (@data, $data);
	while ($data = $code->()) {
		$data->{'_dbh'} = $dbh;
		push @data, bless($data, $class);
	}
	return \@data;
} # END sub list_obj

=item C<list_hash> ( [ $dbh, ] \%params, \@fields, \@sort )

Returns an arrayref of hashrefs meeting all specifications in \%params

For instructions on the format of \%params, see L<"item_format_conditions">.

=cut
sub list_hash {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	ref($dbh)	|| return $self->error_handler('BingoX::Carbon::list_hash called without dbh object');
	my $params	= shift || { };
	my $fields	= shift || $class->fieldorder;
	my $sort	= shift || $class->primary_keys;
	my ($SELECT, @bindings)	= $class->format_select( $dbh, $params, $fields, $sort );
	unless ($SELECT) {
		warn "no select statement" if ($debug);
		return undef;
	}
	warn "list_hash: $SELECT" if ($debug);
	my $code	= $class->sql_select( $dbh, $SELECT, \@bindings );
	return undef unless (ref $code);
	my @data;
	while (my $data = $code->()) {
		push(@data, $data);
	}
	return \@data;
} # END sub list_hash

=item C<list_array> ( [ $dbh, ] \%params, \@fields, \@sort )

Returns an arrayref of arrayrefs meeting all specifications in \%params. Data is sorted 
in the order of $class->deffields.

For instructions on the format of \%params, see L<"item_format_conditions">.

=cut
sub list_array {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	ref($dbh)	|| return $self->error_handler('BingoX::Carbon::list_array called without dbh object');
	my $params	= shift || { };
	my $fields	= shift || $class->fieldorder;
	my $sort	= shift || $class->primary_keys;
	my ($SELECT, @bindings)	= $class->format_select( $dbh, $params, $fields, $sort );
	unless ($SELECT) {
		warn "no select statement" if ($debug);
		return undef;
	}
	warn "list_array: $SELECT" if ($debug);
	my $code	= $class->sql_select( $dbh, $SELECT, \@bindings );
	return undef unless (ref $code);
	my @data;
	while (my $data = $code->()) {
		my @row	= map { $data->{$_} } @{ $fields };
		push(@data, \@row);
	}
	return \@data;
} # END sub list_array

=back

=cut

################################################################################
############################# Data Stream Methods: #############################
################################################################################


=head2 DATA STREAM CONSTRUCTOR METHODS

=over 4

=item C<stream_obj> ( [ $dbh, ] \%params, \@fields, \@sort )

Returns an code reference which, when dereferenced, will continue to return objects 
meeting all specifications in \%params until all matching rows have been returned, then 
it will return undef.  Will optionally limit itself to the fields specified in \@fields, 
and optionally sorted in the order of \@sort.

For instructions on the format of \%params, see L<"item_format_conditions">.

=cut
sub stream_obj {
	my $self 	= shift;
	my $class 	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	ref($dbh) || return $self->error_handler('BingoX::Carbon::stream_obj called without dbh object');
	my $params	= shift || { };
	my $fields	= shift;
	if (!$BingoX::Carbon::cache_all{ $class } && ref($fields) eq 'ARRAY') {
		## Make sure primary keys are included in $fields (map construct removes duplicates) ##
		$fields 	= [
						keys %{
								{
									map { $_ => 1 } (@$fields, @{ $class->primary_keys })
								}
							}
					];
	} else {
		## No fields passed, use the default ##
		$fields		= $BingoX::Carbon::cache_all{ $class } ? $class->fieldorder : $class->primary_keys;
	}
	my $sort	= shift || $class->primary_keys;
	my ($SELECT, @bindings)	= $class->format_select( $dbh, $params, $fields, $sort );
	unless ($SELECT) {
		warn "no select statement" if ($debug);
		return undef;
	}
	my $code	= $class->sql_select( $dbh, $SELECT, \@bindings );
	return undef unless (ref $code);
	return bless(sub {
					my $data		= $code->(@_) || return undef;
					$data->{'_dbh'}	= $dbh;
					return bless( $data, $class );
				}, 'BingoX::Carbon::Stream');
} # END sub stream_obj

=item C<stream_hash> ( [ $dbh, ] \%params, \@fields, \@sort )

Returns an code reference which, when dereferenced, will continue to return a hashref 
meeting all specifications in \%params until all matching rows have been returned, then 
it will return undef.  Will optionally limit itself to the fields specified in \@fields, 
and optionally sorted in the order of \@sort.

For instructions on the format of \%params, see L<"item_format_conditions">.

=cut
sub stream_hash {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	ref($dbh)	|| return $self->error_handler('BingoX::Carbon::stream_hash called without dbh object');
	my $params	= shift || { };
	my $fields	= shift || $class->fieldorder;
	my $sort	= shift || $class->primary_keys;
	my ($SELECT, @bindings)	= $class->format_select( $dbh, $params, $fields, $sort );
	unless ($SELECT) {
		warn "no select statement" if ($debug);
		return undef;
	}
	my $code	= $class->sql_select( $dbh, $SELECT, \@bindings );
	return undef unless (ref $code);
	return bless(sub {
					my $data	= $code->(@_) || return undef;
					return $data;
				}, 'BingoX::Carbon::Stream');
} # END sub stream_hash

=item C<stream_array> ( [ $dbh, ] \%params, \@fields, \@sort )

Returns an code reference which, when dereferenced, will continue to return an arrayref 
meeting all specifications in \%params until all matching rows have been returned, then 
it will return undef. Will optionally limit itself to the fields specified in \@fields, 
and optionally sorted in the order of \@sort.

For instructions on the format of \%params, see L<"item_format_conditions">.

=cut
sub stream_array {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	ref($dbh)	|| return $self->error_handler('BingoX::Carbon::stream_array called without dbh object');
	my $params	= shift || { };
	my $fields	= shift || $class->fieldorder;
	my $sort	= shift || $class->primary_keys;
	my ($SELECT, @bindings)	= $class->format_select( $dbh, $params, $fields, $sort );
	unless ($SELECT) {
		warn "no select statement" if ($debug);
		return undef;
	}
	my $code	= $class->sql_select( $dbh, $SELECT, \@bindings );
	return undef unless (ref $code);
	return bless(sub {
					my $data	= $code->(@_) || return undef;
					my @row		= map { $data->{$_} } @{ $fields };
					return \@row;
				}, 'BingoX::Carbon::Stream');
} # END sub stream_array

=back

=cut

################################################################################
############################# Relational Methods: ##############################
################################################################################


=head2 RELATIONAL METHODS

=over 4

=item C<relate> ( $OBJ )

=item C<relate> ( \@OBJECTS )

=item C<relate> ( \@IDS, $ID_CLASS, $ID_COLUMN )

Relates object to $OBJ, all objects in \@OBJECTS, or objects represented by 
\@IDS from the $ID_CLASS class in the $ID_COLUMN column of the database. Returns 
the number of objects passed that have been related to the object.

=cut
sub relate {
	my $self		= shift;
	my $class		= ref($self) || return $self->error_handler('relate must be called as an object method');
	my $dbh			= $self->dbh;
	my $data		= shift;
	my (@OBJECTS, $fclass, $rclass);
	############################################################################
	##  code duped from get_relation_info so that grep can be used to single  ##
	##                 out relations that don't exist already                 ##
	############################################################################
	if (ref($data) eq 'ARRAY') {
		if ($#{ $data } >= 0) {
			if ($fclass = ref($data->[0])) {	# Array of objects
				@OBJECTS	= @{ $data };
			} else {							# Array of IDs
				$fclass		= shift;
				my $column	= shift;
				@OBJECTS	= @{ $fclass->list_obj( $dbh,
													{
														$column => [ 'IN', @$data ]
													}
												  )
								};
			}
		} else {
			return $self->error_handler('empty array reference passed to relate');
		}
	} elsif ($fclass = ref($data)) {			# Single object
		@OBJECTS	= ( $data );
	} else {
		return $self->error_handler('relate called with invalid parameters - check documentation');
	}
	############################################################################

	## OBJECTS to be related are in the ARRAY @OBJECTS ##
	my $related		= 0;
	my $toberelated	= $#OBJECTS;
	@OBJECTS		= grep { 1 ^ $self->isrelated( $_ ) } @OBJECTS;
	$related		= ($toberelated - $#OBJECTS);	# Add already related objects

	($rclass, $data)	= $self->get_relation_info( 'I', \@OBJECTS );
	return $related unless (ref($data) eq 'ARRAY');
	foreach (@{ $data }) {
		$rclass->new( $dbh, $_ ) || next;
		$related++;
	}
	return $related;
} # END sub relate


=item C<unrelate> ( $OBJ )

=item C<unrelate> ( \@OBJECTS )

=item C<unrelate> ( \@IDS, $ID_CLASS, $ID_COLUMN )

Unrelates object from $OBJ, all objects in \@OBJECTS, or objects represented by 
\@IDS from the $ID_CLASS class in the $ID_COLUMN column of the database. Returns 
the number of objects that no longer are related to the object. 

=cut
sub unrelate {
	my $self	= shift;
	my $class	= ref($self) || return $self->error_handler('unrelate must be called as an object method');
	my $dbh		= $self->dbh;
	my $data	= shift;
	my (@OBJECTS, $fclass, $rclass);
	############################################################################
	##  code duped from get_relation_info so that grep can be used to single  ##
	##                 out relations that don't exist already                 ##
	############################################################################
	if (ref($data) eq 'ARRAY') {
		if ($#{ $data } >= 0) {
			if ($fclass = ref($data->[0])) {	# Array of objects
				@OBJECTS	= @{ $data };
			} else {							# Array of IDs
				$fclass	= shift;
				my $column	= shift;
				@OBJECTS	= @{ $fclass->list_obj( $dbh,
													{
														$column => [ 'IN', @$data ]
													}
												)
								};
			}
		} else {
			return $self->error_handler('empty array reference passed to unrelate');
		}
	} elsif ($fclass = ref($data)) {			# Single object
		@OBJECTS	= ( $data );
	} else {
		return $self->error_handler('unrelate called with invalid parameters - check documentation');
	}
	############################################################################

	## OBJECTS to be unrelated are in the ARRAY @OBJECTS ##
	my $removed			= scalar(@OBJECTS);
	@OBJECTS			= grep { $self->isrelated( $_ ) } @OBJECTS;

	($rclass, $data)	= $self->get_relation_info( 'S', \@OBJECTS );
	return $removed unless (ref($data) eq 'HASH');
	my $list			= $rclass->list_obj( $dbh, $data );
	return undef unless (ref $list);
	foreach my $OBJ (@$list) {
		$removed-- unless ($OBJ->rm);
	}
	return $removed;
} # END sub unrelate


=item C<unrelate_all> ( $fclass [ , $unary_rev ] )

Unrelates all related objects in class $fclass from current object.  
Optional $unary_rev does reverse operation for unary relationships 

i.e.:

 unrelates "parent" objects from current

=cut
sub unrelate_all {
	my $self		= shift;
	my $class		= ref($self) || return $self->error_handler('unrelate_all must be called as an object method');
	my $dbh			= $self->dbh;
	my $fclass		= shift;
	my $unary_rev	= shift;			# UNARY REVERSE FLAG (use second column)
	my $rclass		= $self->relations->{ $fclass } || return $self->error_handler("class $class is not related to class $fclass");
	my $params		= $self->_related_subquery_conditions( $fclass, $unary_rev );
	$rclass->rm( $dbh, $params );
} # END sub unrelate_all


=item C<isrelated> ( $OBJ )

Returns a true value if $OBJ is related to the object, false otherwise.

=cut
sub isrelated {
	my $self			= shift;
	my $class			= ref($self) || return $self->error_handler('isrelated must be called as an object method');
	my $dbh				= $self->dbh;
	my $OBJECT			= shift || return undef;
	my ($rclass, $data)	= $self->get_relation_info( 'S', $OBJECT );
	return undef unless (ref($data) eq 'HASH');
	return ref($rclass->get( $dbh, $data )) ? 1 : 0;
} # END sub isrelated


=item C<list_related> ( $class [, \@fields] [, \@sort] [, $unary_rev_flag ] )

Returns an arrayref of objects of $class related to the object.

=cut
sub list_related {
	my $self		= shift;
	my $class		= ref($self) || return $self->error_handler('method list_related must be called as an object method');
	my $dbh			= $self->dbh;
	my $fclass		= shift || return undef;
	my $fields		= shift || $fclass->primary_keys;
	my $sort		= shift || $fclass->primary_keys;
	my $unary_rev	= shift;			# UNARY REVERSE FLAG (use second column)
	my $code		= $self->stream_related( $fclass, $fields, $sort, $unary_rev );
	return undef unless (ref $code);
	my @array;
	while (my $data = $code->()) {
		push(@array, $data);
	}
	return \@array;
} # END sub list_related


=item C<stream_related> ( $class [, \@fields] [, \@sort] [, $unary_rev_flag ] )

Returns an code reference which, when dereferenced, will continue to return objects 
of $class related to the object until all matching rows have been returned, then 
it will return undef.

=back

=cut
sub stream_related {
	my $self		= shift;
	my $class		= ref($self) || return $self->error_handler('method list_related must be called as an object method');
	my $dbh			= ref($self) ? $self->dbh : return undef;
	my $fclass		= shift || return undef;
	my $fields		= shift || $fclass->primary_keys;
	my $sort		= shift || $fclass->primary_keys;
	my $unary_rev	= shift;			# UNARY REVERSE FLAG (use second column)
	my $params		= $self->_related_conditions( $fclass, $unary_rev );
	return $fclass->stream_obj( $dbh, $params, $fields, $sort );
} # END sub stream_related


=begin private_method

	_related_subquery_conditions ( $fclass [, $unary_rev ] )
		- $fclass is the "foreign" class (related class)
		- in scalar context, returns \%fparams (see unrelate_all())
		- in array context, returns (\%fparams, \@fcolumns, \@columns) (see _related_conditions())
			%fparams  : parameters of query (can be passed to format_conditions())
			@fcolumns : relevant columns in foreign class
			@columns  : relevant columns in this class

=end private_method

=cut
sub _related_subquery_conditions {
	my $self		= shift;
	my $class		= ref($self) || return $self->error_handler('method _related_subquery_conditions must be called as an object method');
	my $fclass		= shift || return undef;
	my $unary_rev	= shift;			# UNARY REVERSE FLAG (use second column)
	my $relations	= $class->relations;
	my $rclass		= $relations->{ $fclass } || return undef;
	my $rfkeys		= $rclass->foreign_keys;
	my @columns		= ( $class );		# Doesn't belong in the array, but it'll get shifted
	my @fcolumns	= ( $fclass );		# off at the beginning of the block below.
	my %fparams;

	if ($class eq $fclass) {			# UNARY RELATIONSHIP
		my $data 	= $rfkeys->{ $class };
		@columns = @fcolumns = ( );
		foreach my $key (keys %{ $data }) {
			next unless (ref($data->{ $key }) eq 'ARRAY');
			push @columns, $key;
			push @fcolumns, $data->{ $key };
		}
		%fparams = map {
							$fcolumns[$_]->[($unary_rev ? 1 : 0)] => $self->${\$columns[$_]}()
						} (0 .. $#columns);
	} else {							# BINARY RELATIONSHIP
		foreach my $arrayref (\@fcolumns, \@columns) {
			my $data = $rfkeys->{ shift(@$arrayref) };
			if (ref($data) eq 'HASH') {
				foreach my $key (keys %{ $data }) {
					if (ref($data->{ $key }) eq 'ARRAY') {
						next;			# Aieee, unary syntax in binary relationship
					} else {
						push(@$arrayref, $data->{ $key });
					}
				}
			} elsif (ref($data) eq 'ARRAY') {
				@$arrayref	= @{ $data };
			} elsif (!(ref $data)) {
				@$arrayref	= ( $data );
			} else {
				return undef;
			}
		}
		%fparams = map { $_ => $self->$_() } @columns;
	}
	return wantarray ? (\%fparams, \@fcolumns, \@columns) : \%fparams;
} # END sub _related_subquery_conditions


=begin private_method

	_related_conditions ( $fclass [, $unary_rev ] )
		- $fclass is the "foreign" class (related class)
		- generates conditions suitable for using with stream_obj()
		- used only by stream_related() and list_related()

=end private_method

=cut
sub _related_conditions {
	my $self		= shift;
	my $class		= ref($self) || return $self->error_handler('method _related_conditions must be called as an object method');
	my $dbh			= ref($self) ? $self->dbh : return undef;
	my $fclass		= shift || return undef;
	my $unary_rev	= shift;			# UNARY REVERSE FLAG (use second column)
	my $relations	= $class->relations;
	my $rclass		= $relations->{ $fclass } || return undef;
	my $rfkeys		= $rclass->foreign_keys;

	my($fparams, $fcolumns, $columns) = $self->_related_subquery_conditions( $fclass, $unary_rev );
	my %params;
	if ($class eq $fclass) {
		foreach my $i (0 .. $#{ $fcolumns }) {
			$params{ $columns->[$i] }	= [
											'IN',
											$rclass->format_select(
												$dbh,
												$fparams,
												[
													$fcolumns->[$i]->[($unary_rev ? 0 : 1)]
												],
												undef,
												'rel'
											)
										];
		}
	} else {
		foreach my $i (0 .. $#{ $fcolumns }) {
			$params{ $fcolumns->[$i] }	= [
											'IN',
											$rclass->format_select(
												$dbh,
												$fparams,
												[
													$fcolumns->[$i]
												],
												undef,
												'rel'
											)
										];
		}
	}
	return \%params;
} # END sub _related_conditions


=over 4

=item C<get_relation_info> ( ('I' | 'S'), $OBJ )

=item C<get_relation_info> ( ('I' | 'S'), \@OBJECTS )

=item C<get_relation_info> ( ('I' | 'S'), \@IDS, $ID_CLASS, $ID_COLUMN )

Returns as the first element the relational class on which the second data element 
is associated. If the first argument is an 'I' (INSERT), the second element is a 
hashref suitable to pass to new or modify. If the first argument is an 'S' (SELECT), 
returns a hashref suitable to pass to get, list_*, stream_*, etc. This method is 
primarily used by methods relate, unrelate, isrelated, and related.

=cut
sub get_relation_info {
	my $self		= shift;
	my $class		= ref($self) || return $self->error_handler('relate must be called as an object method');
	my $dbh			= $self->dbh;
	my $type		= shift || return undef;
	my $data		= shift;

	my ($OBJECTS, $fclass);
	if (ref($data) eq 'ARRAY') {
		if ($#{ $data } >= 0) {
			if ($fclass		= ref($data->[0])) {	# Array of objects
				$OBJECTS	= $data;
			} else {								# Array of IDs
				$fclass	= shift;
				my $column	= shift;
				$OBJECTS	= $fclass->list_obj( $dbh, { $column => [ 'IN', @$data ] } );
			}
		} else {
			return undef;
		}
	} elsif ($fclass = ref($data)) {				# Single object
		$OBJECTS = [ $data ];
	} else {
		return undef;
	}

	## OBJECTS to be related are in the ARRAYREF $OBJECTS ##
	my $relations	= $self->relations		|| return $self->error_handler("No relations found for the $class class");
	my $rclass		= $relations->{$fclass}	|| return undef;
	my $rfkeys		= $rclass->foreign_keys	|| return $self->error_handler("No foreign keys found for the $rclass class");
	my (%objects, %relational_columns);
	$relational_columns{'local'}	= $rfkeys->{ $class };
	$relational_columns{'foreign'}	= $rfkeys->{ $fclass };
	@objects{ 'local', 'foreign' }	= ( [ $self ], $OBJECTS );
	if ($type eq 'S') {
		my %params;
		foreach (qw(local foreign)) {
			my $data	= $relational_columns{$_};
			my (%column_info, $columns);
			if (ref($data) eq 'HASH') {			# Multiple columns represent the same primary key (to relate two of the same type of item)
				%column_info	= %{ $data };
				$columns		= [ keys %column_info ];
			} elsif (ref($data) eq 'ARRAY') {
				$columns		= $data;
			} elsif (!(ref $data)) {
				$columns		= [ $data ];
			} else {
				return $self->error_handler("Relation misconfiguration in $class or $fclass");
			}
			foreach my $column (@{ $columns }) {
				my $method	= $column;
				if (ref($column_info{ $column })) {
					my $i	= 0;
					do {
						last unless (defined($column = $column_info{ $method }->[$i++]));
					} while (exists $params{ $column });
					return undef if (exists $params{ $column });
				}
				next unless (ref $objects{$_}->[0]);
				if ($#{ $objects{ $_ } } == 0) {
					$params{ $column }	= $objects{$_}->[0]->$method();
				} else {
					$params{ $column }	= [
											'IN',
											map { $_->$method() } @{ $objects{$_} }
										];
				}
			}
		}
		warn "get_relation_info returning SELECT to " . (caller 1)[3] . " data: " . Data::Dumper::Dumper(\%params) if ($debug);
		return ($rclass, \%params);
	} elsif ($type eq 'I') {
		my $data	= $relational_columns{'local'};
		my (%gparams, %column_info, $columns);
		if (ref($data) eq 'HASH') {			# Multiple columns represent the same primary key (to relate two of the same type of item)
			%column_info	= %{ $data };
			$columns		= [ keys %column_info ];
		} elsif (ref($data) eq 'ARRAY') {
			$columns		= $data;
		} elsif (!(ref $data)) {
			$columns		= [ $data ];
		} else {
			return $self->error_handler("Relation misconfiguration in $class");
		}
		foreach my $column (@{ $columns }) {
			my $method			= $column;
			$column				= $column_info{ $column }->[0] if (ref($column_info{ $column }) eq 'ARRAY');
			$gparams{ $column }	= $self->$method();
		}

		my @params;
		$data = $relational_columns{'foreign'};
		foreach my $OBJECT (@{ $OBJECTS }) {
			my %params = ( %gparams );
			my (%column_info, $columns);
			if (ref($data) eq 'HASH') {			# Multiple columns represent the same primary key (to relate two of the same type of item)
				%column_info	= %{ $data };
				$columns		= [ keys %column_info ];
			} elsif (ref($data) eq 'ARRAY') {
				$columns		= $data;
			} elsif (!(ref $data)) {
				$columns		= [ $data ];
			} else {
				return $self->error_handler("Relation misconfiguration in $fclass");
			}
			foreach my $column (@{ $columns }) {
				my $method	= $column;
				$column	= $column_info{ $column }->[1] if (ref($column_info{ $column }) eq 'ARRAY');
				$params{ $column }	= $OBJECT->$method();
			}
			push(@params, \%params);
		}
		warn "get_relation_info returning INSERT to " . (caller 1)[3] . " data: " . Data::Dumper::Dumper(\@params) if ($debug);
		return ($rclass, \@params);
	} else {
		return undef;
	}
} # END sub get_relation_info

=back

=cut

################################################################################
######################## Class Variable Access Methods: ########################
################################################################################


=head2 CLASS DATA ACCESSOR METHODS

=over 4

=item C<table> ( [ $dbh ] )

Returns class defined table name

=cut
sub table {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	return ${"${class}::table"} || $self->error_handler("Package variable ${class}::table not defined");
} # END sub table


=item C<identity> ( [ $dbh ] )

Returns class defined identity column as a string.

=cut
sub identity {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	return ${"${class}::identity"};
} # END sub identity


=item C<sequence> ( [ $dbh ] )

Returns class defined sequence used by this table as a string.

=cut
sub sequence {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	return ${"${class}::sequence"};
} # END sub sequence


=item C<seqcol> ( [ $dbh ] )

Returns class defined seqcol used by this table as a string.

=cut
sub seqcol {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	return ${"${class}::seqcol"};
} # END sub seqcol


=item C<def_fields> (  )

Returns class defined fields as a hash reference

=cut
sub deffields { $_[0]->def_fields }
sub def_fields {
	my $self	= shift;
	my $class	= ref($self) || $self;
	no strict 'refs';
	return \%{"${class}::deffields"} if (defined %{"${class}::deffields"});
	return \%{"${class}::def_fields"} if (defined %{"${class}::def_fields"});
	return { %{"${class}::def_fields"} = map { $_ => 1 } @{ $class->field_order || [ ] } };
} # END sub def_fields


=item C<field_order> (  )

Returns class defined field order as an anonymous array

=cut
sub fieldorder { $_[0]->field_order }
sub field_order {
	my $self	= shift;
	my $class	= ref($self) || $self;
	no strict 'refs';
	return [ @{"${class}::fieldorder"} ] if (@{"${class}::fieldorder"});
	return [ @{"${class}::field_order"} ] || $self->error_handler("Package variable ${class}::field_order not defined");
} # END sub field_order


=item C<relations> (  )

Returns class defined relations as a hash reference

=cut
sub relations {
	my $self	= shift;
	my $class	= ref($self) || $self;
	no strict 'refs';
	return { %{"${class}::relations"} };
} # END sub relations


=item C<foreign_keys> (  )

Returns class defined foreign_keys as a hash reference

=cut
sub foreign_keys {
	my $self	= shift;
	my $class	= ref($self) || $self;
	no strict 'refs';
	return { %{"${class}::foreign_keys"} };
} # END sub foreign_keys


=item C<cpkey> (  )

Returns a string representing a single composite primary key joined by $self->pkd.

B<OPTIMIZE>

=cut
sub cpkey {
	my $self	= shift;
	return undef unless (ref $self);
	return $self->{'_cpkey'} if ($self->{'_cpkey'});
	$self->{'_cpkey'} = join($self->pkd, map { $self->$_() } @{ $self->primary_keys } );
	return $self->{'_cpkey'};
} # END sub cpkey

=item C<cpkey_params> ($cpkey) 

Returns a params hash from the cpkey string passed.

=cut
sub cpkey_params {
	my $self	= shift;
	my $cpkey	= shift;
	my $pkeys	= $self->primary_keys;
	
	my $hash = {
				map {
						shift(@{ $pkeys }) => $_
					} split($self->pkd, $cpkey)
			};
	return $hash;
} # END sub cpeky

=item C<title_field> (  )

Returns class defined title_field as a string.

=cut
sub title_field {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	return ${"${class}::title_field"};
} # END sub title_field


=item C<title_size> (  )

Returns class defined title_size as a string.

=cut
sub title_size {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	return ${"${class}::title_size"};
} # END sub title_size


=item C<content_fields> (  )

Returns class defined content fields order as an hashref

=cut
sub contentfields { $_[0]->content_fields }
sub content_fields {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	return { %{"${class}::contentfields"} } if (keys %{"${class}::contentfields"});
	return { %{"${class}::content_fields"} };
} # END sub content_fields


=item C<date_fields> (  )

Returns class defined date fields order as an hashref

=cut
sub datefields { $_[0]->date_fields }
sub date_fields {
	no strict 'refs';
	my $self	= shift;
	my $class	= ref($self) || $self;
	return { %{"${class}::datefields"} } if (keys %{"${class}::datefields"});
	return { %{"${class}::date_fields"} };
} # END sub date_fields


=item C<primary_keys> ( [ $dbh ] )

Returns class defined primary keys as an array ref.  
NOTE: The use of the class variable $primary_key has been deprecated!  
primary_keys will construct an array ref with $primary_key if it is used. 
Future verson of BingoX::Carbon will not support this!

=cut
sub primary_keys {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	no strict 'refs';
	my @pkeys	= @{"${class}::primary_keys"};
	unless (@pkeys) {
		@pkeys	= ( ${"${class}::primary_key"} );
		$self->error_handler("Package variable ${class}::primary_keys not defined") unless (@pkeys);
	}
	return \@pkeys;
} # END sub primary_keys

=item C<dbh> ( )

Returns class database handler object.  
Keeps a global which gets removed with a $r->register_cleanup.

=cut
sub dbh {
	my $self	= shift;
	my $class	= ref($self) || $self;
	return $self->{'_dbh'} if (ref($self) && ref($self->{'_dbh'}));
	if (ref(my $dbh = $self->cached_dbh)) {
		return $dbh;
	} else {
		$dbh			= $self->connectdb;
		$self->{'_dbh'}	= $dbh if (ref $self);
		$self->cached_dbh( $dbh );
		return $dbh;
	}
} # END sub dbh


=item C<cached_dbh> ( [ $dbh ] )

Returns the cached database handle if it has been set.  
Optionally sets the cached database handle to $dbh.

=cut
sub cached_dbh {
	my $self		= shift;
	my $class		= ref($self) || $self;
	my $dclass		= $self->dataclass( $class );
	no strict 'refs';
	if ($#_ >= 0) {
		my $new	= shift;
		if (ref $new) {
			warn "setting new dbh [${dclass}::dbh]" if ($debug > 2);
			${ "${dclass}::dbh" }	= $new;
			Apache->register_cleanup(sub { ${ "${dclass}::dbh" }	= undef; })
				if (exists $ENV{MOD_PERL});
		} else {
			warn "clearing cached dbh [${dclass}::dbh]" if ($debug > 2);
			${ "${dclass}::dbh" }	= undef;
		}
		warn "\tnew value: " . ${ "${dclass}::dbh" } if ($debug > 2);
	}
	return ${ "${dclass}::dbh" };
} # END sub cached_dbh


=item C<purge_dbh> (  )

Clears the database handle cache variable.

=cut
sub purge_dbh {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dclass	= $self->dataclass( $class );
	$self->cached_dbh( undef );
	return 1;
} # END method purge_dbh


=item C<error_handler> (  )

Carps @_ if debugging is activated
prints stack backtrace if $debug > 2
always returns undef (if you choose to overload this method, please make sure you return undef)

=cut
sub error_handler {
	my $class = ref($_[0]) ? ref(shift) : shift;
	$debug && (($debug > 2) ? cluck("$class: ", @_) : carp("$class: ", @_));
	return undef;
} # END sub error_handler


=item C<errors> (  )

Returns $self->{'_errors'} if called as an object method.  
Returns $errstr of the called class otherwise.

=cut
sub errors {
	my $self	= shift;
	my $data	= shift;
	if (ref $self) {
		if ($data) {
			$self->{'_errors'} = $data;
			return $self->{'_errors'};
		} else {
			return delete $self->{'_errors'};
		}
	} else {
		no strict 'refs';
		if ($data) {
			${"${self}::errstr"} = $data;
			return ${"${self}::errstr"};
		} else {
			my $error = ${"${self}::errstr"};
			${"${self}::errstr"} = undef;
			return $error;
		}
	}
} # END sub errors


=item C<data_class> (  )

Returns the data class

=cut
sub dataclass { $_[0]->data_class($_[1]) }
sub data_class {
	my $self	= shift;
	my $class	= shift;
	my $lclass	= $class;
	no strict 'refs';
	my @isa		= @{ "${class}::ISA" };
	while ($isa[0] ne __PACKAGE__) {
		$lclass = shift(@isa);
		unshift( @isa, @{ "${lclass}::ISA" } );
		return undef unless (@isa);
	}
	return $lclass;
} # END sub dataclass


=item C<data_class_name> (  )

Returns the rightmost part of the data_class_name name (thats the text right of the ::)

=cut
sub data_class_name {
	my $self		= shift;
	return $self->{'_data_class_name'} if (ref $self);
	$self->db_class	=~ /^.*:(.*)/;
	$self->{'_data_class_name'} = $1 if (ref $self);
	return $1;
} # END sub data_class_name


=item C<connectdb> ( )

*** NEEDS ERROR HANDLER ****

Called as a static method, it just returns the DBH Object.

=cut
sub connectdb {
	my $self	= shift;
	my $class	= ref($self) || $self;
	no strict 'refs';
	my $dclass	= $self->dataclass( $class );
	my @connect	= @{ "${dclass}::connectarray" };
	@connect = @DATABASE::connectarray unless @connect;
	my $dbh = DBI->connect( @connect ) || return $self->error_handler("Could not connect to the database @connect " . DBI->errstr . "\n");
	$dbh->do("alter session set NLS_DATE_FORMAT = 'Mon DD YYYY HH12:MI:SSAM'") if ($dbh->{'Driver'}->{'Name'} eq 'Oracle');
	return $dbh;
} # END sub connectdb


=item C<pkd> ( )

Returns a constant for the primary key delimiter.

=cut
sub pkd { return '~' }


=item C<date_format> ( )

Returns a constant, the strftime template for what date strings are to be 
displayed as.

=cut
sub date_format { return '%d %b %Y %T' }


=item C<str2time> ( $string )

This is method is used to parse your default date format into a format 
that str2time understands, such as:

  Date: 961221               (yymmdd)
  Date: 12-21-96             (mm-dd-yy)    ( '-', '.' or '/' )
  Date: 12-June-96           (dd-month-yy) ( '-', '.' or '/' )
  Date: June 12 96 00:00PM   (month dd yy hh:mmPM)
  Date: June 12 96 00::00:00 (month dd yy hh:mm::ss)

If time is not passed then time defaults to 00:00:00.

=cut
sub str2time {
	my $self	= shift;
	my $string	= shift;

	Date::Parse::str2time( $string );
} # END sub str2time


=back

=cut

################################################################################
################################# SQL Methods: #################################
################################################################################


=head2 SQL GENERATION METHODS

=over 4

=item C<sql_select> ( [ $dbh, ] $SELECT [, \@bindings] )

Excutes the prepared select statement and returns an arrayref of objects. The @bindings 
array contains values of SQL placeholders if used. Returns a code reference that will 
return a hashref when dereferenced.

=cut
sub sql_select {
	my $self		= shift;
	my $class		= ref($self) || $self;
	my $dbh			= ref($self) ? $self->dbh : shift;
	ref($dbh) || return $self->error_handler('BingoX::Carbon::sql_select called without dbh object');
	my $SELECT		= shift || return $self->error_handler("In ${class}::sql_select(), called without SELECT statement");
	my $bindings	= shift;
	my @bindings	= ref($bindings) ? @$bindings : ( );
	warn "$class->sql_select:\t\t\"$SELECT\" [@bindings]\n" if ($debug);
	my $sth;
	$sth = $dbh->prepare( $SELECT )	|| return $self->error_handler("In ${class}::sql_select(), prepare\n$SELECT;\n" . $dbh->errstr . "\n\n");
	$sth->execute( @bindings )		|| return $self->error_handler("In ${class}::sql_select(), execute\n$SELECT;\n" . $sth->errstr . "\n\n");
	return ($dbh->{'Driver'}->{'Name'} eq 'Oracle')
		? (bless(sub {									# Oracle version (slower!) 
			if ($_[0]) {
				$sth->finish if (defined $sth);
				undef $sth;
				return undef;
			}
			return undef unless ($sth->{'Active'});
			my $resultdata	= $sth->fetchrow_hashref;
			unless (ref($resultdata) eq 'HASH') {
				$sth->finish;
				return undef;
			}
			my $data = {
						map {
								(((join ' ',@{ $class->fieldorder }) =~ /\b($_)\b/i)[0] || $_) => $resultdata->{$_}
							} keys %$resultdata
					};
			return $data;
		}, 'BingoX::Carbon::Stream'))
		: (bless(
				sub {									# Normal version
					if ($_[0]) {
						$sth->finish if (defined $sth);
						undef $sth;
						return undef;
					}
					return undef unless ($sth->{'Active'});
					my $data	= $sth->fetchrow_hashref;
					unless (ref($data) eq 'HASH') {
						$sth->finish;
						return undef;
					}
					return $data;
				}, 'BingoX::Carbon::Stream'
			));
} # END sub sql_select


=item C<format_select> ( [ $dbh, ] \%params, \@fields, \@sort [, $alias ] )

Returns formatted SQL 'SELECT' statement, selecting @fields that meet all specifications 
in %params, sorted by @sort.  Also returns bindings of all dynamic placeholders in SQL statement.
Optionally, $alias may specify the table alias to be used in the statment
(" WHERE alias.name = 'myname'"). Sub-values should be surrounded by ##, 
ie "name LIKE ##me##", for conditions involving: ( LIKE, NOT, <, >, SELECT )
Finally, and sort terms may be reversed (made descending) by prepending them with a '-'. (e.g.,
to sort by 'col1' ascending and 'col2' descending, pass 'qw(col1 -col2)'.)

For instructions on the format of \%params, see L<"item_format_conditions">.

=cut
sub format_select {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	my $params	= shift;
	my $fields	= shift || $class->primary_keys;
	my $sort	= shift;
	my $alias	= shift;
	## make sure we have params ##
	return undef unless ((ref $params eq 'HASH') || (ref $params eq 'ARRAY'));
	$fields		= $class->primary_keys unless ($#{ $fields } >= 0);
	$fields		= join(', ', grep { $_ } @{ $fields });
	my $table	= $class->table;
	$table		.= " $alias" if ($alias);
	my ($WHERE, @bindings);
	if ((defined $params) && (((ref($params) eq 'HASH') && %{ $params }) || (ref($params) eq 'ARRAY' && @{ $params }))) {
		($WHERE, @bindings)	= $class->format_conditions( $params, $alias );
		return $self->error_handler('select conditions failed') unless (defined $WHERE);
	}

	# Don't complain to me about the lowercase SQL
	# -- for some reason the caps screw up on views in Oracle 8i (doesn't make 
	#    much sense to me)
	my @order	= (
					'select',
					$fields,
					'from',
					$table
				);

	push(@order, $WHERE) if ($WHERE);
	if (ref($sort) && (grep { $_ } @{ $sort })) {
		## ORDER ##
		push(@order, 'ORDER BY ' . join(', ', map { substr($_,0,1) eq '-' ? substr($_,1) . ' DESC' : $_ } @{ $sort }));
	}
	my $SELECT	= join(' ', @order);
	warn "$class->format_select:\t\t\"$SELECT\" [@bindings]\n" if ($debug);
	return($SELECT, @bindings);
} # END sub format_select


=item C<format_conditions> ( [ $dbh, ] \%params [, $alias ] )

Returns formatted sql 'WHERE' block, and an array of values to be bound (passed to 
DBI->execute().)  Optionally, $alias may specify the table alias to be used in the statment 
(" WHERE alias.name = 'myname'").  The keys of %params are the fields you are trying to match; 
the values of %params are specified as follows :

=back

=over 4

=item * equality condition

To test one equality, simply pass the value you wish to match as the value.

e.g. :

  { $field => 12 }
  { $field => 'twelve' }

=item * inequalities or multiple equalities (LIKE, NOT, <, >, IN, BETWEEN)

Sub-values should be surrounded by ##, ie "name LIKE ##me##", for conditions involving: 
( LIKE, NOT, <, > ).

To use IN or BETWEEN (with or without NOT), params should contain something similar 
to ( $field => [ $type, @LIST ] ) where $type is '[NOT ]IN' or '[NOT ]BETWEEN' and 
@LIST is the set of values for the statement.

=item * NULL/NOT NULL conditions

To test for a NULL condition or NOT NULL condition, pass 'IS NULL' or 'IS NOT NULL' 
(respectively) as the value.

e.g. :

  { $field => 'IS NOT NULL' }

=item * subqueries

When using a SELECT statement in an IN block, the argument immediately following the select 
statement should be the arrayref containing any bindings for that statement.  
This means that you may use the output of format_conditions as the input for a subquery : 

 $conditions = $obj_class1->format_conditions(
        $dbh,
        {
           $field => [
                        'IN',
                        $obj_class2->format_conditions( $dbh, $field => $value )
                     ]
        }
 );

=item * multiple values

To match multiple conditions, pass an arrayref (that does not begin with 'IN' or 'BETWEEN'!) 
containing a list of conditions (any of the conditions above.)  You MUST delimit each condition 
with either '&&' (for AND) or '||' (for OR), and you may also use '(' or ')' to separate logical 
conditions.

e.g. :

  { $field => [ 1, '||', '(', 2, '&&', 3, ')' ] }

=back

=cut
sub format_conditions {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	my $params	= ((ref $dbh eq 'HASH') || (ref $dbh eq 'ARRAY')) ? $dbh : (shift || { });
	my $alias	= shift;
	my $order;
	## Allow caller to specify order (and logical operation) of parameters ##
	if (ref $params eq 'ARRAY') {
		($order, $params) = @$params;
		if (@$order) {					# add parameters not specified in list
			my %tmpparams = %$params;
			map { delete $tmpparams{$_} } @$order;
			if (%tmpparams) {			# %tmpparams remaining are parameters not in $order list
				unshift @$order, '(';
				push @$order, (')', 'AND', split (' ', join(' AND ', keys %tmpparams)));
			}
		} else {						# order list empty!
			$order = [ split (' ', join(' AND ', keys %$params)) ];
		}
	} elsif (ref $params eq 'HASH') {
		$order = [ split (' ', join(' AND ', keys %$params)) ];
	} else {							# make sure we have params
		return undef;
	}

	## parse each field and add to SQL statement ##
	my ($WHERE, @query, @bindings);
	foreach my $field (@$order) {
		if (($field eq 'AND') || ($field eq 'OR') || ($field eq '(') || $field eq ')') {
			next if (($field =~ /^(?:AND|OR)$/o) && (!@query || ($query[$#query] =~ /^(?:AND|OR)$/o)));
			next if (($field =~ /^(?:\(|\))$/o) && ($query[$#query] =~ /^(?:\(|\))$/o));
			push @query, $field;
			next;
		}
		## make sure field is in params ##
		unless (defined $class->deffields->{$field}) {
			pop @query;
			next;
		}
		## enforce precedence ##
		my $sql = '(';					# ) loathe BBEdit

		my @valuelist = $params->{$field};
		next unless (defined $valuelist[0]);

		## add relation prefix if $r_flag ##
		$field = "${alias}.${field}" if $alias;
		for (my $x = 0; $x <= $#valuelist; $x++) {
			my $value = $valuelist[$x];
			if (ref($value) eq 'ARRAY') {				# IN, BETWEEN, or multiple comparisons
				my ( $type, @values )	= @{ $value };
				if (substr(lc($type), -2) eq 'in') {	# 'IN' or 'NOT IN'
					return $self->error_handler("no bindings passed to format_conditions for type ($type)")
						unless (@values);
					my (@IN_bindings, @IN_sql);
					while (my $value = shift(@values)) {
						if (lc(substr($value, 0, 6)) eq 'select') {
							push (@IN_sql, $value);
							push (@IN_bindings, splice(@values, 0, $#values + 1));	# $/
						} else {
							push (@IN_sql, '?');
							push (@IN_bindings, $value);
						}
					}
					$sql .= "$field " . uc($type) . ' (' . join(', ', @IN_sql) . ')';
					push(@bindings, @IN_bindings);
				} elsif (substr(lc($type), -7) eq 'between') {	# 'BETWEEN' or 'NOT BETWEEN'
					return $self->error_handler("no bindings passed to format_conditions for type ($type)")
						unless (@values);
					$sql .= "$field " . uc($type) . ' ? AND ?';
					push(@bindings, @values[0,1]);
				} else {										# LIST of conditions
					splice (@valuelist, $x+1, 0, @$value);		# appending will push to next iterations
				}
			} elsif ($value =~ /^\/(.+?)\/$/) {					# regex
				$sql .= "$field ~ ?";
				push(@bindings, $1);
			} elsif ($value =~ /^(\d+?)-(\d+?)$/) {				# date or numeric range
				$sql .= "($field > ? AND $field < ?)";
				push(@bindings, $1, $2);
			} elsif ($value eq '&&') {							# AND
				$sql .= ' AND ';
			} elsif ($value eq '||') {							# OR
				$sql .= ' OR ';
																# BEGIN	BBEdit loathing 
			} elsif ($value eq '(')								# Open paren	) loathe BBedit
			{ # loathe BBedit here, too!
				$sql .= '(';									# ) loathe BBedit
			} # loathe BBedit here, too!						# ( loathe BBedit
			  elsif ($value eq ')') {							# Close paren	( loathe BBedit
				$sql .= ')';									# END	BBEdit loathing 
			} elsif (lc($value) =~ /^(?:like|not|is)\s|<|>/) {	# Allow LIKE,NOT,IS,<,>,<=,>= blindly
				if ($value =~ /##/) {
					while ($value =~ s/##(.+?)##/?/o) {
						push(@bindings, $1);
					}
				}
				$sql .= "$field $value";						# can use with embeded SELECT
		### Why do we need this code?  Uncomment if you change the else!
		#	} elsif ($value =~ /^-?(?:\d+?)\.?(?:\d*?)$/) {			# exact match number
		#		$sql .= "$field = ?";
		#		push(@bindings, $value);
		###
			} else {											# exact match lexical
				$sql .= "$field = ?";
				push(@bindings, $value);
			}
		} # END for (multiple values loop)
		## enforce precedence ( ##
		$sql .= ')';

		## add to array to be joined later ##
		push(@query, $sql) if ($sql ne '()');
	} # END foreach (fields loop)

	$WHERE	= 'WHERE ' . join(' ', @query) if (@query);
	warn "$class->format_conditions:\t\"$WHERE\" [@bindings]\n" if ($debug);
	return ($WHERE, @bindings);
} # END sub format_conditions


=head2 AUTOLOAD

=over 4

=item AUTOLOAD

AUTOLOAD method - returns requested field data from object. 
If that requested data has not been cached, it is retrieved from the 
database, cached, and returned.  If data is passed then field value is 
modified in the database and instance data, and value is returned.


=cut
sub AUTOLOAD {
	my $self	= shift;
	ref($self)	|| return $self->error_handler("In ${self}::AUTOLOAD($AUTOLOAD)\n$self is not an object\n\n");
	my $class	= ref($self);

	return if ($AUTOLOAD =~ /::DESTROY$/);
	my $name	= substr($AUTOLOAD, rindex($AUTOLOAD, ':') + 1);	# strip fully-qualified portion
	
	return undef unless ($name);
	if ($self->can( $name )) {					# Accessor method already exists!
		local($AUTOLOAD)	= $AUTOLOAD;		#	This means I was called as SUPER::$name
		$self->_old_school_autoload( @_ );		#	Act like an AUTOLOAD should!
	} else {									# No accessor method
		$class->_create_access_method( $name );	#	Make a fresh one
		$self->$name( @_ );						#	Now call it
	}
} # END sub AUTOLOAD


=begin private_method

	_create_access_method($name)
		- dynamically creates accessor method for method $name
		- called by AUTOLOAD() or import()

=end private_method

=cut
sub _create_access_method {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $name	= shift;
	my $return	= 0;
	return undef unless ($name);
	if ($name eq 'AUTOLOAD') {					# No method constuction, just 
		no strict 'refs';						# make the plain old AUTOLOAD
		if ($class->can('AUTOLOAD')) {
			$return	= $class->can('AUTOLOAD');
			undef *{"${class}::AUTOLOAD"};
		}
		*{"${class}::AUTOLOAD"}	= \&BingoX::Carbon::_old_school_autoload;

	} elsif ($class->can($name)) {				# Already there!
		warn "access method '${class}::$name' already exists" if ($debug);
	} else {									# Let's make a method today! (Excited yet?)
		warn "creating access method '${class}::$name'..." if ($debug);
		eval qq`
			no strict 'refs';
			*{"${class}::$name"}	= sub {
				my \$self	= shift;
				my \$class	= ref(\$self) || return undef;
				if (defined(my \$data = shift)) {
					\$self->modify({$name => \$data})
						|| return \$self->error_handler("In dynamic method $name()\n\tmodify({$name => \$data}) failed\n\n\t");
					\$self->{'$name'} = \$data;
				} elsif (!exists \$self->{'$name'}) {
					map { ('$name' eq \$_) && return \$self->error_handler("In dynamic method $name()\n\tBingoX::Carbon ABUSE!  Object in class $class has no value for primary key $name in instance data!\n\n\t") }
						\@{ \$self->primary_keys };
					my \%params	= map { \$_ => \$self->\$_() } (\@{ \$self->primary_keys });
					my \$aref	= \$self->list_array( \\\%params, ['$name'] );
					\$self->{'$name'} = \$aref->[0]->[0];
				}
				return \$self->{'$name'};
			};
		`;
	}
	return $return;
} # END sub _create_access_method


=begin private_method

	_create_forwarder_method($name)
		- dynamically creates accessor method for method $name
		- called by AUTOLOAD() or import()

=end private_method

=cut
sub _create_forwarder_method {
	my $self	= shift;
	my $class	= ref($self) || $self;
	my $name	= shift;
	my $return	= 0;
	return undef unless ($name);
	if ($name eq 'AUTOLOAD') {		# No method constuction, just
		no strict 'refs';			# make the plain old AUTOLOAD
		if ($class->can('AUTOLOAD')) {
			$return	= $class->can('AUTOLOAD');
			undef *{"${class}::AUTOLOAD"};
		}
		*{"${class}::AUTOLOAD"}	= \&BingoX::Carbon::_old_school_autoload;

	} elsif ($class->can($name)) {	# Already there!
		warn "forwarder method '${class}::$name' already exists" if ($debug);
	} else {						# Let's make a method today! (Excited yet?)
		warn "creating forwarder method '${class}::$name'..." if ($debug);
		eval qq`
			no strict 'refs';
			*{"${class}::$name"}	= sub {
				local(\$AUTOLOAD)	= '$name';
				my \$self	= shift;
				return \$self->_old_school_autoload( \@_ );
			};
		`;
	}
	return $return;
} # END sub _create_forwarder_method


=begin private_method

	_old_school_autoload
		- this is what AUTOLOAD() used to be (this is your father's AUTOLOAD)
		- loading BingoX::Carbon with the ':no_dynmeth' tag will assign 
			$class::AUTOLOAD to this method

=end private_method

=cut
sub _old_school_autoload {
	my $self	= shift;
	ref($self)	|| return $self->error_handler("In " . $self . "::AUTOLOAD()\n$self is not an object\n\n");
	my $class	= ref($self);

	return if ($AUTOLOAD =~ /::DESTROY$/o);
	my $name	= substr($AUTOLOAD, rindex($AUTOLOAD, ':') + 1);	# strip fully-qualified portion 

	## Check to see if valid field name ##
	exists $self->deffields->{ $name }
		|| return $self->error_handler("In AUTOLOAD()\n\tMethod $name not defined in class $class\n\n\t");

	if (defined(my $data = shift)) {			# Data passed -- call modify()
		$self->modify({ $name => $data })
			|| return $self->error_handler("In AUTOLOAD()\n\tmodify({$name => $data}) failed\n\n\t");
	} elsif (!exists $self->{ $name }) {		# No data passed or cached, retrieve from database
		## Check for nasty BingoX::Carbon abuse  ##
		map { ($name eq $_) && return $class->error_handler("In AUTOLOAD()\n\tBingoX::Carbon ABUSE!  Object in class $class has no value for primary key $name in instance data!\n\n\t") }
			@{ $self->primary_keys };
		my %params	= map { $_ => $self->$_() } (@{ $self->primary_keys });
		my $aref	= $self->list_array( \%params, [$name] );
		$self->{$name} = $aref->[0]->[0];
	}
	return $self->{$name};
} # END sub _old_school_autoload

=begin private_method

	_content> ( $content_class, $column, $content )

	Object Method:
		If $content (optional) is passed, the content will either be reomoved 
		or modified in the db. If no content is passed, then the content will 
		be selected from the db.

=end private_method

=cut
sub _content {
	my $self			= shift;
	return undef unless (ref $self);
	my $content_class	= shift; 
	my $content			= shift;
	my $params;
	if (ref($content) eq 'HASH') {
		$params = $content;
		$content = undef;
	} else {
		$params = shift || {};
	}
	my $content_column	= delete $params->{'_column'} || 'content';	# standard content column name
	my $pos_column		= delete $params->{'_pos'} || 'pos'; # standard position column name
	map { $params->{$_} = $self->$_() } @{ $self->primary_keys };
	if (defined $content) {
		my @split_content;
		## splits the content string into 255 char elements into array ##
		unless ($content eq '') {
			my $pos = 0;
			for ($pos = 0; $pos <= length($content); $pos += 255) {
				push(@split_content, substr($content, $pos, 255));
			}
		}
		my $dbh = $self->dbh();
		local $dbh->{'AutoCommit'} = 0;			# BEGIN TRANSACTION
		eval {
			local $dbh->{'RaiseError'} = 1;
			$content_class->rm( $self->dbh, $params ) || die "Could not remove existing content field value " . $dbh->errstr();

			unless ($content eq '') {
				for (0 .. $#split_content) {
					warn "ADDING CONTENT: $content_class => " . $split_content[$_] if ($debug > 2);
					$content_class->new(
											$self->dbh,
											{
												%$params,
												$pos_column		=> $_ + 1,
												$content_column	=> $split_content[$_]
											}
										) || die "Could not add content field value " . $dbh->errstr();
				}
			}
			$self->{ $content_class } = $content;
		};	# END of EVAL

		if ($@) {							# if failure
			$dbh->rollback();
			return $self->error_handler("Failed to add content - $@");		# give error
		}
		return 1;
	} else {
		return join('', map { $_->[0] }
							@{ $content_class->list_array(
									$self->dbh,
									$params,
									[ $content_column ],
									[ $pos_column ]
								) || [ ]
							}
					);
	}
	1;
} # END sub _content


=item C<int_to_bitmap> ( $int )

Returns a 32-bit bit-string which corresponds to the integer $int.

=cut
sub int_to_bitmap {
	unpack ('B32', pack('N', ($_[1] || $_[0])));
} # END sub int_to_bitmap


=item C<bitmap_to_int> ( $bitmap )

Returns an integer that corresponds to the (at most) 32-bit bit-string $bitmap.

=cut
sub bitmap_to_int {
	unpack ('N', pack('B32', substr("0" x 32 . ($_[1] || $_[0]), -32)));
} # END sub bitmap_to_int

=item C<get_list_hash> (  )

=item C<get_list_hash> ( [ $dbh ] [, \%params ] )

If used as a static method then you must pass $dbh.

Returns a hash ref of all the objects in the class it was called against.  
The hash is built from the C<cpkey>, and the C<title_field>, substr()'d to 
the C<title_size> or by default 80 chars.


B<OPTIMIZE>

=cut
sub get_list_hash {
	my $self 	= shift;
	my $class 	= ref($self) || $self;
	my $dbh		= ref($self) ? $self->dbh : shift;
	ref($dbh) || return $self->error_handler('BingoX::Carbon::stream_obj called without dbh object');
	my $params	= shift || { };


	my $title_size	= $class->title_size || 80;
	my $title_field	= $class->title_field;
	my $fields		= $class->primary_keys;
	my $sort		= [ ];
	unless ($class->content_fields->{ $title_field }) {
		push(@$fields, $title_field);
		$sort		= [ $title_field ];
	}

	my $stream		= $class->stream_obj(
								$dbh,
								$params,
								$fields,
								$sort
					);

	my $hash = { };
	while (my $obj = $stream->()) {
		$hash->{ $obj->cpkey }
					= length($obj->$title_field()) > $title_size
					? substr($obj->$title_field(), 0, ($title_size - 3)) . '...'
					: $obj->$title_field();
	}

	warn Data::Dumper::Dumper( $hash ) if ($debug > 2);
	return $hash;
} # END sub get_list_hash


=begin private_method

initializes content methods

=end private_method

=cut
sub _content_meth_init {
	my $class			= shift;
	my $contentfields	= shift || $class->contentfields;
	foreach my $field (keys %$contentfields) {
		next if $class->can($field);
		## CREATE DYNAMIC ACCESS METHOD ##
		no strict 'refs';
		*{"${class}::$field"} =
			sub {
					my $self = shift;
					return undef unless (ref $self);
					warn "CONTENT: $field => '" . $_[0] . "'" if ($debug);
					$self->_content( $contentfields->{ $field }, @_ );
				};
	}
} # END sub _content_meth_init


=begin private_method

initializes date methods.  Makes a lot of assumptions.  The main date 
format is in Sybase.  If not it assumes that the date format is in a 
string format as that of strftime.

=end private_method

=cut
sub _date_meth_init {
	my $class			= shift;
	if (my $datefields	= $class->datefields) {
		foreach my $field (keys %$datefields) {
			next if $class->can($field);
			## CREATE DYNAMIC ACCESS METHOD ##
			eval qq`
				package $class;
				\*{ $field } =
					sub {
							my \$self = shift;
							return undef unless ref(\$self);
							my \$data = shift;
							my \$date;
							if (ref \$data) {
								\$date = \$data;
							} else {
								\$date = BingoX::Time->new( \$data );
							}

							if (defined \$data) {
								\$self->modify({ $field => \$date->time2str( \$self->date_format ) });
							} else {
								my \$meth	= "SUPER::$field";
								my \$value	= \$self->\$meth();
								my \$time_local = \$self->str2time( \$value );
								\$date = (\$value ? BingoX::Time->new( \$time_local ) : undef);
							}

							return \$date;
						}; # END sub
			`;
		}
	}
} # END sub _date_meth_init


package BingoX::Carbon::Stream;

# Objects are constructed in the BingoX::Carbon::stream_obj method above.
sub next {
	my $self	= shift;
	return $self->();
} # END sub next

sub close {
	my $self	= shift;
	return $self->(1);
} # END sub close


1;

__END__

=back

=head1 REVISION HISTORY

 $Log: Carbon.pm,v $
 Revision 2.36  2001/12/20 19:22:38  gefilte
 error() - fixes dumb mistake (see the diff and you'll understand :-)

 format_conditions()
 	- changed some RE parens into non-capturing (for efficiency)
 	- changed "Allow LIKE,NOT,IS" case to bind on "\s". This prevents values beginning with those letters from matching unless they are the "real deal".
 	(Maybe we should add a '= $value' case in case we want to match something that actually does begin with said words.  For now, avoid them :-)

 	"Do you think we should have cut this scene?"
 		- Bad, nasty, evil, naughty Zoot of the Castle Anthrax

 Revision 2.35  2001/09/20 21:01:38  gefilte
 new() - fixed bug in %datefields processing code which caused insert to fail
 		(bug introduced in rev 2.32)

 Revision 2.34  2000/12/12 19:05:00  gefilte
 new(), modify() - fixed incorrect usage of cpkey(), which caused relational code to fail.

 Revision 2.33  2000/12/12 18:49:36  useevil
  - removed $pkey from cpkey, because its not used
  - updated version for new release:  1.92

 Revision 2.32  2000/11/15 19:33:09  useevil
  - new(), modify(), and _date_meth_init() now calls time2str() instead
    of stringifying the object, and date_format() now works

 Revision 2.31  2000/09/26 21:17:38  zhobson
 Fixed bugs in connectdb() and dataclass() that conspired to prevent projects from
 specifying a connectarray in their own namespace (like @Foo::Data::connectarray)

 Revision 2.30  2000/09/20 20:48:27  dweimer
 Doh! fixed some typo's

 Revision 2.29  2000/09/20 20:46:14  dweimer
 Merged David's changes.
 His comments:
 Cleaned up some debugging code.  All stray carp() calls now call error_handler().  error_handler() itself cleaned up.

 Revision 2.28  2000/09/19 23:49:38  dweimer
 content() - no longer converts linebreaks into HTML break tags (must have seemed useful at the time...)
 Changed error_handler so that it clucks if debug is > 2.

 Revision 2.27  2000/09/19 23:42:42  dweimer
 Version update 1.91

 Revision 2.26  2000/09/13 18:16:00  david
 new(), modify()
 	- now only open a transaction if necessary (multiple statements required)

 RATIONALE - This will allow you to use a new() or modify() call when you have an active stream open, so long as the new() or modify() call does not require changes made to a relationship or to a content_field.

 Revision 2.25  2000/09/13 02:21:32  david
 Some minor POD changes
 Now only requires Data::Dumper if $debug is on.
 new(), modify(), rm(), _content()
 	- Made all database transaction code more conventional (in the perl/DBI sense.)
 modify()
 	- static method mode now works again (broken by Carbonium code in rev. 2.1)
 	- will now return an error if you attempt to use statically to change contentfields or relationships
 	- no longer truncates trailing spaces (if you want to do that, do it yourself!)

 Revision 2.24  2000/09/08 03:08:15  adam
  - added cpkey_params method
  - changed cpkey (removed wantarray stuf)

 Revision 2.23  2000/09/07 20:00:58  thai
  - updated POD documentation to show all REQUIRED classes

 Revision 2.22  2000/09/07 19:57:29  thai
  - added data_class_name()
  - changed DateTime::Date usage to BingoX::Time

 Revision 2.21  2000/09/06 23:18:02  greg
 removed old POD, and make new POD more coherent and descriptive.

 Revision 2.20  2000/09/02 00:15:17  thai
  - fixed POD documentation for date_format()

 Revision 2.19  2000/09/01 23:26:30  thai
  - added:
     date_format() - the date format you want returned from the date object
 	str2time() - used to parse date from the database

 Revision 2.18  2000/08/31 22:53:12  greg
 added COPYING and MANIFEST files

 Revision 2.17  2000/08/31 21:54:18  greg
 Added COPYRIGHT information.
 Added file COPYING (LGPL).
 Cleaned up POD.
 Moved into BingoX namespace.
 References to Bingo::XPP now point to Apache::XPP.

 "To the first approximation, syntactic sugar is trivial to implement.
  To the second approximation, the first approximation is totally bogus."
 	-Larry Wall

 Revision 2.16  2000/08/10 21:08:41  thai
  - changed get_list_hash() to work a lot better
  - changed cpkey() to use wantarray and $cpkey for when you want only the
    primary keys
  - changed occurrances where you split the $cpkey to use $self->cpkey( $cpkey )

 Revision 2.15  2000/08/09 21:24:34  thai
  - added title_size()

 Revision 2.14  2000/08/07 23:08:41  thai
  - will return content fields with <BR> for (\r\n)|[\n\r]

 Revision 2.13  2000/08/07 17:58:30  thai
  - fixed bug in _content() where it tried to deference an undefined
    array ref

 Revision 2.12  2000/08/03 20:45:15  thai
  - addd pkd() method to handle the pkds

 Revision 2.11  2000/07/14 19:12:25  dougw
 Should fix the datefields and contentfields error. They were returning an arrayref and the meth_inits tried
 to dereference it as a hash. DOH!

 Revision 2.10  2000/07/13 22:12:44  thai
  - changed methods so they are more consistent
      deffields() is now def_fields()
 	 fieldorder() is now field_order()
 	 contentfields() is now content_fields()
 	 datefields() is now date_fields()
 	 dataclass() is now data_class()
    of course the other methods still work, but please use the new ones

 Revision 2.9  2000/07/12 19:29:02  thai
  - fixed POD, cleaned up code

 Revision 2.8  2000/07/11 01:18:40  zack
 removed explicit reference to Datatime::Date::Sybase from _date_meth_init()

 Revision 2.7  2000/07/11 00:05:39  zack
 in cached_dbh(), only use Apache->register_cleanup() if mod_perl
 is running

 Revision 2.6  2000/07/10 22:39:16  zack
 - added the ability to provide a selection to get_list_hash()

 Revision 2.5  2000/07/07 01:34:54  dougw
  - Took out Caching for _content methods until we decide on a method to 
    cache them other than just class name.

 Revision 2.4  2000/06/24 03:17:56  dougw
  - Modified _content to handle param passing when updating and retrieving 
    a content field. Made sure content_meth_init and date_meth_init check 
    to see if a method exists before mucking with other namespaces

 Revision 2.3  2000/05/31 02:39:20  greg
 changed use of s/.*:// to substr(...) in AUTOLOAD for efficiency.

 Revision 2.2  2000/05/24 20:45:11  thai
  - tried to weed out as much of the DateTime::Date::Sybase code as
    possible.  Still uses DateTime::Date, and only DateTime::Date::Sybase
    in _date_meth_init()

 Revision 2.1  2000/05/19 01:24:42  thai
  - cleaned up code
  - is now part of the Bingo user space
  - added code from Carbonium

 Revision 2.0  2000/05/02 00:54:33  thai
  - committed as 2.0

 Revision 1.58  2000/03/17 19:01:36  colin
 - changed format_conditions() so that it allows "IS " statements to work 
   (was formerly only matching "IS NOT" statements)

 Revision 1.57  2000/03/09 02:01:07  dougw
 Allows nulled numerics and values.
 Changed the push lines in &new and &modify to allow above.

 Revision 1.56  2000/03/08 23:24:36  zack
 Facilitated NULL updates

 Revision 1.55  2000/02/10 20:05:11  greg
 memory saver - now creates forwarder methods instead of full dynamic methods

 Revision 1.54  2000/02/10 08:56:40  greg
 lots of new TODO and TO BE INVESTIGATED items to think about or implement...

 Revision 1.53  2000/02/10 07:24:24  greg
 now doesn't pass empty string column names in sql to DBI...

 Revision 1.52  1999/12/30 04:40:18  thai
  - bug in format_conditions where if the param field was
    not in deffields, then it would "next" leaving behind
    the remnants of the joined condition "AND" or "OR"
    I pop'd the @query array to eliminate that

 Revision 1.51  1999/12/29 01:44:53  david
 More documentation improvements and additions.
 Fixed format_conditions() so BBEdit balances tags correctly. (loathe BBedit :-)

 Revision 1.50  1999/12/28 22:38:10  david
 new() now makes identity/sequence decisions based on actual driver type of $dbh.
 Better documentation of new().

 Revision 1.49  1999/11/21 02:19:24  adam
  - format_conditions() - you can now use 'is not' as well as 'not'

 Revision 1.48  1999/11/10 23:27:59  greg
 Cleaned up documentation and code. Documentation and debugging information
 now more accurately reflects what is actually happening in Carbon.

 Revision 1.47  1999/10/28 05:52:25  david
 AUTOLOAD(), _create_access_method(), _old_school_autoload()
 	- revised accessor code for efficiency (made an 8% improvement!)
 	- added private POD and lots of other useful comments

 I've wanted to do this for awhile...just never got around to it until now.

 Revision 1.46  1999/10/22 21:11:25  thai
  - fixed some typos in the warns and POD.

 Revision 1.45  1999/10/08 21:51:53  derek
 Fixed an error with over-sanitization in format_contditions.

 Revision 1.44  1999/10/08 21:01:48  david
 Merged 'oracle' branch (excluding r1.36.2.5-r1.36.2.7, merged previously 
 into r1.41), adding Oracle support to Carbon, as well as some other 
 improvements (listed below in revision history.)

 Oracle support in sql_select() still needs refining.

 Revision 1.36.2.8  1999/10/01 09:19:38  david
 Removed silly ($primary_keys >= 2) condition from new().
 	(If you don't know what it is, you probably don't care.)

 format_conditions() - added means to specify order and logic of parameters
 	(NEEDS DOCUMENTATION)

 _create_access_method() - changed warning of $AUTOLOAD to $name

 Revision 1.36.2.4  1999/09/21 21:45:05  colin
 Dave changed part of sql_select back so it works now. Huzzah!

 Revision 1.36.2.3  1999/09/21 19:46:30  colin
 changed format_select(): the actuall select statement use lowercase SQL 
 commands because uppercase ones don't work on views :P

 Revision 1.36.2.2  1999/09/21 18:49:57  david
 sql_select() - Minor fix to Oracleizing code -- now works for columns not in fieldorder.

 Revision 1.36.2.1  1999/09/10 07:46:51  david
 INITIAL ORACLE SUPPORT
 	Added seqcol() and sequence() class variables and corresponding static methods
 		$seqcol   - name of column which sequence applies to (like $identity)
 		$sequence - name of sequence object in the database
 	new() - will use nextval of $sequence to populate $seqcol (if no data supplied for that column)
 	- removed $DATABASE::database kluge (Sybase seems to need it -- don't forget!)
 	sql_select() - creates different closure for Oracle which does case matching
 		(Oracle columns return uppercase and are case-insensitive, Carbon is case-sensitive.)
 Tested
 	new() - seems to work as expected with sequences or without
 	modify() - works correctly as object method, as well as through accessor methods
 	rm() - works as object method
 	accessor methods - work
 To do :
 	test modify() and rm() in static form
 	test relationships
 	document changes to new() in POD

 I imagine most everything should work, since the change was made at sql_select() 
 -- the main point of database read access.  All methods which write to the database 
    should work normally, since Oracle is case-insensitive.  Still, more testing 
    should be done.

 Furthermore, the algorithm I used to make sql_select() work is slow, and can probably 
 be greatly improved.  Still, it's a start, and should preserve our API functionality.

 Revision 1.43  1999/10/08 01:13:29  david
 rm() (static) - sanity prevents you from removing entire table if params is empty
 Restructured stream/list_related :
 	_related() broken into _related_conditions() and _related_subquery_conditions()
 	stream_related() now calls sql_select() using result of related_conditions()
 	list_related() now calls stream_related() (like list_obj() calls stream_obj()

 unrelate() - now uses list_obj() instead of stream_obj() to get objects to unrelate
 	(this may bite us later, but for now it makes unrelate() "transaction-friendly")

 unrelate_all() - new method will unrelate all objects of a named class from an object
 	(uses new _related_subquery_conditions() to form its parameters to call rm() with)

 	"Think it'll work?"
 	"It'll take a miracle..."

 Revision 1.42  1999/10/07 23:39:02  greg
 fixed sql BETWEEN syntax

 Revision 1.41  1999/09/29 20:52:03  david
 Merged in changes from r1.36.2.5 through r1.36.2.7 :
 Support for multiple conditions/field in SELECTs.

 Revision 1.36.2.7  1999/09/29 00:27:46  david
 Removed spurious warn left behind in last commit.

 "Do as I say, not as I do."

 Revision 1.36.2.6  1999/09/28 23:08:31  david
 format_conditions() - added support for multiple conditions/field

 Revision 1.36.2.5  1999/09/24 00:48:19  david
 Fixed bug in format_conditions() - it didn't let you have a condition value of 0.

 Revision 1.40  1999/09/28 00:39:25  greg
  - Added blesses, and class Carbon::Stream to support streams as objects - this isn't 
    heavily test yet.
  - Changed cmps (ref($stream) eq 'CODE') to (ref($stream)) to support new stream class.
  - Lots of other small bug fixes.

 Revision 1.39  1999/09/25 21:31:16  david
 table() - no longer prepends table names with the value of $DATABASE::database

 Revision 1.38  1999/09/25 20:14:39  david
 modify() - added [@wherevals] bind information to debugging output
 format_conditions() - bug fix : did not allow conditions with 0 values
 **************************************************************************
 sql_select() - REMOVED CALL TO DBI->TRACE.
 		PEPPLER FIXED DBD::Sybase "Bind Placeholder" BUG
 **************************************************************************
 Just be nice to people, and they do nice things for you. :-)

 Revision 1.37  1999/09/10 07:41:38  david
 Bug fix :
 	The first time you called an accessor method and AUTOLOAD() creates a dynamic 
 	method, if you called it with content (i.e., to modify the object attribute) 
 	that content would not be forwarded to the new accessor method by AUTOLOAD().  
 	This is now fixed.

 (See the diff? Real tiny fix. :-)

 Revision 1.36  1999/09/10 03:22:22  david
 Bug Fixes
 	new() - can now insert a NULL into a non-IDENTITY primary key column which has 
 	        a default (sort of kludgy -- basically it allows this if there are multiple 
 	        primary keys.
 		    the SELECT MAX() thing should probably go the way of the Dodoe.)
 	- changed default sort parameters (ORDER BY) to primary_keys() instead of fieldorder()
 		(Many people have complained about this.  let me know if you disagree with it.)
 Miscellanea
 	- Changed all calls for DBI::errstr to $dbh->errstr or $sth->errstr
 	modify() - changed @update_values to @update_fields, and @values to @update_values
 		(basically, this just uses the same naming as new(), for consistency.)
 debugging improvments
 	- AUTOLOAD now reports what it was called as
 	- new(), modify(), and rm() now display which class is calling them
 documentation
 	- updated KNOWN BUGS section, added TO DO LIST section

    "We don't code bugs here!"

 Revision 1.35  1999/07/14 23:43:22  david
 Changed relations() method to not return %foreign_keys ref
 Added foreign_keys() method to replace functionality of relations() method
 Changed calls to relations() which should be calls to foreign_keys()

 Revision 1.34  1999/07/13 23:10:20  greg
 Added method _old_school_autoload so calling $obj->SUPER::method() works with
 dynamic methods. _create_access_method sets *Carbon::AUTOLOAD to
 \&_old_school_autoload when called with 'AUTOLOAD' (so as not to duplicate
 code).

 Revision 1.33  1999/07/02 03:36:27  david
 Changed a bunch of 'carp()' calls to $self->error_handler

 get() - fixed weird bug where extra arguments were forwarded to closure, signaling 
         termination of embedded $sth

 format_relations/conditions()
     - no longer require $dbh be first parameter (though it will still work)
     - commented out useless code to determine i f value is numeric
         (this was a throwback to our pre-placeholder-binding days)

 Unary relation fixes :
 _related()
     - renamed from related()
     - fixed unary relations for *_related methods()
     - added $unary_rev_flag to reverse unary operations (needs POD!)
 relate/unrelate()
     - fixed unary relations (reversed operands of grep operation, binaries don't care!)

 Unary relationships now work as undocumented.  That is, they work the way we 
 discussed they would work.  But they still need to be documented! ;=}

 Revision 1.32  1999/07/01 18:59:03  greg
 Made changes to modify to add sanity, and efficiency.

 Revision 1.31  1999/07/01 02:22:11  david
 mget() - extra 'my $params = shift;' caused wildly unpredictable results...

 BAD, NASTY, EVIL DARTH GREG BUG!

 Revision 1.30  1999/06/30 00:53:22  greg
 fixed bugs that were found when integrating with Conf with this version of Carbon.
 added workaround for sybase losing track of the current database - needs to be fixed.

 Revision 1.29  1999/06/25 22:23:42  david
 - Some minor POD corrections
 new()
     - Started changing new() to support inserting into identity fields (not finished)
     - Added minor debugging
 sanity - changed most verifications of (ref $params) to (ref $params eq 'HASH')
 get() - cleans up coderef before exiting
 modify() - added static method usage
 rm() - added static method usage
 - unanchored /##(.+?)##/ regular expression in modify() and format_conditions() 
   (so they will actually work)
 list/stream_obj() - adds primary_keys to \@fields if excluded

 Revision 1.28  1999/06/23 22:42:00  greg
 -import: Removed silliness; now you can pass options to classes that inherit
   from Carbon
 -format_contitions: now bindings in 'IN' are passes as an array and not an
   array ref
 -related: took advantage of new syntax for format_conditions
 -get_relation_into: added sanity and warnings

 Revision 1.27  1999/06/22 23:19:59  greg
 - submit: added sanity
 - rm: now removes hash data before undefining reference to object
 - format_conditions: added better support for 'IN' and 'BETWEEN'
 Rewrote relation methods relate and unrelate. Added list_related,
 stream_related, and isrelated based on the get_relation_info and
 related methods

 Revision 1.26  1999/06/15 18:41:31  greg
 import: changed to recognize all options starting with ':' as options,
 	all others as methods. Added ':no_dynmeth' as import option to
 	specify methods should not be generated dynamically, but left to
 	AUTOLOAD
 Changed method AUTOLOAD, and added method _create_access_method to
 	generate dynamic methods

 Revision 1.25  1999/06/11 19:29:09  greg
 Fixed cache_all option that broke with the introduction of the list_* and
 stream_* methods.

 Revision 1.24  1999/06/10 23:03:45  greg
 Added space to SQL statements using WHERE blocks returned by format_conditions.

 Revision 1.23  1999/06/10 21:13:13  greg
 Changed $Carbon::VERSION variable to contain the CVS revision number
 import - changed to use a class variable to control cache_all functionality
 new - Added sanity
 get/mget - changed to wrapper methods around the list_obj method
 _format_conditions - changed to public method format_conditions
 list - changed to wrapper method around list_obj and list_hash methods
 deffields - changed to construct a hash from the class fieldorder
 sql_select - Returns a coderef to stream hash data (no longer blesses objects)
 format_select - new method to construct and return a complete SELECT statement

 Added methods stream_obj, stream_hash, stream_array, list_obj, list_hash, list_array
 Removed scrolling_list, chop_blanks, escape
 Cleaned up code. Removed lots of warn statements.
 Updated POD to reflect new and changed methods.

 --
 "There is no conspiracy. Nobody is in charge. It's a headless blunder
 operating under the illusion of a master plan."    --Worth (Cube)

 Revision 1.22  1999/06/09 23:26:41  thai
  - moved the revision logs to the bottom.

 Revision 1.21  1999/05/08 20:16:23  adam
  - sql_select - added sanity to ensure that all retrieved objects have 
    primary keys.  Otherwise it creates bad objects.  It only does this 
    if there's no $nobless flag.  Added comments around it.
  - There may be a better way of checking.  Probably before the select.
  - identity - podified identity method.
  - AUTOLOAD - commented autoload sanity ensuring that the primary key 
    isn't autoloaded.  Maybe theres a better way to do this, like checking 
    right when you enter autoload. The object should always have a primary key.
  - new - updated pod to account for identity field.

 Revision 1.20  1999/05/07 22:25:46  greg
  - import - Added ability to specify caching of all data at object construction
             at time of require. To cache all data: use Carbon qw(cache_all);
             This will redefine the mget function from where objects are gotten
             (also from get, although get is just a convenient wrapper around mget)

 Revision 1.19  1999/05/07 16:47:37  greg
  - Changed names of variables set by return values of _format_conditions 
    to make more sense.
  - Added a bit of sanity to what _format_conditions does when something 
    isn't quite right.

 Revision 1.18  1999/05/06 22:30:13  adam
  - new() - Now properly handles identities.  It now puts the insert and 
    select @@identity in the same prepare to ensure it is getting the 
    correct identity value.

 Revision 1.17  1999/05/06 06:30:55  adam
  - Handles identity columns.
  - Changed new to look for identity information in class and use it 
    if it can.
  - Added identity method which looks for $identity in the class.
  - Split up insert statement in new to work with inserts of just the 
    identity field.

 Revision 1.16  1999/05/05 06:32:59  adam
  - Added if debug.

 Revision 1.15  1999/05/05 05:56:38  adam
  - Added if ($debug);

 Revision 1.14  1999/05/03 17:11:45  fred
  - added a line to chop_blancs to unescape single quotes.

 Revision 1.13  1999/04/30 00:56:49  thai
  - added more verbage to AUTOLOAD to explain how it returns $obj->name if
    its not already cached.
  - made a change in _format_conditions; ($value =~ /LIKE|NOT|IN|<|>/) to
    ($value =~ /^(LIKE|NOT|IN|<|>)/)

 Revision 1.12  1999/04/29 20:39:22  thai
  - removed $dbh = shift, because it doesn't need it.

 Revision 1.11  1999/04/15 19:44:56  greg
  - Silly me ;) New should return $self, not $dbh <G>

 Revision 1.10  1999/04/15 19:34:13  greg
  - Changed the instance data method dbh uses from 'dbh' to '_dbh'. Changed method
  - new to add dbh to the instance data.

 Revision 1.9  1999/04/13 17:04:37  thai
  - removed $fields->[1] from list(), so that it now returns only an array
    ref of hashes or objs.
  - removed $name from AUTOLOAD at (@{ $self->primary_keys }), causing infinite
    loops.

 Revision 1.8  1999/04/10 20:17:09  adam
  - AUTOLOAD - changed if (defined... to if (exists...

 Revision 1.7  1999/04/10 00:34:10  colin
  - new - changed the select max bit so that if there are no records, it makes it 1.

 Revision 1.6  1999/04/09 22:55:02  greg
  - Tiny work around in case primary_keys doesn't return an array ref.

 Revision 1.5  1999/04/09 22:41:58  greg
  - Added more POD. Removed duplicate primary_keys method.

 Revision 1.4  1999/04/09 20:21:29  greg
  - Removed some debugging information, and turned off all debugging.

 Revision 1.3  1999/04/09 20:10:54  greg
  - Ton of new changes. Multiple primary keys, multiple database support, relations.
  - This was rushed a little, so there may be bugs...

 Revision 1.2  1999/03/12 23:56:40  thai
  - added DBI->trace to modify().

 Revision 1.38  1999/03/12 22:16:36  thai
  - added cvs headers.


=head1 SEE ALSO

perl(1).

=head1 KNOWN BUGS

new() currently does not report failure if inserting with Sybase IDENTITY columns 
fails, because of an anomoly in the way DBI handles multiple result sets.  You can 
tell if a new() has failed if the value of the IDENTITY column is < 1.

=head1 TODO

=over 4

=item * REWRITE RELATIONAL CODE!!!

=item * ability to redirect debugging to a file instead of STDERR

=item * write test suite testing ALL documented carbon features

=item * document unary many-many relationships

(works, presently undocumented)

=item * one-many relationships

=item * multirow inserts (multinew?)

=back

=head1 TO BE INVESTIGATED

=over 4

=item * carbon profiling

carbon could use it's own debugging information to profile projects, and
generate statistics based on that information. it could optionally store
the profiling data to a sepearte table for later perusing... fields to
store would be global incremented unique number with PID, action (select,
modify, etc), sql statement, timestamp.

=item * join class

dynamically create a class based on a join between carbon classes.
class data from all joined classes would need to be stored to be able to modify data.

=item * read only objects (useful in view objects)

=item * view classes

store class data in such a way that modifying through the view wouldn't break
(one table at a time, or store info on how to modify the actual carbon class for the 
view tables).

=item * virtual classes

get rid of empty classes! carbon has worked to well, and there are far 
to many empty classes lying around. either generate classes at compile 
time, or pretending that the classes exist at run time (using some sort 
of Carbon object ($carbon->class->method). Using a carbon object would 
need to fill in class @ISA arrays so that calls to the class
could be caught.

=item * Change class data to be more flexible - containing meta data

=back

=head1 COPYRIGHT

    Copyright (c) 2000, Cnation Inc. All Rights Reserved. This module is free
    software. It may be used, redistributed and/or modified under the terms
    of the GNU Lesser General Public License as published by the Free Software
    Foundation.

    You should have received a copy of the GNU Lesser General Public License
    along with this library; if not, write to the Free Software Foundation, Inc.,
    59 Temple Place, Suite 330, Boston, MA  02111-1307  USA

=head1 AUTHORS

 David Pisoni <david@cnation.com>
 Greg Williams <greg@cnation.com>
 Thai Nguyen <thai@cnation.com>

=cut

