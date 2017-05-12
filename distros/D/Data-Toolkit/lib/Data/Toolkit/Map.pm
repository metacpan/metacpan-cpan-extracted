#!/usr/bin/perl -w
#
# Data::Toolkit::Map
#
# Andrew Findlay
# Nov 2006
# andrew.findlay@skills-1st.co.uk
#
# $Id: Map.pm 388 2013-08-30 15:19:23Z remotesvn $

package Data::Toolkit::Map;

use strict;
use Data::Dumper;
use Carp;
use Clone qw(clone);

=head1 NAME

Data::Toolkit::Map

=head1 DESCRIPTION

Data::Toolkit::Map objects implement mapping functions for attribute names
and values in Data::Toolkit::Entry objects. This is useful when converting between
different data representations in directory-synchronisation projects.

=head1 SYNOPSIS

   my $map = Data::Toolkit::Map->new();

   $map->set("surname", "sn" );

   $map->set("objectclass", [ "inetOrgPerson", "organizationalPerson", "person" ] );
   $map->set("phone","+44 1234 567890");
   $map->set("address", \&buildAddress);
   $map->set("fn", sub { return firstValue("fullname", @_) });

   $arrayRef = $map->outputs();

   $values = $map->generate('attributeName', $entry [, $entry...]);

   $newEntry = $map->newEntry($source1, $source2 ...);

   $result = $map->delete('thisAttribute');

   my $currentDebugLevel = Data::Toolkit::Map->debug();
   my $newDebugLevel = Data::Toolkit::Map->debug(1);

   my $string = $map->dump();

=head1 DEPENDENCIES

   Carp
   Clone
   Data::Dumper

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

   my $map = Data::Toolkit::Map->new();
   my $map = Data::Toolkit::Map->new( {configAttrib => value, ....} );

Creates an object of type Data::Toolkit::Map

Optionally accepts a hash of configuration items chosen from this list:

=over

=item caseSensitiveNames

If this is defined with a true value then attribute names are case-sensitive.
By default they are not, so "Surname", "surname", and "SurName" are all the same attribute.

=item defaultMissingValueBehaviour

This is a hash defining what to do when mapping attributes that do not have values.
The keys are:

=over

=item missing

Defines the behaviour when an input attribute is entirely missing.

=item noValues

Defines the behaviour when an input attribute exists but it has no values.

=item nullValue

Defines the behaviour when an input attribute exists and its first value is undef.

=item emptyString

Defines the behaviour when an input attribute has an empty string as its first value.

=back

The possible values are:

=over

=item delete

Delete the attribute entirely from the output of the map.
If the generate method is used on such an attribute, it will return undef.

=item noValues

The attribute will appear in the output of the map but no values will be defined.
If the generate method is used on such an attribute, it will return an empty array.

=item nullValue

The attribute will appear in the output of the map and its single value will be undef.
If the generate method is used on such an attribute, it will return an array containing one undef element.

=item emptyString

The attribute will appear in the output of the map with a single empty string value.

=item A subroutine reference or closure

If a pointer to an executable procedure is used as the value, that procedure
will be called and its return value used as the value of the attribute.
The return value can be undef, scalar, vector, or hash.
There is no way for the subroutine to request deletion of the entire attribute.

The subroutine is called with the name of the attribute being generated as its first parameter,
an indication of whether an array result is wanted as its second parameter,
and a reference to the input entry as its third parameter:

subroutine( $attributename, $wantarray, $entry);

=back

The default missing value behaviour is:

		{
			missing => 'delete',
			noValues => 'noValues',
			nullValue => 'nullValue',
			emptyString => 'emptyString',
		};

=back

=cut

sub new {
	my $class = shift;
	my $configParam = shift;

	my $self  = {};
	$self->{mapping} = {};

	# Take a copy of the config hash
	# - we don't want to store a ref to the one we were given
	#   in case it is part of another object
	#
	if (defined($configParam)) {
		if ((ref $configParam) ne 'HASH') {
			croak "Data::Toolkit::Map->new expects a hash ref but was given something else"
		}

		$self->{config} = clone($configParam);
	}
	else {
		# Start with empty config
		$self->{config} = {};
		# Add the default missing value behaviour
		$self->{config}->{defaultMissingValueBehaviour} = {
			missing => 'delete',
			noValues => 'noValues',
			nullValue => 'nullValue',
			emptyString => 'emptyString',
		};
	}

	bless ($self, $class);

	carp "Data::Toolkit::Map->new $self" if $debug;
	return $self;
}

sub DESTROY {
	my $self = shift;
	carp "Data::Toolkit::Map Destroying $self" if $debug;
}

########################################################################
# Methods
########################################################################

