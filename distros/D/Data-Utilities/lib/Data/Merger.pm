#!/usr/bin/perl -w
#!/usr/bin/perl -d:ptkdb -w
#
# This module is based on code that was implemented
# when working for Newtec Cy, located in Belgium,
# http://www.newtec.be/.
#

=head1 NAME

Data::Merger - merge nested Perl data structures.

=head1 SYNOPSIS

    use Data::Merger qw(merger);

    my $target
        = {
           a => 2,
           e => {
                 e1 => {
                       },
                },
          };

    my $source
        = {
           a => 1,
           e => {
                 e2 => {
                       },
                 e3 => {
                       },
                },
          };

    my $expected_data
        = {
           a => 1,
           e => {
                 e1 => {
                       },
                 e2 => {
                       },
                 e3 => {
                       },
                },
          };

    my $merged_data = merger($target, $source);

    use Data::Comparator qw(data_comparator);

    my $differences = data_comparator($merged_data, $expected_data);

    if ($differences->is_empty())
    {
        print "$0: 3: success\n";

        ok(1, '3: success');
    }
    else
    {
        print "$0: 3: failed\n";

        ok(0, '3: failed');
    }

=head1 DESCRIPTION

Data::Merger contains subs to merge two nested perl data structures,
overwriting values where appropriate.  For scalars, default is to
overwrite values.  The two data structure can contain perl hashes,
arrays and scalars, and should have the same overall structure (unless
otherwise specified using options, see below).  They should not be
self-referential.

This module implements the functions merger(), merger_any(),
merger_array() and merger_hash().  The main entry point is merger().

The merger() function is called with three arguments:

=over 2

=item target and source arguments

are the two data structures to be merged.  The target data structure
will be overwritten, and results are copied by reference.  If you need
plain copies, first Clone(3) your original data.

=item options

Options is a hash reference.  There is currently one option:

=over 2

=item {arrays}->{overwrite}

If this value evals to 1, array entries are always overwritten,
regardless of type / structure mismatches of the content of the
entries in the arrays.

=item {hashes}->{overwrite}

If this value evals to 1, hash entries are always overwritten,
regardless of type / structure mismatches of the values of the tuples
in the hashes.

=back

=back

=head1 BUGS

Does only work with scalars, hashes and arrays.  Support for
self-referential structures seems broken at the moment.

This works for me to overwrite configuration defaults with specific
values.  Yet, is certainly incomplete.

=head1 AUTHOR

Hugo Cornelis, hugo.cornelis@gmail.com

Copyright 2007 Hugo Cornelis.

This module is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

=head1 SEE ALSO

Data::Transformator(3), Data::Comparator(3), Clone(3)

=cut


package Data::Merger;


use strict;


our @ISA = qw(Exporter);

our @EXPORT_OK = qw(
		    merger
		   );


#
# subs to merge two datastructures.
#

sub merger_any
{
    my $contents = shift;

    my $data = shift;

    my $options = shift;

    # simply check what kind of data structure we are dealing
    # with and forward to the right sub.

    my $type = ref $contents;

    if ($type eq 'HASH')
    {
	merger_hash($contents, $data, $options);
    }
    elsif ($type eq 'ARRAY')
    {
	merger_array($contents, $data, $options);
    }
    else
    {
	die "$0: *** Error: Data::Merger error: merger_any() encounters an unknown data type $type";
    }
}


sub merger_hash
{
    my $contents = shift;

    my $data = shift;

    my $options = shift;

    if (!exists $options->{hashes}->{overwrite})
    {
	$options->{hashes}->{overwrite} = 1;
    }

    # loop over all values in the contents hash.

    foreach my $section (keys %$data)
    {
	if (exists $contents->{$section}
	    || $options->{hashes}->{overwrite} eq 1)
	{
	    my $value = $data->{$section};

	    my $contents_type = ref $contents->{$section};
	    my $value_type = ref $value;

	    if (!defined $value
		&& $options->{undefined}->{overwrite} ne 1)
	    {
		next;
	    }

	    if ($contents_type && $value_type)
	    {
		if ($contents_type eq $value_type)
		{
		    # two references of the same type, go one
		    # level deeper.

		    merger_any($contents->{$section}, $value, $options);
		}
		elsif ($options->{hashes}->{overwrite} eq 1)
		{
		    # copy value regardless of type

		    $contents->{$section} = $value;
		}
		elsif ($options->{hashes}->{overwrite} eq 0)
		{
		    # keep old value

		}
		else
		{
		    die "$0: *** Error: Data::Merger error: contents_type is '$contents_type' and does not match with value_type $value_type";
		}
	    }
	    elsif (!$contents_type && !$value_type)
	    {
		# copy scalar value

		$contents->{$section} = $value;
	    }
	    elsif ($options->{hashes}->{overwrite} eq 1)
	    {
		# copy value regardless of type

		$contents->{$section} = $value;
	    }
	    else
	    {
		die "$0: *** Error: Data::Merger error: contents_type is '$contents_type' and does not match with value_type $value_type";
	    }
	}
	else
	{
	    #t could be a new key being added.
	}
    }
}


sub merger_array
{
    my $contents = shift;

    my $data = shift;

    my $options = shift;

    if (!exists $options->{arrays}->{overwrite})
    {
	$options->{arrays}->{overwrite} = 1;
    }

    # loop over all values in the contents array.

    my $count = 0;

    foreach my $section (@$data)
    {
	if (exists $contents->[$count]
	    || $options->{arrays}->{overwrite} eq 1)
	{
	    my $value = $data->[$count];

	    my $contents_type = ref $contents->[$count];
	    my $value_type = ref $value;

	    if (!defined $value
		&& $options->{undefined}->{overwrite} ne 1)
	    {
		$count++;

		next;
	    }

	    if ($contents_type && $value_type)
	    {
		if ($contents_type eq $value_type)
		{
		    # two references of the same type, go one
		    # level deeper.

		    merger_any($contents->[$count], $value, $options);
		}
		elsif ($options->{arrays}->{overwrite} eq 1)
		{
		    # overwrite array content

		    $contents->[$count] = $value;
		}
		elsif ($options->{arrays}->{overwrite} eq 0)
		{
		    # keep old value

		}
		else
		{
		    die "$0: *** Error: Data::Merger error: contents_type is '$contents_type' and does not match with value_type $value_type";
		}
	    }
	    elsif (!$contents_type && !$value_type)
	    {
		# copy scalar value

		$contents->[$count] = $value;
	    }
	    elsif ($options->{arrays}->{overwrite} eq 1)
	    {
		# overwrite array content

		$contents->[$count] = $value;
	    }
	    else
	    {
		die "$0: *** Error: Data::Merger error: contents_type is '$contents_type' and does not match with value_type $value_type";
	    }
	}
	else
	{
	    #t could be a new key being added.
	}

	$count++;
    }
}


sub merger
{
    my $target = shift;

    my $source = shift;

    my $options = shift;

    if (!exists $options->{undefined}->{overwrite})
    {
	$options->{undefined}->{overwrite} = 0;
    }

    #t I don't think the todos below are still valid, the idea is
    #t sound though:

    #t Should actually use a simple iterator over the detransformed data
    #t that keeps track of examined paths.  Then use the path to store
    #t encountered value in the original data.

    #t Note that the iterator is partly implemented in Sesa::Transform and
    #t Sesa::TreeDocument.  A further abstraction could be useful.

    # first inductive step : merge all data.

    merger_any($target, $source, $options);

    return $target;
}


1;


