package AI::CBR::Sim;

use warnings;
use strict;

use Exporter;
our @ISA = ('Exporter');
our @EXPORT_OK = qw(sim_dist sim_frac sim_eq sim_set);


=head1 NAME

AI::CBR::Sim - collection of basic similarity functions


=head1 SYNOPSIS

Import similarity functions for case construction.

    use AI::CBR::Sim qw(sim_dist sim_eq);

    ...
    ...


=head1 EXPORT

=over 4

=item * sim_dist

=item * sim_frac

=item * sim_eq

=item * sim_set

=back


=head1 FUNCTIONS

=head2 sim_dist

Works for any numeric values.
Suitable when you are interested into the difference of values in a given range.
Returns the fraction of the difference of the values with respect to a given maximum range of interest.
The madatory third argument is this range.

	sim_dist(26, 22, 10); # returns 0.4
	sim_dist(-2, 1, 100); # returns 0.03

=cut

sub sim_dist {
	my ($a, $b, $range) = @_;
	return 1 if $a == $b;
	my $dist = abs($a - $b);
	return 0 if $dist >= $range;
	return 1 - $dist / $range;
}


=head2 sim_frac

Works for non-negative numeric values.
Suitable when you are only interested into their relative difference with respect to 0.
Returns the fraction of the smaller argument with respect to the higher one.

	sim_frac(3, 2); # returns 0.67
	sim_frac(40, 50); # returns 0.8

=cut

sub sim_frac {
	my ($a, $b) = @_;
	return 1 if $a == $b;
	return 0 if $a * $b == 0;
	return $a > $b ? $b / $a : $a / $b;
}


=head2 sim_eq

Works for any textual value.
Suitable when you are interested only into equality/inequality.
Returns 1 in case of equality, 0 in case of inequality.
No third argument.

	sim_eq('foo', 'bar'); # returns 0
	sim_eq('foo', 'foo'); # returns 1

=cut

sub sim_eq {
	return $_[0] eq $_[1] ? 1 : 0;
}


=head2 sim_set

Works for sets/lists of textual values.
Suitable when you are interested into overlap of the two sets.
Arguments are two array references with textual values.
Returns the number of elements in the intersection
divided by the number of elements in the union.
No third argument.

	sim_set([qw/a b c/], [qw/b c d/]); # returns 0.5
	sim_set([qw/a b c/], [qw/c/]); # returns 0.33

=cut

sub sim_set {
	my ($a, $b) = @_;
	return 1 if int @$a == 0 && int @$b == 0;
	return 0 unless int @$a && int @$b;
	my %a = map { ($_ => 1) } @$a;
	my $union = int keys %a;
	my $intersection = 0;
	map {
		$a{$_} ? $intersection++ : $union++
	} @$b;
	return $intersection / $union;
}


=head1 SEE ALSO

See L<AI::CBR> for an overview of the framework.


=head1 AUTHOR

Darko Obradovic, C<< <dobradovic at gmx.de> >>

=head1 BUGS

Please report any bugs or feature requests to C<bug-ai-cbr at rt.cpan.org>, or through
the web interface at L<http://rt.cpan.org/NoAuth/ReportBug.html?Queue=AI-CBR>.  I will be notified, and then you'll
automatically be notified of progress on your bug as I make changes.




=head1 SUPPORT

You can find documentation for this module with the perldoc command.

    perldoc AI::CBR::Sim


You can also look for information at:

=over 4

=item * RT: CPAN's request tracker

L<http://rt.cpan.org/NoAuth/Bugs.html?Dist=AI-CBR>

=item * AnnoCPAN: Annotated CPAN documentation

L<http://annocpan.org/dist/AI-CBR>

=item * CPAN Ratings

L<http://cpanratings.perl.org/d/AI-CBR>

=item * Search CPAN

L<http://search.cpan.org/dist/AI-CBR>

=back


=head1 COPYRIGHT & LICENSE

Copyright 2009 Darko Obradovic, all rights reserved.

This program is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.


=cut

1; # End of AI::CBR::Sim
