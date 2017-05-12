#!/usr/bin/perl -w
#
# Data::Toolkit::Connector::DBI
#
# Andrew Findlay
# Dec 2006
# andrew.findlay@skills-1st.co.uk
#
# $Id: DBI.pm 388 2013-08-30 15:19:23Z remotesvn $

package Data::Toolkit::Connector::DBI;

use strict;
use Carp;
use Clone qw(clone);
use DBI;
use Data::Toolkit::Entry;
use Data::Toolkit::Connector;
use Data::Dumper;

our @ISA = ("Data::Toolkit::Connector");

=head1 NAME

Data::Toolkit::Connector::DBI

=head1 DESCRIPTION

Connector for relational databases accessed through Perl's DBI methods

=head1 SYNOPSIS

   $dbiConn = Data::Toolkit::Connector::DBI->new();

   $dbi = DBI->connect( $data_source, $username, $auth, \%attr ) or die "$@";

   $dbiConn->server( $dbi );

   $spec = $dbiConn->filterspec( "SELECT joinkey,name FROM people WHERE joinkey = '%mykey%'" );
   $msg = $dbiConn->search( $entry );
   while ( $entry = $dbiConn->next() ) {
	process $entry.....
   }

   $msg = $dbiConn->search( $entry );
   $entry = $dbiConn->allrows();

   $spec = $dbiConn->addspec( "INSERT INTO people (joinkey,name) VALUES (%mykey%,%myname%)" );
   $dbiConn->add( $entry );

   $spec = $dbiConn->updatespec( "UPDATE people set name = %myname% WHERE joinkey = %mykey%" );
   $dbiConn->update( $entry );

   $spec = $dbiConn->deletespec( "DELETE FROM people WHERE joinkey = %mykey%" );
   $msg = $dbiConn->delete( $entry );

Data::Toolkit::Connector::DBI does not do any commits or rollbacks. If you need
transactions, you should call the DBI commit and rollback methods directly.

Note that all data is supplied via placeholders rather than being interpolated
into the SQL strings. Thus for example, this addspec:

   INSERT INTO people (joinkey,name) VALUES (%mykey%,%myname%)

is translated before passing to the database engine, becoming:

   INSERT INTO people (joinkey,name) VALUES (?,?)

and the actual values of the 'mykey' and 'myname' attributes are passed as parameters.
This avoids all problems with quoting and SQL-injection attacks. It does make some
SELECT statements a bit harder to compose, particularly when you want to use LIKE
to do substring searches. The solution is to use CONCAT():

   SELECT joinkey,sn FROM people WHERE sn LIKE CONCAT(%firstletter%, '%%')

The value of the 'firstletter' attribute will become a parameter when the
select operation is executed.

=head1 Non-SQL databases

Not using SQL? No problem: Data::Toolkit::Connector::DBI does not attempt to
understand the strings that you give it. All it does is attribute-name
substitution, so provided your database query language understands the '?'
placeholder convention it will all work.

=head1 DEPENDENCIES

   Carp
   Clone
   DBI
   DBD::CSV (for testing)

=cut

########################################################################
# Package globals
########################################################################

use vars qw($VERSION);
$VERSION = '1.0';

# Set this non-zero for debug logging
#
my $debug = 0;

########################################################################
# Constructors and destructors
########################################################################

=head1 Constructor

=head2 new

   my $dbiConn = Data::Toolkit::Connector::DBI->new();

Creates an object of type Data::Toolkit::Connector::DBI

=cut

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless ($self, $class);

	carp "Data::Toolkit::Connector::DBI->new $self" if $debug;
	return $self;
}

sub DESTROY {
	my $self = shift;
	carp "Data::Toolkit::Connector::DBI Destroying $self" if $debug;
}

########################################################################
# Methods
########################################################################

=head1 Methods

=cut

########################################

=head2 server

