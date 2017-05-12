#!/usr/bin/perl -w
#
# Data::Toolkit::Entry
#
# Andrew Findlay
# Nov 2006
# andrew.findlay@skills-1st.co.uk
#
# $Id: Entry.pm 388 2013-08-30 15:19:23Z remotesvn $

package Data::Toolkit::Entry;

use strict;
use Data::MultiValuedHash;
use Data::Dumper;
use Carp;
use Clone qw(clone);

=head1 NAME

Data::Toolkit::Entry

=head1 DESCRIPTION

Data::Toolkit::Entry objects store attribute-value data.
Attributes can have zero or more values.
By default, attribute names are case-insensitive and are always
returned in lower case.

Each attribute can have zero or more values.
The list of values is kept sorted, and by default only one copy of each value
is permitted. The sort order is selectable.

Data::Toolkit::Entry objects are ideal for carrying entries in
directory synchronisation systems and other data-pump applications.

=head1 DEPENDENCIES

   Carp
   Clone
   Data::Dumper
   Data::MultiValuedHash

=head1 SYNOPSIS

   my $entry = Data::Toolkit::Entry->new();

   $count = $entry->set("surname", [ "Findlay" ]);
   $count = $entry->set("cn", [ "Andrew Findlay", "A J Findlay" ]);
   $count = $entry->set("mobile", []);

   $count = $entry->add("newAttribute", [ "Apples" ]);
   $count = $entry->add("newAttribute", [ "Pears", "Oranges" ]);

   $arrayRef = $entry->get("myAttribute");
   print (join ":", $arrayref), "\n";

   $arrayRef = $entry->attributes();

   $result = $entry->attribute_match( 'attribname', ['value1','value2'] );

   $newEntry = $entry->map($thisMap);
   $newEntry = $entry->map($thisMap,$entry2,$entry3,...);

   $result = $entry->delete('thisAttribute','thisValue');

   $result = $entry->delete('thisAttribute');

   my $currentDebugLevel = Data::Toolkit::Entry->debug();
   my $newDebugLevel = Data::Toolkit::Entry(1);

   my $string = $entry->dump();

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

   my $entry = Data::Toolkit::Entry->new();
   my $entry = Data::Toolkit::Entry->new( {configAttrib => value, ....} );

Creates an object of type Data::Toolkit::Entry

Optionally accepts a hash of configuration items chosen from this list:

=over

=item caseSensitiveNames

If this is defined with a true value then attribute names are case-sensitive.
By default they are not, so "Surname", "surname", and "SurName" are all the same attribute.

=item defaultValueComparator

If this is defined its value sets the default method of comparing values
in all attributes. See I<comparator> below for details.

=item defaultUniqueValues

If this is defined its value is the default for each new attribute's
uniqueValues flag.

=back

=cut

sub new {
	my $class = shift;
	my $configParam = shift;

	my $self  = {};

	# Take a copy of the config hash
	# - we don't want to store a ref to the one we were given
	#   in case it is part of another object
	#
	if (defined($configParam)) {
		if ((ref $configParam) ne 'HASH') {
			croak "Data::Toolkit::Entry->new expects a hash ref but was given something else"
		}

		$self->{config} = clone($configParam);
	}
	else {
		# Start with empty config
		$self->{config} = {};
		$self->{config}->{uniqueValues} = {};
		$self->{config}->{comparator} = {};
	}

	# Default value comparison method
	$self->{config}->{defaultValueComparator} = 'caseInsensitive' unless $self->{config}->{defaultValueComparator};

	# Default true for uniqueValues flags
	$self->{config}->{defaultUniqueValues} = 1 unless $self->{config}->{defaultUniqueValues};

	# Attribute names are not case-sensitive by default.
	# Check to see whether this should be changed.
	my $ignoreCase = 1;
	$ignoreCase = 0 if $self->{config}->{caseSensitiveNames};

	# We use Data::MultiValuedHash to handle attribute-value storage
	$self->{data} = Data::MultiValuedHash->new($ignoreCase);

	bless ($self, $class);

	carp "Creating $self" if $debug;
	return $self;
}

