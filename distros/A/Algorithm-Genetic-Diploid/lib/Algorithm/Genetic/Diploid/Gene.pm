package Algorithm::Genetic::Diploid::Gene;
use strict;
use Algorithm::Genetic::Diploid::Base;
use base 'Algorithm::Genetic::Diploid::Base';

=head1 NAME

Algorithm::Genetic::Diploid::Gene - a gene with an expressible function

=head1 METHODS

=over

=item new

Constructor takes named arguments, sets a default value of 1 for the weight

=cut

sub new {
	shift->SUPER::new(
		'weight' => 1,
		@_,
	);
}

=item function

The gene function is a subroutine ref that results in a gene product (representing some
component of fitness) based on environmental input

=cut

sub function {
	my $self = shift;
	$self->make_function;
}

=item express

A gene is expressed based on environmental input, upon which a gene product is returned

=cut

sub express {
	my ( $self, $env ) = @_;
	return $self->function->($env);
}

=item mutate

Re-weights the gene in proportion to the mutation rate

=cut

sub mutate {
	my ( $self, $func ) = @_;
	my $mu = $self->experiment->mutation_rate;
	my $scale = rand($mu) - $mu / 2 + 1;
	my $weight = $self->weight;
	$self->weight( $weight * $scale );
	$self->function( $func ) if $func;
	return $self;
}

=item weight

Getter and setter for the weight of this gene product in the total phenotype

=cut

sub weight {
	my $self = shift;
	$self->{'weight'} = shift if @_;
	return $self->{'weight'};
}

=back

=cut

1;