Define the database server for the connector to use.
This should be an object of type DBI

   my $res = $dbiConn->server( DBI->connect($data_source, $username, $auth) );

Returns the object that it is passed.

=cut

sub server {
	my $self = shift;
	my $server = shift;

	croak "Data::Toolkit::Connector::DBI->server expects a parameter" if !$server;
	carp "Data::Toolkit::Connector::DBI->server $self" if $debug;

	return $self->{server} = $server;
}



########################################

=head2 filterspec

Supply or fetch filterspec

   $hashref = $ldapConn->filterspec();
   $hashref = $ldapConn->filterspec( "SELECT key,name FROM people WHERE key = '%mykey'" );

Parameters are indicated thus: %name% - this will result in a '?'-style placeholder in
the SQL statement and the named attribute will be extracted from the supplied entry
by the search() method.

=cut

sub filterspec {
	my $self = shift;
	my $filterspec = shift;

	carp "Data::Toolkit::Connector::DBI->filterspec $self $filterspec " if $debug;

	croak "Data::Toolkit::Connector::DBI->filterspec called before server connection opened" if !$self->{server};

	# No arg supplied - just return existing setting
	return $self->{filterspec} if (!$filterspec);

	# We have a new filterspec so stash it for future reference
	$self->{filterspec} = $filterspec;

	# We need to parse the spec to find the list of args that it calls for.
	# Start by clearing the arglist and filter string
	my $filter = '';
	my @arglist;
	$self->{search_arglist} = \@arglist;

	# Parameter names are between pairs of % characters
	# Where we want a literal '%' it is represented by '%%'
	# so if the search string has at least two '%' left then there is work to be done
	while ($filterspec =~ /%.*%/) {
		my ($left,$name,$right) = ($filterspec =~ /^([^%]*)%([a-zA-Z0-9_]*)%(.*)$/);
		# Everything before the first % gets added to the filter
		$filter .= $left;
		if ($name) {
			# Add the name to the list of attributes needed when the search is performed
			push @arglist, $name;
			# Put the placeholder in the actual filter
			$filter .= '?';
		}
		else {
			# We got '%%' so add a literal '%' to the filter
			$filter .= '%';
		}
		# The remainder of the filterspec goes round again
		$filterspec = $right;
	}
	# Anything left in the filterspec gets appended to the filter
	$filter .= $filterspec;

	# Stash the resulting string and associated list of attributes
	$self->{selectstatement} = $filter;

	# Prepare the statement and stash the statement handle
	$self->{search_sth} = $self->{server}->prepare( $filter );
	croak "Failed to prepare filter '$filter'" if !$self->{search_sth};

	# Return the spec string that we were given
	return $self->{filterspec};
}

########################################

=head2 search

Search the database.
If an entry is supplied, attributes from it may be used in the search.

   $msg = $dbiConn->search();
   $msg = $dbiConn->search( $entry );

Returns the result of the DBI execute() operation.
This will be false if an error occurred.

=cut

sub search {
	my $self = shift;
	my $entry = shift;

	croak "Data::Toolkit::Connector::DBI->search called before searchspec has been defined" if !$self->{search_sth};
	carp "Data::Toolkit::Connector::DBI->search $self" if $debug;

	# Sanity check
	if ($entry and not $entry->isa('Data::Toolkit::Entry')) {
		croak "Data::Toolkit::Connector::DBI->search parameter must be an entry";
	}

	# Invalidate the current result entry
	$self->{current} = undef;
	$self->{currentDBRow} = undef;

	# The args to be passed to the SQL SELECT statement
	my @args;
	# The array of names that came from the filterspec
	my @arglist = @{$self->{search_arglist}};
	# Check that we have an entry to get params from
	print "ARGLIST for search: ", (join '/', @arglist), "\n" if $debug;
	if ($arglist[0] and !$entry) {
		croak "Data::Toolkit::Connector::DBI->search requires an entry when the searchspec includes parameters";
	}

	# Extract the args from the entry
	my $arg;
	foreach $arg (@arglist) {
		my $value = $entry->get($arg);
		croak "search spec calls for a '$arg' attribute but the entry does not have one" if !$value;
		# We only use the first value from the list.
		# This is permitted to bu undef or the null string.
		$value = $value->[0];
		push @args, $value;
	}

	# Start the search and return the statement handle having stashed a copy internally
	return $self->{searchresult} = $self->{search_sth}->execute( @args );
}



