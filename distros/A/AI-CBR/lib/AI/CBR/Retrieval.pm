package AI::CBR::Retrieval;

use warnings;
use strict;

use List::Util qw(min);

=head1 NAME

AI::CBR::Retrieval - retrieve similar cases from a case-base


=head1 SYNOPSIS

Retrieve solutions for a case from a case-base

    use AI::CBR::Retrieval;

    my $r = AI::CBR::Retrieval->new($case, \@case_base);
    $r->compute_sims();
    my $solution = $r->most_similar_case();
    ...

=head1 METHODS

=head2 new

Creates a new object for retrieval.
Pass your case specification object as the first parameter.
Pass the reference of an array of hash references as the case-base.
The hashes should contain all attributes of the specification.
These will be called candidate cases internally.

=cut

sub new {
	my ($classname, $spec, $candidates) = @_;
	croak('new case without candidates') unless @$candidates;
	my $self = {
		candidates => $candidates,
		# we accept single specs as hash-ref or composed specs as array-ref
		# internally both will be handled as a composed array-ref
		queries    => ref $spec eq 'AI::CBR::Case' ? [$spec] : $spec,
	};
	bless $self, $classname;
	return $self;
}


=head2 compute_sims

If the case-specification is complete,
you may call this method to compute the similarities
of all candidate cases to this specification.
After this step, each candidate of the case-base will have an
additional attribute C<_sim> indicating the similarity.

=cut

sub compute_sims {
	my ($self) = @_;
	
	# pre-allocate variables used in loop
	my ($sum_sims, $sum_weights, $att_key, $att, $weight, $x, $y);
	
	my $num_queries = int @{$self->{queries}};
	foreach my $candidate (@{$self->{candidates}}) {
		$candidate->{_sim} = 1;
		foreach my $query (@{$self->{queries}}) {
			$sum_sims = 0;
			$sum_weights = 0;
			
			ATTRIBUTES:
			while(($att_key, $att) = each(%{$query})) {
				next ATTRIBUTES unless $weight = $att->{weight};
				$sum_weights += $weight;
				$x = $att->{value};
				$y = $candidate->{$att_key};
				$sum_sims += $weight * (
					  !defined $x && !defined $y ? 1
					: !defined $x || !defined $y ? 0
					: &{$att->{sim}}($x, $y, $att->{param} || 0)
				);
			}
			
			$candidate->{_sim} *= _nrt($num_queries, $sum_sims / $sum_weights);
		}
	}
	my @candidates_sorted = sort { $b->{_sim} <=> $a->{_sim} } @{$self->{candidates}};
	$self->{candidates} = \@candidates_sorted;
}


=head2 RETRIEVAL METHODS

Use one of these methods to get the similar cases you are interested into.

=head3 most_similar_candidate

Returns the most similar candidate.
No parameters.

=cut

sub most_similar_candidate {
	my ($self) = @_;
	return $self->{candidates}->[0];
}

=head3 n_most_similar_candidates

Returns the n most similar candidates.
n is the only parameter.

=cut

sub n_most_similar_candidates {
	my ($self, $n) = @_;
	my $last_index = min($n - 1, int @{$self->{candidates}});
	return map { $self->{candidates}->[$_] } (0 .. $last_index);
}

=head3 first_confirmed_candidate

Returns the first candidate that is confirmed by a later candidate.
Confirmation is based on an attribute value
whose key is passed as parameter.
In case there is no confirmed candidate at all,
simply returns the most similar one.

=cut

sub first_confirmed_candidate {
	my ($self, $key) = @_;
	my %candidate_with;
	my $value;
	foreach my $candidate (@{$self->{candidates}}) {
		$value = $candidate->{$key};
		if($candidate_with{$value}) {
			return $candidate_with{$value};
		} else {
			$candidate_with{$value} = $candidate;
		}
	}

	# no confirmed candidate found, fall back
	return $self->most_similar_candidate();
}


# internal method for n-th root
sub _nrt {
	return $_[1] ** (1 / $_[0]);
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

    perldoc AI::CBR::Retrieval


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

1; # End of AI::CBR::Retrieval
