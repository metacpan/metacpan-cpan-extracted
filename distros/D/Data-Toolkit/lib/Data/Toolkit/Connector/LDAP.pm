#!/usr/bin/perl -w
#
# Data::Toolkit::Connector::LDAP
#
# Andrew Findlay
# Nov 2006
# andrew.findlay@skills-1st.co.uk
#
# $Id: LDAP.pm 388 2013-08-30 15:19:23Z remotesvn $

package Data::Toolkit::Connector::LDAP;

use strict;
use Carp;
use Clone qw(clone);
use Net::LDAP::Entry;
use Data::Toolkit::Entry;
use Data::Toolkit::Connector;
use Data::Dumper;

our @ISA = ("Data::Toolkit::Connector");

=head1 NAME

Data::Toolkit::Connector::LDAP

=head1 DESCRIPTION

Connector for LDAP directories.

=head1 SYNOPSIS

   $ldapConn = Data::Toolkit::Connector::LDAP->new();

   $ldap = Net::LDAP->new( 'ldap.example.org' ) or die "$@";
   $mesg = $ldap->bind;

   $ldapConn->server( $ldap );

   $ldapConn->add( $entry );

   $hashref = $ldapConn->searchparams( { base => "dc=example,dc=org", scope => "sub" } );
   $hashref = $ldapConn->filterspec( '(sn=Beeblebrox)' );

   $msg = $ldapConn->search();
   $msg = $ldapConn->search( $entry );

   $msg = $ldapConn->delete( $entry );



=head1 DEPENDENCIES

   Carp
   Clone
   Net::LDAP

=cut

########################################################################
# Package globals
########################################################################

use vars qw($VERSION);
$VERSION = '1.0';

# Set this non-zero for debug logging
#
my $debug = 0;

# BODGE / algorithm choice for updating LDAP
my $useLDAPReplace = 1;

########################################################################
# Constructors and destructors
########################################################################

=head1 Constructor

=head2 new

   my $ldapConn = Data::Toolkit::Connector::LDAP->new();

Creates an object of type Data::Toolkit::Connector::LDAP

=cut

sub new {
	my $class = shift;

	my $self = $class->SUPER::new(@_);
	bless ($self, $class);

	carp "Data::Toolkit::Connector::LDAP->new $self" if $debug;
	return $self;
}

sub DESTROY {
	my $self = shift;
	carp "Data::Toolkit::Connector::LDAP Destroying $self" if $debug;
}

########################################################################
# Methods
########################################################################

=head1 Methods

=cut

########################################

=head2 server

Define the LDAP server for the connector to use.
This should be an object of type Net::LDAP

   my $res = $csvConn->server( Net::LDAP->new('ldap.example.org') );

Returns the object that it is passed.

=cut

sub server {
	my $self = shift;
	my $server = shift;

	croak "Data::Toolkit::Connector::LDAP->server expects a parameter" if !$server;
	carp "Data::Toolkit::Connector::LDAP->server $self" if $debug;

	return $self->{server} = $server;
}



########################################

=head2 add

Add an entry to the LDAP directory

   $msg = $ldapConn->add( $entry );

Retruns the Net::LDAP::Message object from the add operation.

The entry I<must> contain attributes as follows:

=over

=item _dn

The DN of the entry to be created (single value)

=item objectClass

A list of objectClasses describing the entry

=back

In addition, the entry must contain all the mandatory attributes for the
selected objectClasses.
The attribute-value pair used as the RDN must be included.

All attributes in the entry whose names do not start with an underscore
will be placed in the LDAP entry.

=cut

sub add {
	my $self = shift;
	my $entry = shift;

	croak "add requires an entry" if !$entry;

	my $dn = $entry->get('_dn');
	# We only want one value here, not an array of them!
	$dn = $dn->[0] if $dn;
	croak "add requires a _dn attribute in the entry" if !$dn;

	my $oc = $entry->get('objectClass');
	croak "add requires an objectClass attribute in the entry" if !$oc;

	carp "Data::Toolkit::Connector::LDAP->add $dn" if $debug;

	my $dirEntry = Net::LDAP::Entry->new;
	confess "Failed to create Net::LDAP::Entry" if !$dirEntry;

	# Set the DN
	$dirEntry->dn($dn);

	# Work through the attributes in the entry, copying to the dirEntry
	# where appropriate
	my @attributes = $entry->attributes();
	while (my $attr = shift @attributes) {
		# Ignore attributes starting with an underscore
		next if $attr =~ /^_/;
		# Add everything else to the LDAP entry if it has a defined value
		my @values = $entry->get($attr);
		print "## Attribute $attr: ", (join ':',@values), "\n" if $debug;
		$dirEntry->add( $attr => \@values) if defined($values[0]);
	}

	# Do the update and return the result
	return $dirEntry->update( $self->{server} );
}