########################################

=head2 next

Return the next entry from the SQL search as a Data::Toolkit::Entry object.
Optionally apply a map to the data.

Updates the "current" entry (see "current" method description below).

   my $entry = $dbConn->next();
   my $entry = $dbConn->next( $map );

The result is a Data::Toolkit::Entry object if there is data left to be read,
otherwise it is undef.

=cut

sub next {
	my $self = shift;
	my $map = shift;

	carp "Data::Toolkit::Connector::DBI->next $self" if $debug;

	# Invalidate the old 'current entry' in case we have to return early
	$self->{current} = undef;

	# Sanity check
	croak "Data::Toolkit::Connector::DBI->next called but no search has been started" if !$self->{search_sth};

	# Pull out the next row from the database
	my $dbRow = $self->{search_sth}->fetchrow_hashref("NAME_lc");
	return undef if !$dbRow;

	# Build an entry
	my $entry = Data::Toolkit::Entry->new();

	# Now step through the list of columns and assign data to attributes in the entry
	my $attrib;

	foreach $attrib (keys %$dbRow) {
		$entry->set( $attrib, [ $dbRow->{$attrib} ] );
	}

	# Save this as the current entry
	$self->{current} = $entry;
	$self->{currentRow} = $dbRow;

	carp "Data::Toolkit::Connector::DBI->next using row: ".(join ',', (keys %$dbRow)) if $debug;
	# Do we have a map to apply?
	if ($map) {
		return $entry->map($map);
	}

	return $entry;
}

########################################

=head2 allrows

Merges the data from all rows returned by the SQL search into a single
Data::Toolkit::Entry object, so that each attribute has multiple values.
Optionally apply a map to the data.

After this method if called, the "current" entry will be empty
(see "current" method description below).

   my $entry = $dbConn->allrows();
   my $entry = $dbConn->allrows( $map );

The result is a Data::Toolkit::Entry object if there is data left to be read,
otherwise it is undef.

=cut

sub allrows {
	my $self = shift;
	my $map = shift;

	carp "Data::Toolkit::Connector::DBI->allrows $self" if $debug;

	# Invalidate the old 'current entry' in case we have to return early
	$self->{current} = undef;
	# We will use up all the rows so clear this
	$self->{currentRow} = undef;

	# Sanity check
	croak "Data::Toolkit::Connector::DBI->allrows called but no search has been started" if !$self->{search_sth};

	# Pull out the next row from the database
	my $dbRow = $self->{search_sth}->fetchrow_hashref("NAME_lc");
	return undef if !$dbRow;

	# Build an entry
	my $entry = Data::Toolkit::Entry->new();

	# While the search returns rows of data, slurp them up and add the values to the entry
	my $count = 0;
	while ($dbRow) {
		# Step through the list of columns and add data to attributes in the entry
		my $attrib;
		$count++;

		foreach $attrib (keys %$dbRow) {
			$entry->add( $attrib, [ $dbRow->{$attrib} ] );
		}

		# Fetch the next row
		$dbRow = $self->{search_sth}->fetchrow_hashref("NAME_lc");
	}

	# Save this as the current entry
	$self->{current} = $entry;

	carp "Data::Toolkit::Connector::DBI->allrows found $count rows" if $debug;

	# Do we have a map to apply?
	if ($map) {
		return $entry->map($map);
	}

	return $entry;
}


########################################

=head2 current

