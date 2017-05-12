use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Breeder - Even more customizable single generation for an evolutionary algorithm.
                 
=head1 SYNOPSIS

    use Algorithm::Evolutionary qw( Individual::BitString 
    Op::Mutation Op::Crossover
    Op::RouletteWheel
    Op::Breeder);

    use Algorithm::Evolutionary::Utils qw(average);

    my @pop;
    my $number_of_bits = 20;
    my $population_size = 20;
    my $replacement_rate = 0.5;
    for ( 1..$population_size ) {
      my $indi = new Algorithm::Evolutionary::Individual::BitString $number_of_bits ; #Creates random individual
      $indi->evaluate( $onemax );
      push( @pop, $indi );
    }

    my $m =  new Algorithm::Evolutionary::Op::Mutation 0.5;
    my $c = new Algorithm::Evolutionary::Op::Crossover; #Classical 2-point crossover

    my $selector = new Algorithm::Evolutionary::Op::RouletteWheel $population_size; #One of the possible selectors

    my $generation = 
      new Algorithm::Evolutionary::Op::Breeder( $selector, [$m, $c] );

    my @sortPop = sort { $b->Fitness() <=> $a->Fitness() } @pop;
    my $bestIndi = $sortPop[0];
    my $previous_average = average( \@sortPop );
    $generation->apply( \@sortPop );

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Breeder part of the evolutionary algorithm; takes a population and returns another created from the first

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Breeder;

use lib qw(../../..);

our $VERSION = '1.4';

use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

use Algorithm::Evolutionary qw(Wheel
			       Op::Tournament_Selection);

# Class-wide constants
our $APPLIESTO =  'ARRAY';
our $ARITY = 1;

=head2 new( $ref_to_operator_array[, $selector = new Algorithm::Evolutionary::Op::Tournament_Selection 2 ] )

Creates a breeder, with a selector and array of operators

=cut

sub new {
  my $class = shift;
  my $self = {};
  $self->{'_ops'} = shift || croak "No operators found";
  $self->{'_selector'} = shift 
    || new Algorithm::Evolutionary::Op::Tournament_Selection 2;
  bless $self, $class;
  return $self;
}

=head2 apply( $population[, $how_many || $population_size] )

Applies the algorithm to the population, which should have
been evaluated first; checks that it receives a
ref-to-array as input, croaks if it does not. 

Returns a sorted, culled, evaluated population for next generation.

=cut

sub apply {
    my $self = shift;
    my $pop = shift || croak "No population here";
    my $output_size = shift || @$pop; # Defaults to pop size
    my @ops = @{$self->{'_ops'}};

    #Select for breeding
    my $selector = $self->{'_selector'};
    my @genitors = $selector->apply( $pop );

    #Reproduce
    my $totRate = 0;
    my @rates;
    for ( @ops ) {
	push( @rates, $_->{'rate'});
    }
    my $opWheel = new Algorithm::Evolutionary::Wheel @rates;

    my @new_population;
    for ( my $i = 0; $i < $output_size; $i++ ) {
	my @offspring;
	my $selectedOp = $ops[ $opWheel->spin()];
	for ( my $j = 0; $j < $selectedOp->arity(); $j ++ ) {
	    my $chosen = $genitors[ rand( @genitors )];
#		print "Elegido ", $chosen->asString(), "\n";
	    push( @offspring, $chosen->clone() );
	}
	my $mutante = $selectedOp->apply( @offspring );
	push( @new_population, $mutante );
    }
    
    return \@new_population;
}

=head1 SEE ALSO

More or less in the same ballpark, alternatives to this one

=over 4

=item * 

L<Algorithm::Evolutionary::Op::GeneralGeneration>

=item *

L<Algorithm::Evolutionary::Op::Breeder_Diverser>

=item *

L<Algorithm::Evolutionary::Op::Generation_Skeleton> does have a incompatible interface

=back

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut

"The truth is out there";
