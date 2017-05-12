use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Canonical_GA_NN - Canonical Genetic
                 Algorithm that does not rank population

=head1 SYNOPSIS

  # Straightforward instance, with all defaults (except for fitness function)
  my $algo = new Algorithm::Evolutionary::Op::Canonical_GA_NN; 

  #Define an easy single-generation algorithm with predefined mutation and crossover
  my $m = new Algorithm::Evolutionary::Op::Bitflip; #Changes a single bit
  my $c = new Algorithm::Evolutionary::Op::QuadXOver; #Classical 2-point crossover
  my $generation = new Algorithm::Evolutionary::Op::Canonical_GA_NN( 0.2, [$m, $c] );

   my $generation = new Algorithm::Evolutionary::Op::Canonical_GA_NN( undef , [$m, $c] ); # Defaults to 0.4

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

This is a fast version of the canonical GA, useful for large
populations, since it avoids the expensive rank operation. Roulette
wheel selection, still, is kind of slow.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Canonical_GA_NN;

use lib qw(../../..);

our $VERSION =   "3.6";

use Carp;

use Algorithm::Evolutionary qw(Wheel
			       Op::Bitflip
			       Op::QuadXOver );

use base 'Algorithm::Evolutionary::Op::Easy';

# Class-wide constants
our $APPLIESTO =  'ARRAY';
our $ARITY = 1;

=head2 new( [ $selection_rate][,$operators_ref_to_array] )

Creates an algorithm, with the usual operators. Includes a default
mutation and crossover, in case they are not passed as parameters. The
first element in the array ref should be an unary, and the second a
binary operator. This binary operator must accept parameters by
reference, not value; it will modify them. For the time being, just
L<Algorithm::Evolutionary::Op::QuadXOver> works that way. 

=cut

sub new {
  my $class = shift;
  my $self = {};
  $self->{'_selrate'} = shift || 0.4;
  if ( @_ ) {
      $self->{_ops} = shift;
  } else {
      #Create mutation and crossover
      my $mutation = new Algorithm::Evolutionary::Op::Bitflip;
      push( @{$self->{_ops}}, $mutation );
      my $xover = new Algorithm::Evolutionary::Op::QuadXOver 2;
      push( @{$self->{_ops}}, $xover );
  }
  bless $self, $class;
  return $self;

}

=head2 apply( $population) 

Applies a single generation of the algorithm to the population; checks
that it receives a ref-to-array as input, croaks if it does not. This
population should be already evaluated. Returns a new population for
next generation, unsorted.

=cut

sub apply ($) {
  my $self = shift;
  my $pop = shift || croak "No population here";
  croak "Incorrect type ".(ref $pop) if  ref( $pop ) ne $APPLIESTO;

  my @newPop;
  @$pop = sort { $b->{_fitness} <=> $a->{_fitness} } @$pop;
  my @rates = map( $_->Fitness(), @$pop );

  #Creates a roulette wheel from the op priorities. Theoretically,
  #they might have changed 
  my $popWheel= new Algorithm::Evolutionary::Wheel @rates;
  my $popSize = scalar @$pop;
  my @ops = @{$self->{_ops}};
  for ( my $i = 0; $i < $popSize*(1-$self->{'_selrate'})/2; $i ++ ) {
    my @selected = $popWheel->spin(2);
    my @clones;
    # This should be a mutation-like op which does not modify arg
    for my $c (0..1) {
      $clones[$c] = $ops[0]->apply( $pop->[$selected[$c]] ); 
    }

    $ops[1]->apply( @clones ); #This should be a
    #crossover-like op
    push @newPop, @clones;
  }
  #Re-sort
  @{$pop}[$popSize*$self->{_selrate}..$popSize-1] =  @newPop;
}


=head1 SEE ALSO

=over 4

=item L<Algorithm::Evolutionary::Op::Easy>

=item L<Algorithm::Evolutionary::Wheel>

=item L<Algorithm::Evolutionary::Fitness::Base>

=item Of course, L<Algorithm::Evolutionary::Fitness::CanonicalGA>

=back

You will also find a
    L<canonical-genetic-algorithm.pl> example within this
    bundle. Check it out for usage examples

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut

"The truth is out there";