sub DESTROY {
	my $self = shift;
	carp "Destroying $self" if $debug;
}

########################################################################
# Methods
########################################################################

=head1 Methods

=cut

########################################

=head2 set

Set the value of an attribute, overriding what was there before.
Creates the attribute if necessary.

Passing an empty list of values creates an empty attribute
(this is different from the attribute not existing at all).

Passing an undef list of values deletes the attribute and returns undef.

   $count = $entry->set("surname", [ "Findlay" ]);
   $count = $entry->set("cn", [ "Andrew Findlay", "A J Findlay" ]);
   $count = $entry->set("mobile", []);

The method returns the number of values that the attribute has, so in the
examples above, $count would be 1, 2, and 0 respectively.

=cut

sub set {
	my $self = shift;
	my $attrib = shift;
	my $values = shift;

	croak "set requires an attribute name" if (!$attrib);

	# Lower-case the attribute name if necessary
	$attrib = "\L$attrib" if (!$self->{config}->{caseSensitiveNames});

	carp "Data::Template::Entry->set attribute '$attrib'" if $debug;

	# Delete any existing values
	$self->{data}->delete($attrib);

	# undefined list?
	return undef if !defined($values);

	croak "Second parameter to Data::Template::Entry->set must be an array" if ((ref $values) ne "ARRAY");

	# Pass the rest of the job to the add method
	return $self->add($attrib, $values);
}


########################################

=head2 add

Add one or more values to an attribute.
Creates the attribute if necessary.

Passing an undef list of values does nothing.

Passing an empty list of values creates an empty attribute
or leaves an existing one unchanged.

   $count = $entry->add("newAttribute", [ "Apples" ]);
   $count = $entry->add("newAttribute", [ "Pears", "Oranges" ]);
   $count = $entry->add("anotherAttribute", []);
   $count = $entry->add("anotherAttribute", undef);

The method returns the number of values that the attribute has after
the add operation has completed. If an undef list is added to a
non-existant attribute then the return will be undef.

=cut

sub add {
	my $self = shift;
	my $attrib = shift;
	my $values = shift;

	croak "add requires an attribute name" if (!$attrib);

	# Lower-case the attribute name if necessary
	$attrib = "\L$attrib" if (!$self->{config}->{caseSensitiveNames});

	carp "Data::Template::Entry->add attribute '$attrib'" if $debug;

	# If we were given an undef value list then
	# we dont want to modify the entry at all.
	#
	return $self->{data}->count($attrib) if !defined($values);

	carp "Data::Template::Entry->add $attrib: " . ref $values if $debug;
	croak "Second parameter to Data::Template::Entry->add must be an array ref" if ((ref $values) ne "ARRAY");

	# Set the comparator type if it has not been done already
	if (!defined($self->{config}->{comparator}->{$attrib})) {
		carp "Data::Template::Entry->add setting attribute '$attrib' default comparator" if $debug;
		$self->{config}->{comparator}->{$attrib} = $self->{config}->{defaultValueComparator};
	}

	# Set the uniqueValues flag if it has not been done already
	if (!defined($self->{config}->{uniqueValues}->{$attrib})) {
		carp "Data::Template::Entry->add setting attribute '$attrib' default uniqueValues flag" if $debug;
		$self->{config}->{uniqueValues}->{$attrib} = $self->{config}->{defaultUniqueValues};
	}

	# If we get this far we should at least create the attribute
	$self->{data}->push($attrib);

	# Add each value from the list
	foreach my $val (@$values) {
		$self->addOne( $attrib, $val );
	}

	# Return the new number of values
	return $self->{data}->count($attrib);
}


########################################

=head2 attrCmp

Compare two values of a specific attribute using the defined comparator for that attribute.
Returns negative, zero, or positive.

   $result = $entry->attrCmp( 'attributename', 'value1', 'value2' );

=cut