Return the current entry in the list of search results.
The current entry is not defined until the "next" method has been called after a search.

   $entry = $dbConn->current();

=cut

sub current {
	my $self = shift;

	carp "Data::Toolkit::Connector::DBI->current $self" if $debug;

	return $self->{current};
}



########################################

=head2 addspec

Supply or fetch spec for add

   $spec = $dbiConn->addspec();
   $spec = $dbiConn->addspec( "INSERT INTO people (joinkey,name) VALUES (%key%, %myname%)" );

Parameters are indicated thus: %name% - this will result in a '?'-style placeholder in
the SQL statement and the named attribute will be extracted from the supplied entry
by the add() method. Note that these parameters should not be quoted - they are not
passed as text to the database engine.

=cut

sub addspec {
	my $self = shift;
	my $addspec = shift;

	carp "Data::Toolkit::Connector::DBI->addspec $self $addspec " if $debug;

	croak "Data::Toolkit::Connector::DBI->addspec called before server connection opened" if !$self->{server};

	# No arg supplied - just return existing setting
	return $self->{addspec} if (!$addspec);

	# We have a new addspec so stash it for future reference
	$self->{addspec} = $addspec;

	# We need to parse the spec to find the list of args that it calls for.
	# Start by clearing the arglist and add string
	my $add = '';
	my @arglist;
	$self->{add_arglist} = \@arglist;

	# Parameter names are between pairs of % characters
	# Where we want a literal '%' it is represented by '%%'
	# so if the add string has at least two '%' left then there is work to be done
	while ($addspec =~ /%.*%/) {
		my ($left,$name,$right) = ($addspec =~ /^([^%]*)%([a-zA-Z0-9_]*)%(.*)$/);
		# Everything before the first % gets added to the add string
		$add .= $left;
		if ($name) {
			# Add the name to the list of attributes needed when the add is performed
			push @arglist, $name;
			# Put the placeholder in the actual add string
			$add .= '?';
		}
		else {
			# We got '%%' so add a literal '%' to the add string
			$add .= '%';
		}
		# The remainder of the addspec goes round again
		$addspec = $right;
	}
	# Anything left in the addspec gets appended to the add string
	$add .= $addspec;

	# Stash the resulting string
	$self->{add_statement} = $add;

	# Prepare the statement and stash the statement handle
	$self->{add_sth} = $self->{server}->prepare( $add );
	croak "Failed to prepare add '$add'" if !$self->{add_sth};

	# Return the spec string that we were given
	return $self->{addspec};
}

########################################

=head2 add

Update a row in the database using data from a source entry and an optional map.
If a map is supplied, it is used to transform data from the source entry before
it is applied to the database operation.

Returns the result of the DBI execute operation.

   $msg = $dbConn->add($sourceEntry);
   $msg = $dbConn->add($sourceEntry, $addMap);

A suitable add operation must have been defined using the addspec() method
before add() is called:

   $spec = $dbiConn->addspec( "INSERT INTO people (joinkey,name) VALUES (%key%, %myname%)" );
   $msg = $dbiConn->add( $entry );

NOTE that only the first value of a given attribute is used, as relational databases expect
a single value for each column in a given row.

=cut