=head1 Methods

=cut

########################################

=head2 set

Set or replace a mapping.

   $map->set( outputAttribute, generator )

outputAttribute must be a text string. Generator can be of several types:

=over

=item SCALAR - the value is the name of an attribute in the source entry, which is copied
to the outputAttribute

=item ARRAY - the value is a fixed array of strings which will be used as the value of
the outputAttribute

=item CODE - the value is a procedure or closure that is run to generate the value of
the outputAttribute. The procedure must return undef or an array reference.

=back

This is a simple mapping that generates a "surname" attribute by copying
the value of the input entry's "sn" attribute:

   $map->set("surname", "sn" );

This is a fixed mapping generating an LDAP objectClass attribute with
several values:

   $map->set("objectclass", [ "inetOrgPerson", "organizationalPerson", "person" ] );

This is a fixed mapping generating a single value (note the use of a list
to distinguish this from the first case above):

   $map->set("phone", ["+44 1234 567890"]);

This is a dynamic mapping where the attribute is generated by a procedure:

   $map->set("address", \&buildAddress);

When a dynamic mapping is evaluated, it is given the name of the attribute being generated
followed by all the parameters that were passed to the "generate" call,
so it can refer to entries and other objects.

Similarly, closures can be used:

   $map->set("fn", sub { return firstValue("xyzzy", @_) });

In this example, when the firstValue() procedure is called by "generate",
it gets one fixed parameter plus anything else that was passed to the "generate" call.
Thus the call:

   $map->generate("fn",$entry)

would result in a call like this:

   firstValue("fn","xyzzy",$entry)


=cut

sub set {
	my $self = shift;
	my $attrib = shift;
	my $values = shift;

	croak "set requires an attribute name" if (!$attrib);
	croak "set requires a value" if (!$values);

	# Lower-case the attribute name if necessary
	$attrib = "\L$attrib" if (!$self->{config}->{caseSensitiveNames});

	carp "Data::Toolkit::Map->set attribute '$attrib'" if $debug;

	return $self->{mapping}->{$attrib} = $values;
}


########################################

=head2 unset

Removes an attribute from a map.
Returns a reference to the deleted value.

=cut

sub unset {
	my $self = shift;
	my $attrib = shift;

	croak "unset requires an attribute name" if (!$attrib);

	# Lower-case the attribute name if necessary
	$attrib = "\L$attrib" if (!$self->{config}->{caseSensitiveNames});

	carp "Data::Toolkit::Map->unset attribute '$attrib'" if $debug;

	return delete $self->{mapping}->{$attrib};
}


########################################

=head2 outputs

Return the list of attributes that the map generates.

Returns an empty list if there are no attributes.

   $arrayRef = $map->outputs();

=cut

sub outputs {
	my $self = shift;

	my @keys_list = sort(CORE::keys %{$self->{mapping}});
	carp "Data::Toolkit::Map->outputs are: " . (join ',', @keys_list) if $debug;
        return( wantarray ? @keys_list : \@keys_list );

}

########################################
#
# generateMissingValue( $attrib, $wantarray, $requiredBehaviour, $entry );
#
# Internal procedure for handling missing values

sub generateMissingValue {
	my ($attrib, $wantarray, $requiredBehaviour, $entry) = @_;

	croak "generateMissingValue needs a requiredBehaviour parameter" if (!$requiredBehaviour);

	carp "generateMissingValue '$attrib', $wantarray, '$requiredBehaviour'" if $debug;
	if ( $requiredBehaviour eq 'delete' ) {
		return undef;
	}

	if ($requiredBehaviour eq 'noValues') {
		# Return an empty array
		my $res = [];
		return ($wantarray ? @$res : $res);
	}

	if ($requiredBehaviour eq 'nullValue') {
		# Return an array containing an undef value
		my $res = [ undef ];
		return ($wantarray ? @$res : $res);
	}

	if ($requiredBehaviour eq 'emptyString') {
		my $res = [''];
		return ($wantarray ? @$res : $res);
	}

	if ((ref $requiredBehaviour) eq 'CODE') {
		# We have been given some code to run
                return &$requiredBehaviour($attrib, $wantarray, $entry);
	}

	croak "generateMissingValue was given an invalid requiredBehaviour parameter ($requiredBehaviour)";
}


########################################

=head2 generate

Generate a list of values for a given attribute.

   $values = $map->generate('attributeName', $entry );

=cut