sub attrCmp {
	my $self = shift;
	my $attrib = shift;
	my $val1 = shift;
	my $val2 = shift;

	croak "Data::Template::Entry->attrCmp needs an attribute name" if !$attrib;

	# Lower-case the attribute name if necessary
	$attrib = "\L$attrib" if (!$self->{config}->{caseSensitiveNames});

	# Find the comparator for this attribute
	my $comparator = $self->{config}->{comparator}->{$attrib};
	carp "Data::Template::Entry->attrCmp comparator: $comparator" if $debug;

	if ($comparator eq 'caseSensitive') {
		return ($val1 cmp $val2);
	}
	elsif ($comparator eq 'caseInsensitive') {
		return ("\L$val1" cmp "\L$val2");
	}
	elsif ($comparator eq 'integer') {
		return ($val1 <=> $val2);
	}
	elsif ((ref $comparator) eq 'CODE') {
		return (&$comparator($val1, $val2));
	}
	else {
		croak "comparator $comparator not implemented";
	}
}

# Internal method: add one value to an attribute, preserving the sort order and uniqueness
#
sub addOne {
	my $self = shift;
	my $attrib = shift;
	my $value = shift;

	carp "Data::Template::Entry->addOne( $attrib, $value )" if $debug;

	# Get the current list of values
	my @list = $self->{data}->fetch($attrib);

	# Find the uniqueness flag for this attribute
	my $uniq = $self->{config}->{uniqueValues}->{$attrib};
	carp "Data::Template::Entry->addOne uniqueValues: $uniq" if $debug;

	# Work out where to put our new one
	my $splicePosition = 0;
	while (defined(my $thisVal = $list[$splicePosition])) {
		my $cmp = attrCmp( $self, $attrib, $value, $thisVal );

		# Not there yet
		next if $cmp > 0;

		# Duplicate - return now if we are preserving uniqueness
		return if (($cmp == 0) and $uniq);

		# Insert here
		last;
	}
	continue {
		$splicePosition++;
	}

	# Insert the value
	$self->{data}->splice($attrib,$splicePosition,0,$value);
}

########################################

=head2 get

Get the list of values for an attribute.

Returns an empty list if the attribute exists but has no values.

Returns undef if the attribute does not exist.

   $arrayRef = $entry->get("myAttribute");

=cut

sub get {
	my $self = shift;
	my $attrib = shift;

	croak "get requires an attribute name" if (!$attrib);

	# Lower-case the attribute name if necessary
	$attrib = "\L$attrib" if (!$self->{config}->{caseSensitiveNames});

	carp "Data::Template::Entry->get attribute '$attrib'" if $debug;
	my $valref = $self->{data}->fetch($attrib);
	return undef if !$valref;
	my @values = @$valref;
	return ( wantarray ? @values : \@values );
}

########################################

=head2 attributes

Get the list of attributes in an entry.

Returns an empty list if there are no attributes.

Note that attributes can exist but not have values.

   $arrayRef = $entry->attributes();

=cut

sub attributes {
	my $self = shift;

	my @attrs = $self->{data}->keys();
	carp "Data::Template::Entry->attributes are: " . (join ',',@attrs) if $debug;
	return ( wantarray ? @attrs : \@attrs );
}


########################################

=head2 attribute_match

Return true or false depending on whether the named attribute contains
a list of values exactly matching the one supplied.

   $result = $entry->attribute_match( 'attribname', ['value1','value2'] );

The supplied list must be sorted into the same order that Data::Toolkit::Entry uses.
This will automatically be done in the common case of comparing an attribute
in two entries:

   $result = $entry->attribute_match( 'name', $secondEntry->get('name') );

An undef list is treated as if it were an empty list.

=cut

sub attribute_match {
	my $self = shift;
	my $attrib = shift;
	my $list = shift;

	croak "Data::Template::Entry->attribute_match needs an attribute name" if !$attrib;
	carp "Data::Template::Entry->attribute_match $attrib" if $debug;

	# Lower-case the attribute name if necessary
	$attrib = "\L$attrib" if (!$self->{config}->{caseSensitiveNames});

	# Undef list of values is equivalent to an empty list
	$list = [] if !$list;
	my @supplied = @$list;
	my @mine = $self->{data}->fetch($attrib);

	# Step through the lists comparing values
	my $suppVal = shift @supplied;
	my $myVal = shift @mine;
	while ($suppVal and $myVal) {
		return 0 if (attrCmp($self, $attrib, $suppVal, $myVal) != 0);

		# Match so far - get the next pair of values
		$suppVal = shift @supplied;
		$myVal = shift @mine;
	}
	# Match is good if no values left
	return 1 if (!$suppVal and !$myVal);
	# One list still has a value so match is not made
	return 0;
}