########################################

=head2 delete

Delete an entry from the LDAP directory

   $msg = $ldapConn->delete( $entry );

Retruns the Net::LDAP::Message object from the add operation.

The entry I<must> contain an attribute called _dn containing a single value:
the DN of the LDAP entry that you want to delete.

=cut

sub delete {
	my $self = shift;
	my $entry = shift;

	croak "delete requires an entry" if !$entry;

	my $dn = $entry->get('_dn');
	# We only want one value here, not an array of them!
	$dn = $dn->[0] if $dn;
	croak "delete requires a _dn attribute in the entry" if !$dn;

	carp "Data::Toolkit::Connector::LDAP->delete $dn" if $debug;

	# Do the deletion and return the result
	return $self->{server}->delete( $dn );
}



########################################

=head2 searchparams

Supply or fetch search parameters

   $hashref = $ldapConn->searchparams();
   $hashref = $ldapConn->searchparams( { base => "dc=example,dc=org", scope => "sub" } );

=cut

sub searchparams {
	my $self = shift;
	my $paramhash = shift;

	carp "Data::Toolkit::Connector::LDAP->searchparams $self $paramhash " if $debug;

	# No arg supplied - just return existing setting
	return $self->{searchparams} if (!$paramhash);

	if ((ref $paramhash) ne 'HASH') {
		croak "Data::Toolkit::Connector::LDAP->searchparams expects a hashref argument";
	}

	# Store the parameters and return a pointer to them
	return $self->{searchparams} = clone( $paramhash );
}


########################################

=head2 filterspec

Supply or fetch filterspec

   $hashref = $ldapConn->filterspec();
   $hashref = $ldapConn->filterspec( '(sn=Beeblebrox)' );

=cut

sub filterspec {
	my $self = shift;
	my $filter = shift;

	carp "Data::Toolkit::Connector::LDAP->filterspec $self $filter " if $debug;

	# No arg supplied - just return existing setting
	return $self->{filterspec} if (!$filter);

	# Store the filter and return it
	return $self->{filterspec} = $filter;
}

########################################

=head2 search

Search the LDAP directory.
If an entry is supplied, attributes from it may be used in the search.

   $msg = $ldapConn->search();
   $msg = $ldapConn->search( $entry );

Returns the Net::LDAP::Message object from the search operation.

=cut

sub search {
	my $self = shift;
	my $entry = shift;

	carp "Data::Toolkit::Connector::LDAP->search $self" if $debug;

	# Invalidate the current entry
	$self->{current} = undef;
	$self->{currentLDAP} = undef;

	# Take copy of search params as we need to modify it
	my %searchparams;
	if ($self->{searchparams}) {
		%searchparams = %{ clone( $self->{searchparams} ) };
	}

	# Do we need to generate a search string?
	if ($self->{filterspec}) {
		my $filterspec = $self->{filterspec};
		my $filter = '';
		croak "Data::Toolkit::Connector::LDAP->search needs a filterspec" if !$filterspec;

		# Parameter names are between pairs of % characters
		# so if the search string has at least two left then there is work to be done
		while ($filterspec =~ /%.+%/) {
			croak "Data::Toolkit::Connector::LDAP->search needs an entry to build the filter from" if !$entry;

			my ($left,$name,$right) = ($filterspec =~ /^([^%]*)%([a-zA-Z0-9_]+)%(.*)$/);
			# Everything before the first % gets added to the filter
			$filter .= $left;
			# Look for the attribute in the entry
			my $value = $entry->get($name);
			$value = $value->[0] if $value;
			croak "Data::Toolkit::Connector::LDAP->search cannot find value for '$name' to put in search filter" if !$value;
			# Apply escape convention for LDAP search data
			$value =~ s/\\/\\5c/g;    # Escape backslashes
			$value =~ s/\(/\\28/g;    # Escape (
			$value =~ s/\)/\\29/g;    # Escape )
			$value =~ s/\*/\\2a/g;    # Escape *

			# Place the value in the filter
			$filter .= $value;
			# The remainder of the filterspec goes round again
			$filterspec = $right;
		}
		# Anything left in the filterspec gets appended to the filter
		$filter .= $filterspec;

		# Drop the filter into the local copy of the search params
		$searchparams{filter} = $filter;
	}

	# Do the search and return the result having stashed a copy internally
	return $self->{searchresult} = $self->{server}->search( %searchparams );
}



