=head1 NAME

Algorithm::QuineMcCluskey::Format - provide formatting functions to
Algorithm::QuineMcCluskey

=cut

package Algorithm::QuineMcCluskey::Format;

use strict;
use warnings;
use 5.016001;

use List::Util qw(any uniqstr);

use Exporter;
our @ISA = qw(Exporter);

our @EXPORT_OK = qw(arrayarray hasharray chart);

our $VERSION = 1.01;

=head1 DESCRIPTION

This module provides formatting utilities designed for (but not limited
to) use in Algorithm::QuineMcCluskey.

=cut

=head1 FUNCTIONS

=head3 arrayarray()

Returns a more compact string form of the covers structure.

=cut

sub arrayarray
{
	my ($ar) = @_;
	my $fmt = "%" . length(scalar @{$ar}) . "d: [%s]";
	my $idx = 0;
	my @output;

	for my $ref (@{$ar})
	{
		push @output, sprintf($fmt, $idx, (defined $ref)? join(", ", @{ $ref }): " ");
		$idx++;
	}

	return "\n" . join("\n", @output);
}

=head3 hasharray()

Returns a more compact string form of primes structure.

=cut

sub hasharray
{
	my ($hr) = @_;
	my @output;

	for my $r (sort setbit_cmp keys %$hr)
	{
		push @output, "$r => [" . join(", ", @{ $hr->{$r} }) . "]";
	}

	return "\n" . join("\n", @output);
}

=head3 chart()

    $chart = chart(\%prime_implicants, $width);

Return a string that interprets the primes' hash-of-array structure
into a column and row chart usable for visual searching of essential prime
implicants.

=cut

sub chart
{
	my($hr, $width) = @_;

	my @rows = sort setbit_cmp keys %$hr;
	my @columns = sort(uniqstr(map{ @{ $hr->{$_} } } @rows));
	my $fmt = "%" . ($width+2) . "s";
	my @output;

	push @output, join("", map{sprintf($fmt, $_)} ' ', @columns);

	#
	# Having set up our list of row and column headers, check
	# to see which column values are present in each row.
	#
	for my $r (@rows)
	{
		my @present = map {my $v = $_; (any{$v eq $_} @{ $hr->{$r} }) } @columns;

		my @marks = map{ sprintf($fmt, $_? 'x': '.') } @present;

		push @output, join("", sprintf($fmt, $r), @marks);
	}

	return join("\n", @output);
}

=head3 setbit_cmp()

=head3 unsetbit_cmp()

Comparison function for sort() that orders the rows in the chart() 
and hasharray() functions.

=cut

sub setbit_cmp
{
	my $a1 = scalar(() = $a=~ m/1/g);
	my $b1 = scalar(() = $b=~ m/1/g);
	return (($a1 <=> $b1) || ($a cmp $b));
}

sub unsetbit_cmp
{
	my $a0 = scalar(() = $a=~ m/0/g);
	my $b0 = scalar(() = $b=~ m/0/g);
	return (($a0 <=> $b0) || ($a cmp $b));
}

=head1 SEE ALSO

L<Algorithm::QuineMcCluskey>

=head1 AUTHOR

John M. Gamble B<jgamble@cpan.org>

=cut

1;

__END__