########################################

=head2 uniqueValues

Define whether an attribute should have unique values.

By default, values are unique: an attribute will not store more than one copy
of a given value, which is compared using the I<comparator> method set for the
attribute.

   $uniqVal = $entry->uniqueValues( 'attributeName', 1 );
   $uniqVal = $entry->uniqueValues( 'attributeName', 0 );
   $uniqVal = $entry->uniqueValues( 'attributeName' );

Setting an undefined value has no effect other than to return the current setting.

Returns the setting of the uniqueValues flag.

Note that changing this flag on an attribute which already has values
does I<not> affect those values.

Passing a hash reference causes all existing uniqueValues flags to be replaced
by the values specified in the hash:

   $hashRef = $entry->uniqueValues( \%mySettings );

=cut

sub uniqueValues {
	my $self = shift;
	my $attrib = shift;
	my $uniq = shift;

	croak "uniqueValues requires an attribute name or hash" if (!$attrib);

	if ((ref $attrib) eq 'HASH') {
		# we have been given a complete config to override what we had before
		my %newUV = %$attrib;
		$self->{config}->{uniqueValues} = \%newUV;
	}

	# Lower-case the attribute name if necessary
	$attrib = "\L$attrib" if (!$self->{config}->{caseSensitiveNames});


	if (!defined($uniq)) {
		carp "Data::Template::Entry->uniqueValues attribute '$attrib'" if $debug;
		return $self->{config}->{uniqueValues}->{$attrib};
	}

	carp "Data::Template::Entry->uniqueValues attribute '$attrib': $uniq" if $debug;
	return $self->{config}->{uniqueValues}->{$attrib} = $uniq;
}

########################################

=head2 comparator

Define how values should be compared for a particular attribute.

By default, values are treated as case-insensitive text strings.

   $func = $entry->comparator( 'attributeName', 'caseIgnore' );
   $func = $entry->comparator( 'attributeName', 'caseSensitive' );
   $func = $entry->comparator( 'attributeName', 'integer' );
   $func = $entry->comparator( 'attributeName', \&myComparatorFunction );
   $func = $entry->comparator( 'attributeName' );

If supplying a function of your own, it should be suitable for use in
Perl's "sort" operation: it should return an integer less than, equal to,
or greater than zero depending on whether its first argument is less than, equal to,
or greater than its second argument. Note that sort's $a,$b convention
should I<not> be used.

Returns the name of the comparison method or a reference to a function
as appropriate.

Note that changing this flag on an attribute which already has values
does I<not> affect those values.

Passing a hash reference causes all existing comparator flags to be replaced
by the values specified in the hash:

   $hashRef = $entry->comparator( \%myHash );

=cut

sub comparator {
	my $self = shift;
	my $attrib = shift;
	my $comp = shift;

	croak "comparator requires an attribute name or hash" if (!$attrib);

	if ((ref $attrib) eq 'HASH') {
		# we have been given a complete config to override what we had before
		my %newCMP = %$attrib;
		$self->{config}->{comparator} = \%newCMP;
	}

	# Lower-case the attribute name if necessary
	$attrib = "\L$attrib" if (!$self->{config}->{caseSensitiveNames});


	if (!defined($comp)) {
		carp "Data::Template::Entry->comparator attribute '$attrib'" if $debug;
		return $self->{config}->{comparator}->{$attrib};
	}

	if ((ref $comp) eq 'CODE') {
		# We have a procedure to register
		carp "Data::Template::Entry->comparator attribute '$attrib' (CODE)" if $debug;
		return $self->{config}->{comparator}->{$attrib} = $comp;
	}

	if ("\L$comp" eq 'caseignore') {
		carp "Data::Template::Entry->comparator attribute '$attrib' (caseIgnore)" if $debug;
		return $self->{config}->{comparator}->{$attrib} = 'caseIgnore';
	}

	if ("\L$comp" eq 'casesensitive') {
		carp "Data::Template::Entry->comparator attribute '$attrib' (caseSensitive)" if $debug;
		return $self->{config}->{comparator}->{$attrib} = 'caseSensitive';
	}

	if ("\L$comp" eq 'integer') {
		carp "Data::Template::Entry->comparator attribute '$attrib' (integer)" if $debug;
		return $self->{config}->{comparator}->{$attrib} = 'integer';
	}

	# Hmm - something odd here
	croak "Unknown comparator type";
}

