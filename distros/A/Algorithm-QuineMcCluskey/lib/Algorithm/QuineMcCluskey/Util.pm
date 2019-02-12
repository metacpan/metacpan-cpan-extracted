=head1 NAME

Algorithm::QuineMcCluskey::Util - provide utility functions to
Algorithm::QuineMcCluskey

=cut

package Algorithm::QuineMcCluskey::Util;

use strict;
use warnings;
use 5.016001;

use List::Util qw(any);
use List::Compare::Functional qw(is_LequivalentR is_LsubsetR);

use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	all => [ qw(
		covered_least
		find_essentials
		hammingd1pos
		maskedmatch
		matchcount
		purge_elements
		remels
		row_dominance
		transpose
		uniqels
	) ],
);

our @EXPORT_OK = (
	@{ $EXPORT_TAGS{all} }
);

our $VERSION = 1.00;

=head1 DESCRIPTION

This module provides various utilities designed for (but not limited to) use in
Algorithm::QuineMcCluskey.

The prime implicant and essentials "tables" are in the form of a hash of
array refs, and are manipulated with the functions find_essentials(),
least_covered(), purge_elements(), remels(), row_dominance(), transpose(),
and uniqels().

=cut

=head2 FUNCTIONS

=head3 matchcount()

Returns the count of a search string Y found in the source string X.

E.g.:

    my $str = "d10d11d1d"; 
    matchcount($str, "d");     # returns 4
    matchcount($str, "d1");    # returns 3