sub add {
	my $self = shift;
	my $source = shift;
	my $map = shift;

	croak "Data::Toolkit::Connector::DBI->add called before addspec has been defined" if !$self->{add_sth};
	croak "Data::Toolkit::Connector::DBI->add first parameter should be a Data::Toolkit::Entry"
		if ($source and !$source->isa('Data::Toolkit::Entry'));
	croak "Data::Toolkit::Connector::DBI->add second parameter should be a Data::Toolkit::Map"
		if ($map and !$map->isa('Data::Toolkit::Map'));

	carp "Data::Toolkit::Connector::DBI->add $self $source" if $debug;

	# Apply the map if we have one
	$source = $source->map($map) if $map;

	# The args to be passed to the SQL UPDATE statement
	my @args;
	# The array of names that came from the addspec
	my @arglist = @{$self->{add_arglist}};
	# Check that we have an entry to get params from
	print "ARGLIST for add: ", (join '/', @arglist), "\n" if $debug;
	if ($arglist[0] and !$source) {
		croak "Data::Toolkit::Connector::DBI->add requires an entry when the addspec includes parameters";
	}

	# Extract the args from the entry
	my $arg;
	foreach $arg (@arglist) {
		my $value = $source->get($arg);
		croak "add spec calls for a '$arg' attribute but the entry does not have one" if !$value;
		# We only use the first value from the list.
		# This is permitted to be undef or the null string.
		$value = $value->[0];
		push @args, $value;
	}

	# Start the operation and return the statement handle having stashed a copy internally
	return $self->{add_result} = $self->{add_sth}->execute( @args );
}


########################################

=head2 updatespec

Supply or fetch spec for update

   $spec = $dbiConn->updatespec();
   $spec = $dbiConn->updatespec( "UPDATE people set name = %myname% WHERE joinkey = %mykey%" );

Parameters are indicated thus: %name% - this will result in a '?'-style placeholder in
the SQL statement and the named attribute will be extracted from the supplied entry
by the update() method.

=cut

sub updatespec {
	my $self = shift;
	my $updatespec = shift;

	carp "Data::Toolkit::Connector::DBI->updatespec $self $updatespec " if $debug;

	croak "Data::Toolkit::Connector::DBI->updatespec called before server connection opened" if !$self->{server};

	# No arg supplied - just return existing setting
	return $self->{updatespec} if (!$updatespec);

	# We have a new updatespec so stash it for future reference
	$self->{updatespec} = $updatespec;

	# We need to parse the spec to find the list of args that it calls for.
	# Start by clearing the arglist and update string
	my $update = '';
	my @arglist;
	$self->{update_arglist} = \@arglist;

	# Parameter names are between pairs of % characters
	# Where we want a literal '%' it is represented by '%%'
	# so if the update string has at least two '%' left then there is work to be done
	while ($updatespec =~ /%.*%/) {
		my ($left,$name,$right) = ($updatespec =~ /^([^%]*)%([a-zA-Z0-9_]*)%(.*)$/);
		# Everything before the first % gets added to the update string
		$update .= $left;
		if ($name) {
			# Add the name to the list of attributes needed when the update is performed
			push @arglist, $name;
			# Put the placeholder in the actual update string
			$update .= '?';
		}
		else {
			# We got '%%' so add a literal '%' to the update string
			$update .= '%';
		}
		# The remainder of the updatespec goes round again
		$updatespec = $right;
	}
	# Anything left in the updatespec gets appended to the update string
	$update .= $updatespec;

	# Stash the resulting string and associated list of attributes
	$self->{update_statement} = $update;

	# Prepare the statement and stash the statement handle
	$self->{update_sth} = $self->{server}->prepare( $update );
	croak "Failed to prepare update '$update'" if !$self->{update_sth};

	carp "Data::Toolkit::Connector::DBI->updatespec setting '$update', (" . (join ',',@arglist) . ")" if $debug;

	# Return the spec string that we were given
	return $self->{updatespec};
}

########################################

=head2 update

Update a row in the database using data from a source entry and an optional map.
If a map is supplied, it is used to transform data from the source entry before
it is applied to the database operation.

Returns the result of the DBI execute operation.

   $msg = $dbConn->update($sourceEntry);
   $msg = $dbConn->update($sourceEntry, $updateMap);

A suitable update operation must have been defined using the updatespec() method
before update() is called:

   $spec = $dbiConn->updatespec( "UPDATE people set name = %myname% WHERE key = %mykey%" );
   $msg = $dbiConn->update( $entry );

NOTE that only the first value of a given attribute is used, as relational databases expect
a single value for each column in a given row.