########################################

=head2 map

Create a new entry object by applying a map to the current one.
Further entries can also be specified. They will be passed to the Data::Toolkit::Map
generate method.

   $newEntry = $entry->map($thisMap);
   $newEntry = $entry->map($thisMap,$entry2,$entry3,...);

The map is a Data::Toolkit::Map object.

=cut

sub map {
	my $self = shift;
	my $map = shift;

	croak "map requires a map object" if (!$map);
	croak "map object must be of type Data::Toolkit::Map" if (!$map->isa('Data::Toolkit::Map'));
	carp "Data::Template::Entry->map" if $debug;

	# Create a new entry with the same setup as this one
	my $newEntry = Data::Toolkit::Entry->new($self->{config});

	# Get the list of output attributes from the map
	my $mapOutputs = $map->outputs();

	# Step through that list creating attributes in the new entry
	# Do not create an attribute if given an undef arrayref
	#
	foreach my $attr (@$mapOutputs) {
		my $vals = $map->generate($attr,$self,@_);
		warn "Data::Template::Entry->map $attr: " . (join ':',@$vals) if $debug;
		$newEntry->add($attr, $vals) if $vals;
	}

	return $newEntry;
}


########################################

=head2 delete

Delete a value from an attribute:

   $result = $entry->delete('thisAttribute','thisValue');

Delete an attribute and all its values:

   $result = $entry->delete('thisAttribute');

In both cases, returns a list containing any values that it deleted.
If nothing was deleted, returns false.

Note that deleting an attribute does not delete setting such as the
comparator for that attribute.

=cut

sub delete {
	my $self = shift;
	my $attrib = shift;
	my $value = shift;

	croak "delete requires an attribute name" if (!$attrib);

	# Lower-case the attribute name if necessary
	$attrib = "\L$attrib" if (!$self->{config}->{caseSensitiveNames});


	if (defined($value)) {
		# We are deleting a single value
		carp "Data::Template::Entry->delete '$value' from attribute '$attrib'" if $debug;
		my $allValues = $self->{data}->fetch($attrib);
		# Is there anything there at all?
		return undef if (!defined($allValues) or !defined($allValues->[0]));
		# print "NEED TO DELETE $value\n";
		for (my $count=0; defined($allValues->[$count]); $count++) {
			if ($value eq $allValues->[$count]) {
				return $self->{data}->splice($attrib,$count,1);
			}
		}
		# Not found
		return undef;
	}
	else {
		# We are deleting the whole attribute
		carp "Data::Template::Entry->delete attribute '$attrib'" if $debug;
		return $self->{data}->delete($attrib);
	}
}


########################################################################
# Debugging methods
########################################################################

=head1 Debugging methods

=head2 debug

Set and/or get the debug level for Data::Toolkit::Entry

   my $currentDebugLevel = Data::Toolkit::Entry->debug();
   my $newDebugLevel = Data::Toolkit::Entry(1);

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

########################################

=head2 dump

Returns a text representation of the entry.

   my $string = $entry->dump();

=cut


sub dump {
	my $self = shift;

	my %hash = $self->{data}->fetch_all();
	return Dumper(\%hash);
}

########################################################################
########################################################################

=head1 Error handling

If you miss out an essential parameter, the module will throw an exception
using "croak" from the Carp module. These exceptions represent programming
errors in most cases so there is little point in trapping them with "eval".

=head1 Author

Andrew Findlay

Skills 1st Ltd

andrew.findlay@skills-1st.co.uk

http://www.skills-1st.co.uk/

=cut

########################################################################
########################################################################
1;