sub generate {
	my $self = shift;
	my $attrib = shift;

	croak "generate requires an attribute name" if (!$attrib);

	# Lower-case the attribute name if necessary
	$attrib = "\L$attrib" if (!$self->{config}->{caseSensitiveNames});

	carp "Data::Toolkit::Map->generate for attribute '$attrib'" if $debug;

	my $mapping = $self->{mapping}->{$attrib};
	# If that is undef or empty, return it immediately
	return $mapping if !$mapping;

	my $refMap = ref $mapping;
	if (!$refMap) {
		# We have a mapping but it is not a reference
		carp "Data::Toolkit::Map->generate attribute '$attrib' from source attribute '$mapping'" if $debug;

		# Must be a simple attribute map so get the source entry
		my $entry = shift;
		my @values = $entry->get($mapping);

		if (not $values[0]) {
			# We may have a missing value or attribute in the source
			# (or it may just be zero...) so do some checks
			my $valref = $entry->get($mapping);
			if (not defined($valref)) {
				# The attribute is entirely missing in the source
				carp "generate attribute '$attrib' from missing source attr" if $debug;
				return generateMissingValue( $attrib, wantarray,
					$self->{config}->{defaultMissingValueBehaviour}->{missing}, $entry );
			}
			if ((scalar @$valref) == 0) {
				# The attribute is present but has no values
				carp "generate attribute '$attrib' from source attr with no values" if $debug;
				return generateMissingValue( $attrib, wantarray,
					$self->{config}->{defaultMissingValueBehaviour}->{noValues}, $entry );
			}
			if (not defined($valref->[0])) {
				# The attribute is present but has a null value
				carp "generate attribute '$attrib' from null valued source attr" if $debug;
				return generateMissingValue( $attrib, wantarray,
					$self->{config}->{defaultMissingValueBehaviour}->{nullValue}, $entry );
			}
			if ($valref->[0] eq '') {
				# The attribute is present and the value is an empty string
				carp "generate attribute '$attrib' from empty string source attr" if $debug;
				return generateMissingValue( $attrib, wantarray,
					$self->{config}->{defaultMissingValueBehaviour}->{emptyString}, $entry );
			}
			# In all other cases, just return what was there in the source entry
		}

		return wantarray ? @values : \@values;
	}
	elsif ($refMap eq 'ARRAY') {
		# Arrays represent constant data so just return it as-is
		carp "Data::Toolkit::Map->generate attribute '$attrib' from fixed array" if $debug;

		return wantarray ? @$mapping : $mapping;
	}
	elsif ($refMap eq 'CODE') {
		# We have been given some code to run
		carp "Data::Toolkit::Map->generate attribute '$attrib' from supplied code" if $debug;

		my $result = &$mapping($attrib, @_);
		# Do some sanity checking on the result
		return undef if !defined($result);
		my $resType = ref $result;
		$resType = 'SCALAR' if !$resType;
		if ($resType ne 'ARRAY') {
			croak "mapping procedure returned $resType while mapping for '$attrib' - it should have returned an ARRAY";
		}

		return $result;
	}
	else {
		# Don't know what to do with this!
		croak "generate does not know how to handle a $refMap mapping";
	}

}

########################################

=head2 newEntry

Create a new entry object by applying a map to one or more existing entries

   $newEntry = $map->newEntry($source1, $source2 ...);

The source objects are Data::Toolkit::Entry objects

=cut

sub newEntry {
	my $self = shift;

	# If we have been passed any source entries, use the first one as a template
	# to create the new entry
	if ($_[0]) {
		carp "Data::Toolkit::Map->newEntry from template entry" if $debug;
		my $template = shift;
		return $template->map( $self, @_ );
	}

	# Hmm - we seem to be mapping from nothing to create something!
	carp "Data::Toolkit::Map->newEntry from nothing" if $debug;

	# Create a new entry with default config to act as source
	my $newEntry = Data::Template::Entry->new();

	return $newEntry->map( $self );
}


########################################

=head2 delete

Delete an output from a map.

   $result = $map->delete('thisAttribute');

=cut

sub delete {
	my $self = shift;
	my $attrib = shift;

	croak "delete requires an attribute name" if (!$attrib);

	# Lower-case the attribute name if necessary
	$attrib = "\L$attrib" if (!$self->{config}->{caseSensitiveNames});

	carp "Data::Toolkit::Map->delete '$attrib'" if $debug;

	return delete $self->{$attrib};
}


########################################################################
# Debugging methods
########################################################################

=head1 Debugging methods

=head2 debug

Set and/or get the debug level for Data::Toolkit::Map

   my $currentDebugLevel = Data::Toolkit::Map->debug();
   my $newDebugLevel = Data::Toolkit::Map->debug(1);

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

Returns a text representation of the map.

   my $string = $map->dump();

=cut


sub dump {
	my $self = shift;

	my %hash = $self->{mapping};
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