Note also that multiple rows could be affected by a single call to this method, depending
on how the updatespec has been defined.

=cut

sub update {
	my $self = shift;
	my $source = shift;
	my $map = shift;

	croak "Data::Toolkit::Connector::DBI->update called before updatespec has been defined" if !$self->{update_sth};
	croak "Data::Toolkit::Connector::DBI->update first parameter should be a Data::Toolkit::Entry"
		if ($source and !$source->isa('Data::Toolkit::Entry'));
	croak "Data::Toolkit::Connector::DBI->update second parameter should be a Data::Toolkit::Map"
		if ($map and !$map->isa('Data::Toolkit::Map'));

	carp "Data::Toolkit::Connector::DBI->update $self $source" if $debug;

	# Apply the map if we have one
	$source = $source->map($map) if $map;

	# The args to be passed to the SQL UPDATE statement
	my @args;
	# The array of names that came from the updatespec
	my @arglist = @{$self->{update_arglist}};
	# Check that we have an entry to get params from
	print "ARGLIST for update: ", (join ',', @arglist), "\n" if $debug;
	if ($arglist[0] and !$source) {
		croak "Data::Toolkit::Connector::DBI->update requires an entry when the updatespec includes parameters";
	}

	# Extract the args from the entry
	my $arg;
	foreach $arg (@arglist) {
		my $value = $source->get($arg);
		croak "update spec calls for a '$arg' attribute but the entry does not have one" if !$value;
		# We only use the first value from the list.
		# This is permitted to be the null string.
		# It should not be undef, as that would need an 'IS NULL' clause in SQL.
		$value = $value->[0];
		push @args, $value;
	}

	# Start the search and return the statement handle having stashed a copy internally
	return $self->{update_result} = $self->{update_sth}->execute( @args );
}


########################################

=head2 deletespec

Supply or fetch spec for delete

   $spec = $dbiConn->deletespec();
   $spec = $dbiConn->deletespec( "DELETE from people WHERE joinkey = %mykey%" );

Parameters are indicated thus: %name% - this will result in a '?'-style placeholder in
the SQL statement and the named attribute will be extracted from the supplied entry
by the delete() method.

=cut

sub deletespec {
	my $self = shift;
	my $deletespec = shift;

	carp "Data::Toolkit::Connector::DBI->deletespec $self $deletespec " if $debug;

	croak "Data::Toolkit::Connector::DBI->deletespec called before server connection opened" if !$self->{server};

	# No arg supplied - just return existing setting
	return $self->{deletespec} if (!$deletespec);

	# We have a new deletespec so stash it for future reference
	$self->{deletespec} = $deletespec;

	# We need to parse the spec to find the list of args that it calls for.
	# Start by clearing the arglist and delete string
	my $delete = '';
	my @arglist;
	$self->{delete_arglist} = \@arglist;

	# Parameter names are between pairs of % characters
	# Where we want a literal '%' it is represented by '%%'
	# so if the delete string has at least two '%' left then there is work to be done
	while ($deletespec =~ /%.*%/) {
		my ($left,$name,$right) = ($deletespec =~ /^([^%]*)%([a-zA-Z0-9_]*)%(.*)$/);
		# Everything before the first % gets added to the delete string
		$delete .= $left;
		if ($name) {
			# Add the name to the list of attributes needed when the delete is performed
			push @arglist, $name;
			# Put the placeholder in the actual delete string
			$delete .= '?';
		}
		else {
			# We got '%%' so add a literal '%' to the delete string
			$delete .= '%';
		}
		# The remainder of the deletespec goes round again
		$deletespec = $right;
	}
	# Anything left in the deletespec gets appended to the delete string
	$delete .= $deletespec;

	# Stash the resulting string and associated list of attributes
	$self->{delete_statement} = $delete;

	# Prepare the statement and stash the statement handle
	$self->{delete_sth} = $self->{server}->prepare( $delete );
	croak "Failed to prepare delete '$delete'" if !$self->{delete_sth};

	carp "Data::Toolkit::Connector::DBI->deletespec setting '$delete', (" . (join ',',@arglist) . ")" if $debug;

	# Return the spec string that we were given
	return $self->{deletespec};
}

