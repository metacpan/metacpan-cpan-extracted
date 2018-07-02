=head1 NAME

Algorithm::QuineMcCluskey::Util - provide utility functions to
Algorithm::QuineMcCluskey

=cut

package Algorithm::QuineMcCluskey::Util;

use strict;
use warnings;
use 5.010001;

use List::MoreUtils qw(any pairwise indexes uniq firstidx);
use List::Compare::Functional qw(is_LequivalentR is_LsubsetR);

use Exporter;
our @ISA = qw(Exporter);

our %EXPORT_TAGS = (
	all => [ qw(
		columns
		countels
		diffpos
		find_essentials
		hdist
		least_covered
		maskedmatch
		matchcount
		purge_elements
		remels
		row_dominance
		uniqels
	) ],
);

our @EXPORT_OK = (
	@{ $EXPORT_TAGS{all} }
);

our $VERSION = 0.17;

=head1 DESCRIPTION

This module provides various utilities designed for (but not limited to) use in
Algorithm::QuineMcCluskey.

The prime implicant and essentials "tables" are in the form of a hash of
array refs, and are manipulated with the functions columns(), find_essentials(),
least_covered(), purge_elements(), remels(), row_dominance(), and uniqels().

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

=head3 find_essentials()

Find the essential prime implicants in a primes table, filtered
by a list of terms.

      my $ess = find_essentials(\%primes, @terms);

=cut

sub find_essentials
{
	my($primes, @terms) = @_;

	my @kp = keys %$primes;
	my %essentials;

	for my $term (@terms)
	{
		my @tp = grep {
				grep { $_ eq $term } @{ $primes->{$_} }
			} @kp;

		#
		# TODO: It would be nice to track the terms that make
		# this essential
		if (scalar @tp == 1)
		{
			$essentials{$tp[0]}++;
		}
	}

	return %essentials;
}

=head3 row_dominance()

Row dominance checking.

@dominated_rows = row_dominance(\%primes, 0);
@dominant_rows = row_dominance(\%primes, 1);

A row (column) I<i> of a PI chart dominates row (column) I<j>
if row (column) I<i> contains an x in each column (row) dominated by it.

Return those rows (columns are handled by rotating the primes hash before
calling this function).

=cut

sub row_dominance
{
	my($primes, $dominant_rows) = @_;
	my @kp = keys %$primes;
	my @rows;

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
				is_LequivalentR([ $primes->{$row1} => $primes->{$row2} ]) or
				!is_LsubsetR([ $primes->{$row1} => $primes->{$row2} ]));

			push @rows, (($dominant_rows)? $row1: $row2);
		}
	}

	return uniq(@rows);
}

=head3 least_covered()

Find the term with the fewest implicant covers.

      my $t = least_covered(\%primes, @terms);

=cut

sub least_covered
{
	my($primes, @bit_terms) = @_;

	my @t = grep {
		my $o = $_;
		any { countels( $o, $_ ) } values %{$primes}
	} @bit_terms;

	#
	# Flip the table so that terms become keys, limited
	# to those found in @t.
	#
	my %ic = columns($primes, @t);

	#
	# Sort by count of the array items.
	#
	return (sort { @{ $ic{$a} } <=> @{ $ic{$b} } } keys %ic)[0];
}

=head3 purge_elements()

      purge_elements(\%prime_implicants, @essentials);

Given a table of prime implicants, delete the list of elements (usually
the essential prime implicants) from the table, both row-wise and column-wise.

=cut

sub purge_elements
{
	my($primes, @ess) = @_;
	my $count = 0;

	return $count if (scalar @ess == 0 or scalar keys %$primes == 0);

	#
	# Delete the rows of each element,
	# then delete the columns associated with each element.
	#
	delete ${$primes}{$_} for @ess;

	for my $el (@ess)
	{
		$count += remels($el, $primes);
	}

	if ($count != 0)
	{
	}
	return $count;
}

=head3 remels()

Given a value and a reference to a hash of arrayrefs, remove the value
from the individual arrayrefs if the value matches the masks.

Deletes the entire arrayref from the hash if the last element of the
array is removed.

      remels($element, \%primes);

Returns the number of removals made.

=cut

sub remels
{
	my ($el, $href) = @_;
	my $rems = 0;
	my @kp = keys %$href;

	for my $k (@kp)
	{
		my @pos = indexes { maskedmatch($el, $_) } @{$href->{$k}};
		for my $pos (reverse @pos)
		{
			if (scalar @{$href->{$k}} == 1)
			{
				delete $href->{$k};
				$rems++;
				last;
			}
			else
			{
				splice(@{$href->{$k}}, $pos, 1);
				$rems++;
			}
		}
	}

	return $rems;
}

=head3 countels()

Returns a count of all elements in the array ref that are equal to $el.

      my $c = countels($el, \@array);

=cut

sub countels
{
	my($el, $aref) = @_;

	return 0 unless (@$aref);
	return scalar grep { $_ eq $el } @$aref;
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

=head3 columns()

Rotates 90 degrees a hashtable of the type used for %primes, using
only @columms.

      my %table90 = columns(\%table, @columns)

=cut

sub columns
{
	my ($r, @c) = @_;
	my %r90;
	for my $o (@c)
	{
		my @t = grep {
			any { $_ eq $o } @{ $r->{$_} }
		} keys %$r;

		$r90{$o} = [@t] if (scalar @t);
	}
	return %r90;
}

=head3 diffpos()

Find the location of the first difference between two strings

      my $p = diffpos($str1, $str2);

=cut

sub diffpos
{
	return firstidx { $_ } pairwise { $a ne $b }
			@{[ split(//, shift)]},
			@{[ split(//, shift)]};
}

=head3 hdist()

Return the Hamming distance between two strings.

      $d = hdist($str1, $str2);

=cut

sub hdist
{
	my $x = 0;

	pairwise { $x += ($a ne $b) }
			@{[ split(//, shift)]},
			@{[ split(//, shift)]};
	return $x;
}

=head1 SEE ALSO

L<Algorithm::QuineMcCluskey>

=head1 AUTHOR

Darren M. Kulp C<< <darren@kulp.ch> >>

=cut

1;

__END__

