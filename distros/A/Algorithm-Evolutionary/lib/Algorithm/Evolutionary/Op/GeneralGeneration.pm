use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::GeneralGeneration - Customizable single generation for an evolutionary algorithm.
                 
=head1 SYNOPSIS

  #Taken from the t/general.t file, verbatim
  my $m = new Algorithm::Evolutionary::Op::Bitflip; #Changes a single bit
  my $c = new Algorithm::Evolutionary::Op::Crossover; #Classical 2-point crossover
  my $replacementRate = 0.3; #Replacement rate
  use Algorithm::Evolutionary::Op::RouletteWheel;
  my $popSize = 20;
  my $selector = new Algorithm::Evolutionary::Op::RouletteWheel $popSize; #One of the possible selectors
  use Algorithm::Evolutionary::Op::GeneralGeneration;
  my $onemax = sub { 
    my $indi = shift;
    my $total = 0;
    for ( my $i = 0; $i < $indi->length(); $i ++ ) {
      $total += substr( $indi->{_str}, $i, 1 );
    }
    return $total;
  };
  my @pop;
  my $numBits = 10;
  for ( 0..$popSize ) {
    my $indi = new Algorithm::Evolutionary::Individual::BitString $numBits ; #Creates random individual
    my $fitness = $onemax->( $indi );
    $indi->Fitness( $fitness );
    push( @pop, $indi );
  }
  my $generation = 
    new Algorithm::Evolutionary::Op::GeneralGeneration( $onemax, $selector, [$m, $c], $replacementRate );
  my @sortPop = sort { $a->Fitness() <=> $b->Fitness() } @pop;
  my $bestIndi = $sortPop[0];
  $generation->apply( \@sortPop );
 
=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Genetic algorithm that uses the other component. Must take as input the operators thar are going to be
used, along with its priorities

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::GeneralGeneration;

use lib qw(../../..);

our $VERSION = '3.2';

use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

use Algorithm::Evolutionary::Wheel;

# Class-wide constants
our $APPLIESTO =  'ARRAY';
our $ARITY = 1;

=head2 new( $evaluation_function, $selector, $ref_to_operator_array, $replacement_rate )

Creates an algorithm, with the usual operators. Includes a default mutation
and crossover, in case they are not passed as parameters

=cut

sub new {
  my $class = shift;
  my $self = {};
  $self->{'_eval'} = shift || croak "No eval function found";
  $self->{'_selector'} = shift || croak "No selector found";
  $self->{'_ops'} = shift || croak "No operator found";
  $self->{'_replacementRate'} = shift || 1; #Default to all  replaced
  bless $self, $class;
  return $self;
}


=head2 set( $ref_to_params_hash, $ref_to_code_hash, $ref_to_operators_hash )

Sets the instance variables. Takes a ref-to-hash as
input

=cut

sub set {
  my $self = shift;
  my $hashref = shift || croak "No params here";
  my $codehash = shift || croak "No code here";
  my $opshash = shift || croak "No ops here";
  $self->{_selrate} = $hashref->{selrate};

  for ( keys %$codehash ) {
	$self->{"_$_"} =  eval "sub { $codehash->{$_} } ";
  }

  $self->{_ops} =();
  for ( keys %$opshash ) {
	push @{$self->{_ops}}, 
	  Algorithm::Evolutionary::Op::Base::fromXML( $_, $opshash->{$_}->[1], $opshash->{$_}->[0] ) ;
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
  my @ops = @{$self->{_ops}};

  #Breed
  my $selector = $self->{_selector};
  my @genitors = $selector->apply( @$pop );

  #Reproduce
  my $totRate = 0;
  my @rates;
  for ( @ops ) {
	push( @rates, $_->{rate});
  }
  my $opWheel = new Algorithm::Evolutionary::Wheel @rates;

  my @newpop;
  my $pringaos =  @$pop  * $self->{'_replacementRate'} ;
  for ( my $i = 0; $i < $pringaos; $i++ ) {
	  my @offspring;
	  my $selectedOp = $ops[ $opWheel->spin()];
#	  print $selectedOp->asXML;
	  for ( my $j = 0; $j < $selectedOp->arity(); $j ++ ) {
		my $chosen = $genitors[ rand( @genitors )];
#		print "Elegido ", $chosen->asString(), "\n";
		push( @offspring, $chosen->clone() );
	  }
	  my $mutante = $selectedOp->apply( @offspring );
	  push( @newpop, $mutante );
  }
  
  #Eliminate and substitute
  splice( @$pop, -$pringaos );
  for ( @newpop ) {
      $_->evaluate( $eval );
  }
  push @$pop, @newpop;
  my @sortPop = sort { $b->{'_fitness'} <=> $a->{'_fitness'}; } @$pop;
  @$pop = @sortPop;
  
}

=head1 SEE ALSO

=over 4

=item *

A more modern and flexible version: L<Algorithm::Evolutionary::Op::Generation_Skeleton>.

=item * 

L<Algorithm::Evolutionary::Op::CanonicalGA>.

=item * 

L<Algorithm::Evolutionary::Op::FullAlgorithm>.


=back

=head1 Copyright

  
This file is released under the GPL. See the LICENSE file included in this distribution,
or go to http://www.fsf.org/licenses/gpl.txt

=cut

"The truth is out there";
