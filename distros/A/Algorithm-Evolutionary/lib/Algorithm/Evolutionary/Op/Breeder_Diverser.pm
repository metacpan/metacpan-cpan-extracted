use strict;
use warnings;

=head1 NAME
Algorithm::Evolutionary::Op::Breeder_Diverser - Like Breeder, only it tries to cross only individuals that are different 

=head1 SYNOPSIS

    use Algorithm::Evolutionary qw( Individual::BitString 
      Op::Mutation Op::Crossover
      Op::RouletteWheel
      Op::Breeder_Diverser);

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
      new Algorithm::Evolutionary::Op::Breeder_Diverser( $selector, [$m, $c] );

    my @sortPop = sort { $b->Fitness() <=> $a->Fitness() } @pop;
    my $bestIndi = $sortPop[0];
    my $previous_average = average( \@sortPop );
    $generation->apply( \@sortPop );

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Breeder part of the evolutionary algorithm; takes a population and
returns another created from the first. Different from
L<Algorithm::Evolutionary::Op::Breeder>: tries to avoid crossover
among the same individuals and also re-creating an individual already
in the pool. In that sense it "diverses", tries to diversify the
population. In general, it works better in environments where high
diversity is needed (like, for instance, in L<Algorithm::MasterMind>.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Breeder_Diverser;

use lib qw(../../..);

our ($VERSION) = ( '$Revision: 1.7 $ ' =~ / (\d+\.\d+)/ ) ;

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
  $self->{_ops} = shift || croak "No operators found";
  $self->{_selector} = shift 
    || new Algorithm::Evolutionary::Op::Tournament_Selection 2;
  bless $self, $class;
  return $self;
}

=head2 apply( $population[, $how_many || $population_size] )

Applies the algorithm to the population, which should have
been evaluated first; checks that it receives a
ref-to-array as input, croaks if it does not. Returns a sorted,
culled, evaluated population for next generation.

It is valid only for string-denominated chromosomes. Checks that the
offspring is different from parents before inserting it. 

=cut

sub apply ($) {
    my $self = shift;
    my $pop = shift || croak "No population here";
    my $output_size = shift || @$pop; # Defaults to pop size
    my @ops = @{$self->{_ops}};

    #Select for breeding
    my $selector = $self->{_selector};
    my @genitors = $selector->apply( $pop );

    #Reproduce
    my $totRate = 0;
    my @rates;
    for ( @ops ) {
	push( @rates, $_->{rate});
    }
    my $op_wheel = new Algorithm::Evolutionary::Wheel @rates;

    my @new_population;
    my $i = 0;
    while ( @new_population < $output_size ) {
      my @offspring;
      my $selected_op = $ops[ $op_wheel->spin()];
      my $chosen = $genitors[ $i++ % @genitors]; #Chosen in turn
      push( @offspring, $chosen->clone() );
      if( $selected_op->{'_arity'} == 2 ) {
	my $another_one;
	do {
	  $another_one = $genitors[ rand( @genitors )];
	} until ( $another_one->{'_str'} ne  $chosen->{'_str'} );
	push( @offspring, $another_one );
      } elsif ( $selected_op->{'_arity'} > 2 ) {
	for ( my $j = 1; $j < $selected_op->arity(); $j ++ ) {
	  my $chosen = $genitors[ rand( @genitors )];
	  push( @offspring, $chosen->clone() );
	}
      }
      my $mutant = $selected_op->apply( @offspring );
      my $equal;
      for my $o (@offspring) {
	$equal += $o->{'_str'} eq  $mutant->{'_str'};
      }
      if ( !$equal ) {
	push( @new_population, $mutant );
      } 

    }
    return \@new_population;
}

=head1 SEE ALSO

More or less in the same ballpark, alternatives to this one

=over 4

=item * 

L<Algorithm::Evolutionary::Op::GeneralGeneration>

=item * 

L<Algorithm::Evolutionary::Op::Breeder>

=back

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2013/01/07 13:54:20 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Breeder_Diverser.pm,v 1.7 2013/01/07 13:54:20 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 1.7 $

=cut

"The truth is out there";