########################################

=head2 delete

Delete a row from the database using data from a source entry and an optional map.
If a map is supplied, it is used to transform data from the source entry before
it is applied to the database operation.

Returns the result of the DBI execute operation.

   $msg = $dbConn->delete($sourceEntry);
   $msg = $dbConn->delete($sourceEntry, $deleteMap);

A suitable delete operation must have been defined using the deletespec() method
before delete() is called:

   $spec = $dbiConn->deletespec( "DELETE FROM people WHERE joinkey = %mykey%" );
   $msg = $dbiConn->delete( $entry );

NOTE that only the first value of a given attribute is used.

Note also that multiple rows could be affected by a single call to this method, depending
on how the deletespec has been defined.

=cut

sub delete {
	my $self = shift;
	my $source = shift;
	my $map = shift;

	croak "Data::Toolkit::Connector::DBI->delete called before deletespec has been defined" if !$self->{delete_sth};
	croak "Data::Toolkit::Connector::DBI->delete first parameter should be a Data::Toolkit::Entry"
		if ($source and !$source->isa('Data::Toolkit::Entry'));
	croak "Data::Toolkit::Connector::DBI->delete second parameter should be a Data::Toolkit::Map"
		if ($map and !$map->isa('Data::Toolkit::Map'));

	carp "Data::Toolkit::Connector::DBI->delete $self $source" if $debug;

	# Apply the map if we have one
	$source = $source->map($map) if $map;

	# The args to be passed to the SQL UPDATE statement
	my @args;
	# The array of names that came from the deletespec
	my @arglist = @{$self->{delete_arglist}};
	# Check that we have an entry to get params from
	print "ARGLIST for delete: ", (join ',', @arglist), "\n" if $debug;
	if ($arglist[0] and !$source) {
		croak "Data::Toolkit::Connector::DBI->delete requires an entry when the deletespec includes parameters";
	}

	# Extract the args from the entry
	my $arg;
	foreach $arg (@arglist) {
		my $value = $source->get($arg);
		croak "delete spec calls for a '$arg' attribute but the entry does not have one" if !$value;
		# We only use the first value from the list.
		# This is permitted to be the null string.
		# It should not be undef, as that would need an 'IS NULL' clause in SQL.
		$value = $value->[0];
		push @args, $value;
	}

	# Start the search and return the statement handle having stashed a copy internally
	return $self->{delete_result} = $self->{delete_sth}->execute( @args );
}

########################################################################
# Debugging methods
########################################################################

=head1 Debugging methods

=head2 debug

Set and/or get the debug level for Data::Toolkit::Connector

   my $currentDebugLevel = Data::Toolkit::Connector::LDAP->debug();
   my $newDebugLevel = Data::Toolkit::Connector::LDAP->debug(1);

Any non-zero debug level causes the module to print copious debugging information.

Note that this is a package method, not an object method. It should always be
called exactly as shown above.

All debug information is reported using "carp" from the Carp module, so if
you want a full stack backtrace included you can run your program like this:

   perl -MCarp=verbose myProg

=cut

# Class method to set and/or get debug level
#
sub debug {
	my $class = shift;
	if (ref $class)  { croak "Class method 'debug' called as object method" }
	# print "DEBUG: ", (join '/', @_), "\n";
	$debug = shift if (@_ == 1);
	return $debug
}


########################################################################
########################################################################

=head1 Author

Andrew Findlay

Skills 1st Ltd

andrew.findlay@skills-1st.co.uk

http://www.skills-1st.co.uk/

=cut

########################################################################
########################################################################
1;
