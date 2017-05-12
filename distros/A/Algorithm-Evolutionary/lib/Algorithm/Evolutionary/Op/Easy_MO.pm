use strict; #-*-cperl-*-
use warnings;

use lib qw( ../../.. );

=head1 NAME

Algorithm::Evolutionary::Op::Easy_MO - Multiobjecttive evolutionary algorithm, single generation, with 
                    variable operators 
                 

=head1 SYNOPSIS

  #Mutation and crossover. Default selection rate is 0.4
  my $algo = new Algorithm::Evolutionary::Op::Easy_MO( $eval ); 

  #Define an easy single-generation algorithm with predefined mutation and crossover
  my $m = new Algorithm::Evolutionary::Op::Bitflip; #Changes a single bit
  my $c = new Algorithm::Evolutionary::Op::Crossover; #Classical 2-point crossover
  my $generation = new Algorithm::Evolutionary::Op::Easy_MO( $rr, 0.2, [$m, $c] );

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base>

=cut

=head1 DESCRIPTION

"Easy" to use, single generation of an evolutionary algorithm. Takes
an arrayref of operators as input, or defines bitflip-mutation and
2-point crossover as default. The C<apply> method applies a single
iteration of the algorithm to the population it takes as input

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Easy_MO;

our ($VERSION) = ( '$Revision: 3.6 $ ' =~ / (\d+\.\d+)/ ) ;

use Carp;

use Algorithm::Evolutionary qw( Wheel Op::Bitflip
				Op::Crossover
				Op::Eval::MO_Rank );

use base 'Algorithm::Evolutionary::Op::Base';

# Class-wide constants
our $APPLIESTO =  'ARRAY';

=head2 new( $eval_func, [$selection_rate,] [$operators_arrayref] )

Creates an algorithm that optimizes the handled fitness function and
reference to an array of operators. If this reference is null, an
array consisting of bitflip mutation and 2 point crossover is
generated. Which, of course, might not what you need in case you don't
have a binary chromosome. Take into account that in this case the
fitness function should return a reference to array. 

=cut

sub new {
  my $class = shift;
  my $self = {};
  $self->{_eval} = shift || croak "No eval function found";
  $self->{_rank} = new Algorithm::Evolutionary::Op::Eval::MO_Rank $self->{'_eval'};
  $self->{_selrate} = shift || 0.4;
  if ( @_ ) {
      $self->{_ops} = shift;
  } else {
      #Create mutation and crossover
      my $mutation = new Algorithm::Evolutionary::Op::Bitflip;
      push( @{$self->{_ops}}, $mutation );
      my $xover = new Algorithm::Evolutionary::Op::Crossover;
      push( @{$self->{_ops}}, $xover );
  }
  bless $self, $class;
  return $self;

}

=head2 set( $hashref, codehash, opshash )

Sets the instance variables. Takes a ref-to-hash (for options), codehash (for fitness) and opshash (for operators)

=cut

sub set {
  my $self = shift;
  my $hashref = shift || croak "No params here";
  my $codehash = shift || croak "No code here";
  my $opshash = shift || croak "No ops here";
  $self->{_selrate} = $hashref->{selrate};

  for ( keys %$codehash ) {
    $self->{"_$_"} =  eval "sub {  $codehash->{$_} } " || carp "Error compiling fitness function: $! => $@";
  }

  $self->{_ops} =();
  for ( keys %$opshash ) {
    #First element of the array contains the content, second the rate.
    push @{$self->{_ops}},  
      Algorithm::Evolutionary::Op::Base::fromXML( $_, $opshash->{$_}->[1], $opshash->{$_}->[0] );
  }

}

=head2 apply( $population )

Applies the algorithm to the population; checks that it receives a
ref-to-array as input, croaks if it does not. Returns a sorted,
culled, evaluated population for next generation.

=cut

sub apply ($) {
  my $self = shift;
  my $pop = shift || croak "No population here";

  #Evaluate
  my $eval = $self->{_eval};
  my @ops = @{$self->{_ops}};
  $self->{'_rank'}->apply( $pop );

  #Sort
  my @popsort = sort { $b->{_fitness} <=> $a->{_fitness}; } @$pop;

  #Cull
  my $pringaos = int(($#popsort+1)*$self->{_selrate}); #+1 gives you size
#  print "Pringaos $pringaos\n";
  splice @popsort, - $pringaos;
#  print "Población ", scalar @popsort, "\n";
 
  #Reproduce
  my @rates = map( $_->{'rate'}, @ops );
  my $opWheel = new Algorithm::Evolutionary::Wheel @rates;

  #Generate offpring;
  my $originalSize = $#popsort; # Just for random choice
  for ( my $i = 0; $i < $pringaos; $i ++ ) {
      my @offspring;
      my $selectedOp = $ops[ $opWheel->spin()];
      for ( my $j = 0; $j < $selectedOp->arity(); $j ++ ) {
	  my $chosen = $popsort[ int ( rand( $originalSize ) )];
	  push( @offspring, $chosen ); #No need to clone, it's not changed in ops
      }
      my $mutante = $selectedOp->apply( @offspring );
      push( @popsort, $mutante );
  }

  #Return
  for ( my $i = 0; $i <= $#popsort; $i++ ) {
#	print $i, "->", $popsort[$i]->asString, "\n";
      $pop->[$i] = $popsort[$i];
  }

  
}

=head1 SEE ALSO

L<Algorithm::Evolutionary::Op::CanonicalGA>.
L<Algorithm::Evolutionary::Op::FullAlgorithm>.
L<Algorithm::Evolutionary::Op::Easy> for the scalar version of this code.

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2011/02/14 06:55:36 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Easy_MO.pm,v 3.6 2011/02/14 06:55:36 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.6 $
  $Name $

=cut

"The truth is out there";
