use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::CanonicalGA - Canonical Genetic Algorithm, with any representation

=head1 SYNOPSIS

  # Straightforward instance, with all defaults (except for fitness function)
  my $algo = new Algorithm::Evolutionary::Op::CanonicalGA( $eval ); 

  #Define an easy single-generation algorithm with predefined mutation and crossover
  my $m = new Algorithm::Evolutionary::Op::Bitflip; #Changes a single bit
  my $c = new Algorithm::Evolutionary::Op::QuadXOver; #Classical 2-point crossover
  my $generation = new Algorithm::Evolutionary::Op::CanonicalGA( $rr, 0.2, [$m, $c] );

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

The canonical classical genetic algorithm evolves a population of
bitstrings until they reach the optimum fitness. It performs mutation
on the bitstrings by flipping a single bit, crossover interchanges a
part of the two parents.

The first operator should be unary (a la mutation) and the second
binary (a la crossover) they will be applied in turn to couples of the
population.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::CanonicalGA;

use lib qw(../../..);

our $VERSION =   '3.6';

use Carp;

use Algorithm::Evolutionary qw(Wheel
			       Op::Bitflip
			       Op::QuadXOver );

use base 'Algorithm::Evolutionary::Op::Easy';

# Class-wide constants
our $APPLIESTO =  'ARRAY';
our $ARITY = 1;

=head2 new( $fitness[, $selection_rate][,$operators_ref_to_array] )

Creates an algorithm, with the usual operators. Includes a default mutation
and crossover, in case they are not passed as parameters. The first
    element in the array ref should be an unary, and the second a
    binary operator.

=cut

sub new {
  my $class = shift;
  my $self = {};
  $self->{_eval} = shift || croak "No eval function found";
  $self->{_selrate} = shift || 0.4;
  if ( @_ ) {
      $self->{_ops} = shift;
  } else {
      #Create mutation and crossover
      my $mutation = new Algorithm::Evolutionary::Op::Bitflip;
      push( @{$self->{_ops}}, $mutation );
      my $xover = new Algorithm::Evolutionary::Op::QuadXOver;
      push( @{$self->{_ops}}, $xover );
  }
  bless $self, $class;
  return $self;

}

=head2 apply( $population) 

Applies a single generation of the algorithm to the population; checks
that it receives a ref-to-array as input, croaks if it does
not. Returns a sorted, culled, evaluated population for next
generation.

=cut

sub apply ($) {
  my $self = shift;
  my $pop = shift || croak "No population here";
  croak "Incorrect type ".(ref $pop) if  ref( $pop ) ne $APPLIESTO;

  my $eval = $self->{_eval};
  for ( @$pop ) {
    if ( !defined ($_->Fitness() ) ) {
	$_->evaluate( $eval );
    }
  }

  my @newPop;
  @$pop = sort { $b->{_fitness} <=> $a->{_fitness} } @$pop;
  my @rates = map( $_->Fitness(), @$pop );

  #Creates a roulette wheel from the op priorities. Theoretically,
  #they might have changed 
  my $popWheel= new Algorithm::Evolutionary::Wheel @rates;
  my $popSize = scalar @$pop;
  my @ops = @{$self->{_ops}};
  for ( my $i = 0; $i < $popSize*(1-$self->{_selrate})/2; $i ++ ) {
      my $clone1 = $ops[0]->apply( $pop->[$popWheel->spin()] ); # This should be a mutation-like op
      my $clone2 = $ops[0]->apply( $pop->[$popWheel->spin()] );
      $ops[1]->apply( $clone1, $clone2 ); #This should be a
                                          #crossover-like op
      $clone1->evaluate( $eval );
      $clone2->evaluate( $eval );
      push @newPop, $clone1, $clone2;
  }
  #Re-sort
  @{$pop}[$popSize*$self->{_selrate}..$popSize-1] =  @newPop;
  @$pop = sort { $b->{_fitness} <=> $a->{_fitness} } @$pop;
}

=head1 SEE ALSO

=over 4

=item L<Algorithm::Evolutionary::Op::Easy>

=item L<Algorithm::Evolutionary::Wheel>

=item L<Algorithm::Evolutionary::Fitness::Base>

=back

Probably you will also be able to find a
    L<canonical-genetic-algorithm.pl> example within this
    bundle. Check it out for usage examples

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut

"The truth is out there";