########################################

=head2 next

Return the next entry from the LDAP search as a Data::Toolkit::Entry object.
Optionally apply a map to the LDAP data.

Updates the "current" entry (see "current" method description below).

   my $entry = $ldapConn->next();
   my $entry = $ldapConn->next( $map );

The result is a Data::Toolkit::Entry object if there is data left to be read,
otherwise it is undef.

=cut

sub next {
	my $self = shift;
	my $map = shift;

	carp "Data::Toolkit::Connector::LDAP->next $self" if $debug;

	# Invalidate the old 'current entry' in case we have to return early
	$self->{current} = undef;

	# Do we have any search results to return?
	return undef if !$self->{searchresult};			# No search results at all!
	return undef if !$self->{searchresult}->count();	# No data left to return

	# Pull out the next LDAP entry
	my $ldapEntry = $self->{searchresult}->shift_entry();
	confess "Expecting to find an entry in LDAP search results!" if !$ldapEntry;

	# Build an entry
	my $entry = Data::Toolkit::Entry->new();

	# Set the DN
	$entry->set( '_dn', [ $ldapEntry->dn() ] );

	# Now step through the LDAP attributes and assign data to attributes in the entry
	my $attrib;
	my @attributes = $ldapEntry->attributes();

	foreach $attrib (@attributes) {
		$entry->set( $attrib, $ldapEntry->get_value( $attrib, asref => 1 ) );
	}

	# Save this as the current entry
	$self->{current} = $entry;
	$self->{currentLDAP} = $ldapEntry;

	# Do we have a map to apply?
	if ($map) {
		return $entry->map($map);
	}

	return $entry;
}


########################################

=head2 current

Return the current entry in the list of search results as a Data::Toolkit::Entry.
The current entry is not defined until the "next" method has been called after a search.
Alternatively the current entry can be set by passing a Net::LDAP::Entry
object to this method.

   $entry = $ldapConn->current();
   $entry = $ldapConn->current( $newEntry );

NOTE: if you intend to modify the returned entry you should clone it first,
as it is a reference to the connector's copy.

=cut

sub current {
	my $self = shift;
	my $newCurrent = shift;

	if ($newCurrent) {
		croak "Data::Toolkit::Connector::LDAP->current expects a Net::LDAP::Entry"
			unless $newCurrent->isa("Net::LDAP::Entry");
		carp "Data::Toolkit::Connector::LDAP->current converting Net::LDAP::Entry" if $debug;

		# Build an entry
		my $entry = Data::Toolkit::Entry->new();

		# Set the DN
		$entry->set( '_dn', [ $newCurrent->dn() ] );

		# Now step through the LDAP attributes and assign data to attributes in the entry
		my $attrib;
		my @attributes = $newCurrent->attributes();

		foreach $attrib (@attributes) {
			$entry->set( $attrib, $newCurrent->get_value( $attrib, asref => 1 ) );
		}

		$self->{current} = $entry;
		$self->{currentLDAP} = $newCurrent;
	}

	if ($debug) {
		my $dn;
		my $setting = '';
		$setting = "setting " if $newCurrent;
		$dn = $self->{current}->get('_dn') if $self->{current};
		carp "Data::Toolkit::Connector::LDAP->current $setting$self DN: $dn";
	}

	return $self->{current};
}


########################################

=head2 update

Update the current LDAP entry using data from a source entry and an optional map.
If no map is supplied, all attributes in the source entry are updated in the LDAP entry.

If a map I<is> supplied then any attribute listed in the map but not in the
source entry will be deleted from the current entry in LDAP.

Returns the Net::LDAP::Message result of the LDAP update operation.

   $msg = $ldapConn->update($sourceEntry);
   $msg = $ldapConn->update($sourceEntry, $updateMap);

=cut

