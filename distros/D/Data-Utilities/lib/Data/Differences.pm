#!/usr/bin/perl -w
#!/usr/bin/perl -d:ptkdb -w
#
# This is module is based on a module with the same name, implemented
# when working for Newtec Cy, located in Belgium,
# http://www.newtec.be/.
#

package Data::Differences;


#
# Please read the comments of the constructor (new()) before using
# this package.
#
# How it should be done (at least this is what I think at the moment
# of writing) :
#
# 1. A set of differences is essentially a blessed hash which inherits
# from this package.
#
# 2. At the top level the hash contains entries describing meta
# information :
#
# 2.1. The fundamental types that have been compared.
#
# 3. Additionally the following items are present at the top level :
#
# 3.1. 'subtractor_operands' : operands for the subtract operation.
#
# 3.2. 'adder_operands' : operands for the add operation.  This should
# be feed to Hash::Merge, possibly by first embedding the given
# arguments in a top level hash (e.g. if the arguments are arrays).
#


use strict;


#
# is_empty()
#
# Return true if a differences describing data structure describes no
# differences.
#

sub is_empty
{
    my $self = shift;

    #t perhaps I should also return false for an array with only
    #t undefs and likewise for a hash ?

    # for an empty hash

    if (("$self" =~ /HASH/ && !%$self)

	# or an empty array

	|| ("$self" =~ /ARRAY/ && !@$self)

	# or an empty scalar

	|| ("$self" =~ /SCALAR/ && !defined $$self))
    {
	# return empty

	return 1;
    }

    # otherwise

    else
    {
	# return false

	return 0;
    }
}


#
# filter()
#
# Filter the differences set by removing the undef entries.  For
# reasons of consistency this sub must be called during construction.
#

sub filter
{
    my $self = shift;

    if ("$self" =~ /ARRAY/)
    {
	return $self->filter_array();
    }
    elsif ("$self" =~ /HASH/)
    {
	return $self->filter_hash();
    }
    elsif ("$self" =~ /SCALAR/)
    {
	return $self->filter_scalar();
    }
    elsif ("$self" =~ /REF/
	   && !defined $$self)
    {
	return \undef;
    }
    elsif ("$self" =~ /REF/
	   && UNIVERSAL::isa($$self,'Data::Differences'))
    {
	return $$self->filter();
    }
    else
    {
	# a structure that cannot be dissected any further : return it.

	return $self;
    }
}


sub filter_array
{
    my $self = shift;

    my $is_empty = 1;

    foreach my $entry (@$self)
    {
	#t see comments below on ->filter_hash().
	#t perhaps this needs protection with an additional check, not sure.

	if (defined $entry)
	{
	    if ($entry->filter())
	    {
		$is_empty = 0;
	    }
	}
    }

    if ($is_empty)
    {
	@$self = ();
    }

    return $self;
}


sub filter_hash
{
    my $self = shift;

    my $is_empty = 1;

    foreach my $key (keys %$self)
    {
	#t
	#t The first if condition is bogus I guess,
	#t commented out but perhaps
	#t it is right for certain scenarios, unresolved.
	#t The rest of the TODO comments is about the
	#t commented out condition only.
	#t
	#t we can get here with a reference to an empty hash.
	#t without the eval below, we get the perl error
	#t 'Not a SCALAR reference'.  I simply added the
	#t eval {} statement to allow to continue the other
	#t developments.  I inspected via the debugger the
	#t correctness of the software under test,
	#t I am not sure of the correctness of the testing
	#t software.  Given the fact that this eval {} statement
	#t also hides a number of warnings, I suspect so far
	#t unforeseen scenarios that might popup as bugs of
	#t the testing software.

	eval
	{
#  	    if (defined ${$self->{$key}})
	    if (defined $self->{$key})
	    {
		if ($self->{$key}->filter())
		{
		    $is_empty = 0;
		}
	    }
	};
    }

    if ($is_empty)
    {
	%$self = ();
    }

    return $self;
}


sub filter_scalar
{
    my $self = shift;

    if (defined $$self)
    {
	return 1;
    }
    else
    {
	return undef;
    }
}


#
# new()
#
# Create a new structure from the given data structure.
#
# The given data structure must be compliant with the common
# conventions for this data structure, whatever they may be.  They
# still need complete definition.
#
# Currently the differences structure only deals with new data (to be
# added to existing data), it does not deal with data to be removed.
#

sub new
{
    my $proto = shift;

    my $class = ref $proto || $proto;

    my $differences = shift;

    bless $differences, $class;

    $differences->filter();

    return $differences;
}


1;


