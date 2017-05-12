#!/usr/bin/perl -w
#!/usr/bin/perl -d:ptkdb -w
#
# This is module is based on a module with the same name, implemented
# when working for Newtec Cy, located in Belgium,
# http://www.newtec.be/.
#

package Data::Comparator;


#
# The main entry point for this module is the sub data_comparator().
# It compares two sets of (structured) data and reports on the
# differences found with a differences describing data structure.
#
# The algorithm used is of a subtractive kind.  It subtracts the first
# data structure given from the second one.  This means that, since it
# not possible to subtract what is not yet there, not all differences
# are reported.  To have a report of all differences between
# structures A and B, first subtract A from B, next subtract B from A.
# The two result sets are an exact description of the differences
# between A and B (or should be, untested for the moment).
#


use strict;


use Clone 'clone';

use Data::Differences;


# require Exporter;

our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
		    array_comparator
		    hash_comparator
		    data_comparator
		   );


#
# array_comparator()
#
# Compare two arrays, report on the differences found by returning an
# array describing the differences between the two arrays.
#

sub array_comparator
{
    my $array1 = shift;

    my $array2 = shift;

#     my $result = { adder_operand => [], subtractor_operand => [], };

    my $result = [];

    foreach my $index (0 .. $#$array1)
    {
	if (exists $array2->[$index])
	{
	    my $index_result = data_comparator($array1->[$index], $array2->[$index]);

	    if (!$index_result->is_empty())
	    {
		$result->[$index] = $index_result;
	    }
	}
	else
	{
	    $result->[$index]
		= Data::Differences->new(clone(\$array1->[$index]));
	}
    }

    foreach my $index ($#$array1 + 1 .. $#$array2)
    {
	$result->[$index]
	    = Data::Differences->new(clone(\$array2->[$index]));
    }

    return Data::Differences->new($result);
}


=head1 NAME

Data::Comparator - recursively compare Perl datatypes

=head1 SYNOPSIS

  use Data::Comparator qw(data_comparator);
  
  $a = { 'foo' => 'bar', 'move' => 'zig' };
  $b = [ 'alpha', 'beta', 'gamma', 'vlissides' ];

  $diff = data_comparator($a, $b);

  use Data::Dumper;

  print Dumper($diff);

  if ($diff->is_empty())
  {
      print '$a and $b are alike\n';
  }
  else
  {
      print '$a and $b are not alike\n';
  }

=head1 DESCRIPTION

Compare two sets of (structured) data, report on the differences found
with a differences describing data structure.  Additionally a set of
expected differences may be given in the form of a differences
describing data structure.

Returns a differences describing data structure, which is empty if no
differences are found.  The type of the result is the same as the type
of the second data structure given.

The algorithm used is of a subtractive kind.  It subtracts the first
data structure given from the second one.  This means that, since it
is not possible to subtract what is not given in the subtractor, not
all differences are reported.  To have a report of all differences
between structures A and B, first subtract A from B, next subtract B
from A, using this module.  The two result sets are an exact
description of the differences between A and B.

It is possible to add any of the methods array_comparator(),
hash_comparator(), data_comparator() to an existing object, or to use
these as regular subs.

=head1 NOTE

This module is used in the tests for Data::Merger(3) and
Data::Transformator(3).

=head1 BUGS

Does only work with scalars, hashes and arrays.  Does not work on
self-referential structures.

=head1 AUTHOR

Hugo Cornelis, hugo.cornelis@gmail.com

Copyright 2007 Hugo Cornelis.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

Data::Merger(3), Data::Transformator(3), Data::Differences(3),
Clone(3)

=cut

sub data_comparator
{
    my $data1 = shift;

    my $data2 = shift;

    my $expected_differences = shift;

    my $result;

    # get the types for the different arguments

    my $data_type1 = (ref $data1 && "$data1") || '';

    my $data_type2 = (ref $data2 && "$data2") || '';

    # first compare comparables

    # try to compare two hashes

    if ($data_type1 =~ /HASH/
        && $data_type2 =~ /HASH/)
    {
	$result = hash_comparator($data1, $data2);
    }

    # or try to compare two arrays

    elsif ($data_type1 =~ /ARRAY/
	   && $data_type2 =~ /ARRAY/)
    {
	$result = array_comparator($data1, $data2);
    }

    # or try to compare two scalars

    elsif ($data_type1 =~ /SCALAR/
	   && $data_type2 =~ /SCALAR/)
    {
	$result = scalar_ref_comparator($data1, $data2);
    }

    # or try to compare two referenced references

    elsif ($data_type1 =~ /REF/
	   && $data_type2 =~ /REF/)
    {
	$result = data_comparator($$data1, $$data2);
    }

    # or try to compare two non references

    elsif (!$data_type1
	   && !$data_type2)
    {
	$result = scalar_comparator($data1, $data2);
    }

    # second, for non-comparables

    else
    {
	# simply clone second argument

	$result = Data::Differences->new(clone(\$data2));
    }

    # if the user was already expecting differences

    if (defined $expected_differences)
    {
	# compare the result with the expected differences

	$result = data_comparator($expected_differences, $result);
    }

    return $result;
}


#
# hash_comparator()
#
# Compare two hashes, report on the differences found by returning an
# hash describing the differences between the two hashes.
#

sub hash_comparator
{
    my $hash1 = shift;

    my $hash2 = shift;

    my $result = {};

    foreach my $key (keys %$hash1)
    {
	if (exists $hash2->{$key})
	{
	    my $key_result = data_comparator($hash1->{$key}, $hash2->{$key});

	    if (!$key_result->is_empty())
	    {
		$result->{$key} = $key_result;
	    }
	}
    }

    foreach my $key (grep { !exists $hash1->{$_} } keys %$hash2)
    {
	$result->{$key}
	    = Data::Differences->new(clone(\$hash2->{$key}));
    }

    return Data::Differences->new($result);
}


#
# scalar_comparator()
#
# Compare two scalar values, report on the differences found by
# returning the second scalar value if it is different from the first
# scalar value.
#

sub scalar_comparator
{
    my $scalar1 = shift;

    my $scalar2 = shift;

    #t two undefs is illegal.

    if (!defined $scalar1 && !defined $scalar2)
    {
	return Data::Differences->new(clone(\undef));
    }

    if (!defined $scalar2)
    {
	return Data::Differences->new(clone(\$scalar2));
    }

    if (($scalar1 cmp $scalar2) eq 0)
    {
	return Data::Differences->new(clone(\undef));
    }
    else
    {
	return Data::Differences->new(clone(\$scalar2));
    }
}


#
# scalar_ref_comparator()
#
# Compare two references to scalar values, report on the differences
# found by returning the second reference if it is different from the
# first reference.
#

sub scalar_ref_comparator
{
    my $scalar1 = shift;

    my $scalar2 = shift;

    my $value1 = $$scalar1;

    my $value2 = $$scalar2;


    # for two undefs

    if (!defined $value1
	&& !defined $value2)
    {
	# return equality

	return Data::Differences->new(clone(\undef));
    }

    # for one undef

    elsif (!defined $value1
	   || !defined $value2)
    {
	# return different

	return Data::Differences->new(clone(\$scalar2));
    }

    # in other cases

    else
    {
	# do a normal comparison by calling the generic comparator

	return data_comparator($value1, $value2);

# 	if (($value1 cmp $value2) eq 0)
# 	{
# 	    return Data::Differences->new(clone(\undef));
# 	}
# 	else
# 	{
# 	    return Data::Differences->new(clone(\$scalar2));
# 	}
    }
}


1;


