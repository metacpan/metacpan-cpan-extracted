use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::EDA_step - Single step for a Estimation of Distribution Algorithm
                 
=head1 SYNOPSIS

    use Algorithm::Evolutionary qw( Individual::BitString 
				Op::Mutation Op::Crossover
				Op::RouletteWheel
				Fitness::ONEMAX Op::EDA_step
				Op::Replace_Worst);

    use Algorithm::Evolutionary::Utils qw(average);

    my $onemax = new Algorithm::Evolutionary::Fitness::ONEMAX;

    my @pop;
    my $number_of_bits = 20;
    my $population_size = 20;
    my $replacement_rate = 0.5;
    for ( 1..$population_size ) {
      my $indi = new Algorithm::Evolutionary::Individual::BitString $number_of_bits ; #Creates random individual
      $indi->evaluate( $onemax );
      push( @pop, $indi );
    }

    my $selector = new Algorithm::Evolutionary::Op::RouletteWheel $population_size; #One of the possible selectors

    my $generation = 
      new Algorithm::Evolutionary::Op::EDA_step( $onemax, $selector, $replacement_rate );

    my @sortPop = sort { $b->Fitness() <=> $a->Fitness() } @pop;
    my $bestIndi = $sortPop[0];
    my $previous_average = average( \@sortPop );
    $generation->apply( \@sortPop );

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Estimation of Distribution Algorithms shun operators and instead try
to model the distribution of "good" solutions in the population. This
version corresponds to the most basic one.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::EDA_step;

use lib qw(../../..);

our ($VERSION) = ( '$Revision: 1.5 $ ' =~ / (\d+\.\d+)/ ) ;

use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

use Algorithm::Evolutionary qw(Hash_Wheel Individual::String);

# Class-wide constants
our $APPLIESTO =  'ARRAY';
our $ARITY = 1;

=head2 new( $evaluation_function, $replacement_rate )

Creates an algorithm, with no defaults except for the default
replacement operator (defaults to L<Algorithm::Evolutionary::Op::ReplaceWorst>)

=cut

sub new {
  my $class = shift;
  my $self = {};
  $self->{_eval} = shift || croak "No eval function found";
  $self->{_replacementRate} = shift || 0.5; #Default to half  replaced
  $self->{_population_size} = shift || 100; #Default
  $self->{_alphabet} = shift || [ 0, 1]; #Default
  bless $self, $class;
  return $self;
}


=head2 set( $ref_to_params_hash, $ref_to_code_hash, $ref_to_operators_hash )

Sets the instance variables. Takes a ref-to-hash as
input. Not intended to be used from outside the class

=cut

sub set {
  my $self = shift;
  my $hashref = shift || croak "No params here";
  my $codehash = shift || croak "No code here";
  my $opshash = shift || croak "No ops here";

  for ( keys %$codehash ) {
	$self->{"_$_"} =  eval "sub { $codehash->{$_} } ";
  }

  $self->{_ops} =();
  for ( keys %$opshash ) {
    push @{$self->{_ops}}, 
      Algorithm::Evolutionary::Op::Base::fromXML( $_, $opshash->{$_}->[1], $opshash->{$_}->[0] ) ;
  }
}

=head2 reset( $population )

Start all over again by resetting the population

=cut

sub reset {
  my $self = shift;
  my $population = shift;
  my $length = $population->[0]->size;
  @$population = ();
  my @alphabet = @{$self->{'_alphabet'}};
  for ( my $p= 0; $p < $self->{'_population_size'}; $p++ ) {
    my $string = '';
    for ( my $i = 0; $i < $length; $i++ ) {
      $string .= $alphabet[rand( @alphabet )];
    }
    my $new_one =  Algorithm::Evolutionary::Individual::String->fromString( $string );
    push @$population, $new_one;
  } 
}

=head2 apply( $population )

Applies the algorithm to the population, which should have
been evaluated first; checks that it receives a
ref-to-array as input, croaks if it does not. Returns a sorted,
culled, evaluated population for next generation.

=cut

sub apply ($) {
    my $self = shift;
    my $pop = shift || croak "No population here";
    croak "Incorrect type ".(ref $pop) if  ref( $pop ) ne $APPLIESTO;

    #Evaluate only the new ones
    my $eval = $self->{_eval};
    for my $p ( @{$pop} ) {
      $p->evaluate( $eval) if !$p->Fitness();
    }
    my @ranked_pop = sort { $b->{_fitness} <=> $a->{_fitness}; } @$pop;

    #Eliminate
    my $pringaos =  @$pop  * $self->{_replacementRate} ;
    splice( @ranked_pop, -$pringaos );

    #Check distribution of remaining pop
    my $how_many = @ranked_pop;
    my @occurrences;
    my $length = $pop->[0]->size;
    for my $p ( @ranked_pop ) {
      for ( my $i = 0; $i < $length; $i++ ) {
	if ( ! defined $occurrences[$i] ) {
	  $occurrences[$i] = {};
	}
	my $this_value = $p->Atom($i);
	$occurrences[$i]->{$this_value}++;
      }
    }
    my @wheel;
    for ( my $i = 0; $i < $length; $i++ ) {
      for my $k (  @{$self->{'_alphabet'}} ) {
	if ( $occurrences[$i]->{$k} ) {
	  $occurrences[$i]->{$k} /= $how_many;
	} else {
	  $occurrences[$i]->{$k} = 0.05; #Minimum to avoid stagnation
	}
      }
      $wheel[$i] = new Algorithm::Evolutionary::Hash_Wheel $occurrences[$i];
    }

    #Generate new population
    for ( my $p= 0; $p < $self->{'_population_size'} - $pringaos; $p++ ) {
      my $string = '';
      for ( my $i = 0; $i < $length; $i++ ) {
	$string .= $wheel[$i]->spin;
      }
      my $new_one =  Algorithm::Evolutionary::Individual::String->fromString( $string );
      push @ranked_pop, $new_one;
    } 
    @$pop = @ranked_pop; # Population is sorted
}

=head1 SEE ALSO

More or less in the same ballpark, alternatives to this one

=over 4

=item * 

L<Algorithm::Evolutionary::Op::GeneralGeneration>

=back

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/09/30 16:01:28 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/EDA_step.pm,v 1.5 2009/09/30 16:01:28 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 1.5 $

=cut

"The truth is out there";