To search for only the string without a regular expression accidentally
interfering, enclose the search string between '\Q' and '\E'. E.g.:

    #
    # We don't know what's in $looking, so de-magic it.
    #
    matchcount($str, '\E' . $looking . '\Q]);

=cut

sub matchcount
{
	my($x, $y) = @_;

	return scalar(() = $x=~ m/$y/g);
}

=head3 maskedmatch()

Returns the terms that match a mask made up of zeros, ones, and don't-care
characters.

    my @rterms = maskedmatch("010-0", @terms);

=cut

sub maskedmatch
{
	my($mask, @terms) = @_;
	my @t;

	#
	# Make two patterns based on the don't-care characters
	# in the mask (assumed to be the character that's not
	# a zero or a one, an assumption enforced in BUILD.)
	#
	(my $m0 = $mask) =~ s/[^01]/0/g;
	(my $m1 = $mask) =~ s/[^01]/1/g;
	$m0 = oct "0b" . $m0;
	$m1 = oct "0b" . $m1;

	for my $x (@terms)
	{
		my $b = oct "0b" . $x;
		push @t, $x if ((($m0 & $b) == $m0) && (($m1 & $b) == $b));
	}

	return @t;
}

=head3 maskedmatchindexes()

Returns the indexes of the terms that match a mask made up of zeros,
ones, and don't-care characters.

    my @pos = maskedmatchindexes("010-0", @terms);

=cut

sub maskedmatchindexes
{
	my($mask, @terms) = @_;
	my @p;

	#
	# Make two patterns based on the don't-care characters
	# in the mask (assumed to be the character that's not
	# a zero or a one, an assumption enforced in BUILD.)
	#
	(my $m0 = $mask) =~ s/[^01]/0/g;
	(my $m1 = $mask) =~ s/[^01]/1/g;
	$m0 = oct "0b" . $m0;
	$m1 = oct "0b" . $m1;

	for my $j (0 .. $#terms)
	{
		my $b = oct "0b" . $terms[$j];
		push @p, $j if ((($m0 & $b) == $m0) && (($m1 & $b) == $b));
	}

	return @p;
}

=head3 find_essentials()

Find the essential prime implicants in a primes table.

    my @essentials = find_essentials(\%primes);

=cut

sub find_essentials
{
	my($primes) = @_;

	my %essentials;
	my %bterms;

	#
	# Invert the hash-of-arrays
	#
	while (my($k, $v) = each %{$primes})
	{
		for my $term (@{ $v })
		{
			$bterms{$term} = [] unless (exists $bterms{$term});
			push @{$bterms{$term}}, $k;
		}
	}

	#
	# Find the term that can be covered by only one bit term. Those
	# terms are essentials.
	#
	for my $k (keys %bterms)
	{
		if (scalar @{ $bterms{$k}} == 1)
		{
			my @bt = @{ $bterms{$k}};
			$essentials{ ${ $bterms{$k}}[0]} = 1;
		}
	}

	return keys %essentials;
}

=head3 row_dominance()

Row dominance checking.

    @dominated_rows = row_dominance(\%primes, 0);

    @dominant_rows = row_dominance(\%primes, 1);

A row I<i> of a PI chart dominates row I<j> if row I<i> contains an x in each
column dominated by it.

A column I<p> of a PI chart dominates column I<q> if column I<p> contains an x
in each row dominated by it.

Return those rows (columns are handled by rotating the primes hash before
calling this function).

=cut

sub row_dominance
{
	my($primes, $dominant_rows) = @_;
	my @kp = keys %$primes;
	my %unique_rows;

	$dominant_rows //= 0;

	for my $row1 (@kp)
	{
		for my $row2 (@kp)
		{
			#
			# Skip if
			# 1) the same row, or
			# 2) the the rows have identical content, or
			# 3) row1's list isn't a subset of row2 (which means
			#    it isn't dominated by row2).
			#
			next if ($row1 eq $row2 or
				is_LequivalentR([ $primes->{$row1}, $primes->{$row2} ]) or
				!is_LsubsetR([ $primes->{$row1}, $primes->{$row2} ]));

			$unique_rows{(($dominant_rows)? $row1: $row2)} = 1;
		}
	}

	return keys %unique_rows;
}

=head3 covered_least()

Find the term with the fewest implicant covers, along with a list of
those covers.

    my($term, @covers) = covered_least(\%primes);

=cut

sub covered_least
{
	my($primes) = @_;
	my(@covers);

	#
	# Collect the bit terms that are within the hash's arrays.
	#
	my %bterms;
	$bterms{$_} += 1 for (map {@$_} values %{$primes});
	my @t = keys %bterms;

	#print STDERR "bit terms hash:\n";
	#for my $j (@t)
	#{
	#	print STDERR "\t$j => " . $bterms{$j} . "\n";
	#}
	#print STDERR "\n";

	#
	# Find out which keys in the primes hash
	# cover each term (that is, have the term
	# in each primes' arrays).
	#
	my @pkeys = keys %$primes;
	my $count = 1 + scalar @pkeys;
	my $term = "";

	#
	# Now find a term with the lowest number of covers.
	#
	for my $o (@t)
	{
		my $c = $bterms{$o};
		if ($c < $count)
		{
			$term = $o;
			$count = $c;
		}
	}

	for my $p (@pkeys)
	{
		push @covers, $p if any { $_ eq $term } @{ $primes->{$p} };
	}

	#print STDERR "covered_least() returns term ($term) and covers (" . join(", ", @covers) . ")\n";

	return ($term, @covers);
}

=head3 purge_elements()

    purge_elements(\%prime_implicants, @essentials);

Given a table of prime implicants, delete the list of elements (usually
the essential prime implicants) from the table, both row-wise and column-wise.

=cut

sub purge_elements
{
	my($primes, @ess) = @_;

	return 0 if (scalar @ess == 0 or scalar keys %$primes == 0);

	#
	# Delete the rows of each element,
	# then delete the columns associated with each element.
	#
	delete ${$primes}{$_} for @ess;

	return remels($primes, @ess);
}

=head3 remels()

Given a reference to a hash of arrayrefs and a reference to an array of
values, remove the values from the individual arrayrefs if the values
matches their masks.

Deletes the entire arrayref from the hash if the last element of the
array is removed.

    remels(\%primes, @elements);

Returns the number of removals made.

=cut

sub remels
{
	my ($href, @els) = @_;
	my $rems = 0;
	my @kp = keys %$href;

	for my $el (@els)
	{
		for my $k (@kp)
		{
			my @pos = maskedmatchindexes($el, @{$href->{$k}});
			$rems += scalar @pos;

			#
			# If it turns out that all the elements in the array
			# are to be removed, then just delete the entire
			# array reference.
			#
			if (scalar @pos == scalar @{$href->{$k}})
			{
				delete $href->{$k};
			}
			else
			{
				splice(@{$href->{$k}}, $_, 1) for (reverse sort @pos);
			}
		}
	}

	return $rems;
}

=head3 uniqels()

Returns the unique arrays from an array of arrays (i.e., we're
ensuring non-duplicate answers).

    my @uels = uniqels(@els);

=cut

sub uniqels
{
	my %h;
	return map { $h{ join(",", @{$_}) }++ == 0 ? $_ : () } @_;
}

=head3 transpose()

Transposes a hash-of-arrays structure of the type used for %primes.

    my %table90 = transpose(\%table)

=cut

sub transpose
{
	my($table) = @_;
	my(%r90, %hoh);

	#
	# Set up a hash-of-hashes, inverting the
	# key to array-of-values relationship.
	#
	for my $r (keys %{$table})
	{
		$hoh{$_}{$r} = 1 for (@{$table->{$r}});
	}

	#
	# For each key collect those sub-hash keys into arrays.
	#
	%r90 = map{ ($_ , [ keys %{$hoh{$_}} ]) } keys %hoh;

	return %r90;
}

=head3 hammingd1pos()

Very specialized Hamming distance and position function.

Our calling code is only interested in Hamming distances of 1.
In those cases return the string position where the two values differ.
In all the other cases where the distance isn't one, return a -1.

    $idx = hammingd1pos($val1, $val2);

=cut

sub hammingd1pos
{
	#
	# Xor the strings. The result will be a string in the
	# non-printing range (in fact equal characters will result
	# in a null character), so to each character Or a '0'.
	#
	my $v = ($_[0] ^ $_[1]) | (qq(\x30) x length $_[0]);

	#
	# Strings that don't have a Hamming distance of one are of no
	# interest. Otherwise, return that character position.
	#
	return -1 unless(scalar(() = $v=~ m/[^0]/g) == 1);

	$v =~ m/[^0]/g;
	return pos($v) - 1;
}

=head1 SEE ALSO

L<Algorithm::QuineMcCluskey>

=head1 AUTHOR

Darren M. Kulp C<< <darren@kulp.ch> >>

John M. Gamble B<jgamble@cpan.org> (current maintainer)

=head1 LICENSE AND COPYRIGHT

Copyright (c) 2006 Darren Kulp. All rights reserved. This program is
free software; you can redistribute it and/or modify it under the same
terms as Perl itself.

See L<http://dev.perl.org/licenses/> for more information.

=cut

1;

__END__