sub update {
	my $self = shift;
	my $source = shift;
	my $map = shift;

	croak "Data::Toolkit::Connector::LDAP->update called without a source entry" if !$source;
	croak "Data::Toolkit::Connector::LDAP->update expects a Data::Toolkit::Entry parameter"
		if !$source->isa('Data::Toolkit::Entry');
	croak "Data::Toolkit::Connector::LDAP->update second parameter should be a Data::Toolkit::Map"
		if ($map and !$map->isa('Data::Toolkit::Map'));

	croak "Data::Toolkit::Connector::LDAP->update called without a valid current entry" if !$self->{current};

	my $dn = $self->{current}->get('_dn');
	$dn = $dn->[0] if $dn;
	carp "Data::Toolkit::Connector::LDAP->update $self DN: $dn" if $debug;

	# Save a copy of the current entry in case the update fails and we need to reset it
	my $currentSave = clone($self->{currentLDAP});

	# Apply the map if we have one
	$source = $source->map($map) if $map;

	# Work out which attributes we are going to deal with
	my @attrlist;
	if ($map) {
		# We have a map so take the list of attributes from that
		# This allows us to delete attributes that are not present in the source entry
		@attrlist = $map->outputs();
	}
	else {
		# No map supplied so we will only update attributes present in the source entry
		# i.e. we will not delete any attributes
		@attrlist = $source->attributes();
	}

	# Step through the list of attributes and compare source with current LDAP entry
	# Keep track of whether we do any actual changes, and avoid passing null change to LDAP
	# (need to synthesise an LDAP result message in that case)
	my $needUpdate = 0;
	foreach my $attr (@attrlist) {
		print "ATTR: $attr\n" if $debug;

		# We know that entry objects store attr lists in sorted order so we can use this
		# to compare them.
		my @sourcelist = $source->get($attr);
		my @currentlist = $self->{current}->get($attr);

		if ($useLDAPReplace) {
			# Delete or replace the whole set of values
			# Often inefficient, but works even if no equality match is defined in the schema

			# Delete attribute if no values are wanted
			if (!defined($sourcelist[0]) and defined($currentlist[0])) {
				print "DELETING $attr\n" if $debug;
				$self->{currentLDAP}->delete( $attr );
				$needUpdate = 1;
			}

			# Replace all values if we have any
			if (defined($sourcelist[0])) {
				# Only replace if different attribute count or list
				# FIXME: this does not honour the attribute comparison rules
				my $joinsource = '';
				my $joincurrent = '';
				$joinsource = (join ',',@sourcelist) if defined($sourcelist[0]);
				$joincurrent = (join ',',@currentlist) if defined($currentlist[0]);
				if ($joinsource ne $joincurrent) {
					print "REPLACING $attr: ", (join ',', @sourcelist), "\n" if $debug;
					$self->{currentLDAP}->replace( $attr => \@sourcelist );
					$needUpdate = 1;
				}
			}
		}
		else {
			# FIXME: if the attribute does not have an equality match defined in the schema
			# then this per-value update scheme will not work.
			# The 'replace' update will work in those cases but it is inefficient when dealing
			# with large numbers of values.
			# Maybe choose based on the size of the 'current' list?
			# Step through the lists comparing values
			my $sourceVal = shift @sourcelist;
			my $currentVal = shift @currentlist;
			while ($sourceVal or $currentVal) {
				# print "CMP $sourceVal $currentVal\n";
				# Simple case
				next if ($source->attrCmp($attr, $sourceVal, $currentVal) == 0);

				# Values differ or one is empty so we need to modify LDAP
				$needUpdate = 1;

				if ($sourceVal) {
					# The source value needs adding
					print "ADD value $sourceVal\n" if $debug;
					$self->{currentLDAP}->add( $attr => $sourceVal );
				}

				if ($currentVal) {
					# The current value needs deleting
					print "DEL value $currentVal\n" if $debug;
					$self->{currentLDAP}->delete( $attr => [ $currentVal ] );
				}
			}
			continue {
				# Get next pair of values
				$sourceVal = shift @sourcelist;
				$currentVal = shift @currentlist;
			}
		}
	}

	if ($needUpdate) {
		# Do the update
		my $msg =  $self->{currentLDAP}->update( $self->{server} );

		# Reset currentLDAP if the update failed
		$self->{currentLDAP} = $currentSave if $msg->is_error();

		# Return the update message
		return $msg;
	}

	# Nasty bodge to construct a success message for an operation that we did not
	# actually do.
	# FIXME: find a better way to do this.
	# FIXME: it must support the $msg->is_error() and $msg->code() methods...
	my $bodge = clone($self->{searchresult});
	$bodge->{parent} = undef;
	$bodge->{resultCode} = 0;
	$bodge->{errorMessage} = 'Success';
	return $bodge;
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
