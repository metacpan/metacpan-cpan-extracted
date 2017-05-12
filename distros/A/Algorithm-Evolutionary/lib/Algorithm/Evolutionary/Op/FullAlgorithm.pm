use strict; #-*-cperl-*-
use warnings;

use lib qw ( ../../../../lib);

=head1 NAME

Algorithm::Evolutionary::Op::FullAlgorithm - Skeleton class for a fully-featured evolutionary algorithm
                 

=head1 SYNOPSIS

  use Algorithm::Evolutionary qw( Op::Base Op::Bitflip Op::Crossover
                                  Op::RouletteWheel Op::GeneralGeneration
                                  Op::GenerationalTerm Op::FullAlgorithm );

  # Using the base class as factory
  my $easyEA = Algorithm::Evolutionary::Op::Base->fromXML( $ref->{$xml} );
  $easyEA->apply(\@pop ); 

  #Or using the constructor
  my $m = new Algorithm::Evolutionary::Op::Bitflip; #Changes a single bit
  my $c = new Algorithm::Evolutionary::Op::Crossover; #Classical 2-point crossover
  my $replacementRate = 0.3; #Replacement rate
  my $popSize = 20;
  my $selector = new Algorithm::Evolutionary::Op::RouletteWheel $popSize; #One of the possible selectors
  my $onemax = sub { 
    my $indi = shift;
    my $total = 0;
    my $len = $indi->length();
    my $i = 0;
    while ($i < $len ) {
      $total += substr($indi->{'_str'}, $i, 1);
      $i++;
    }
    return $total;
  };
  my $generation = 
    new Algorithm::Evolutionary::Op::GeneralGeneration( $onemax, $selector, [$m, $c], $replacementRate );
  my $g100 = new Algorithm::Evolutionary::Op::GenerationalTerm 10;
  my $f = new Algorithm::Evolutionary::Op::FullAlgorithm $generation, $g100;
  print $f->asXML();

  $f->apply( $pop ); # Pop should be defined else where

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Class for a configurable evolutionary algoritm. It takes a
single-generarion object, and mixes it with a termination condition
to create a full algorithm. Includes a sensible default
(100-generation generational algorithm) if it is issued only an object
of class L<Algorithm::Evolutionary::Op::GeneralGeneration>.

=cut

package Algorithm::Evolutionary::Op::FullAlgorithm;

our ($VERSION) = ( '$Revision: 3.0 $ ' =~ / (\d+\.\d+)/ ) ;

use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

#  Class-wide constants
our $APPLIESTO =  'ARRAY';
our $ARITY = 1;

=head2 new( $single_generation[, $termination_test] [, $verboseness] )

Takes an already created algorithm and a terminator, and creates an object

=cut

sub new {
  my $class = shift;
  my $algo = shift|| croak "No single generation algorithm found";
  my $term = shift ||  new  Algorithm::Evolutionary::Op::GenerationalTerm 100;
  my $verbose = shift || 0;
  my $hash = { algo => $algo,
	       terminator => $term,
	       verbose => $verbose };
  my $self = Algorithm::Evolutionary::Op::Base::new( __PACKAGE__, 1, $hash );
  return $self;
}

=head2 set( $hashref, $codehash, $opshash )

Sets the instance variables. Takes hashes to the different options of
    the algorithm: parameters, fitness functions and operators

=cut

sub set {
  my $self = shift;
  my $hashref = shift || croak "No params here";
  my $codehash = shift;
  my $opshash = shift;

  $self->SUPER::set( $hashref ); # Base class only aware of options
  #Now reconstruct operators
  for my $o ( keys %$opshash ) { #ops are keyed by type
	$self->{$opshash->{$o}->[1]->{'-id'}} = 
	  Algorithm::Evolutionary::Op::Base::fromXML( $o, $opshash->{$o}->[1], $opshash->{$o}->[0] ); 
  }

}

=head2 apply( $reference_to_population_array )

Applies the algorithm to the population; checks that it receives a
ref-to-array as input, croaks if it does not. Returns a sorted,
culled, evaluated population for next generation.

=cut

sub apply ($) {
  my $self = shift;
  my $pop = shift || croak "No population here";
  croak "Incorrect type ".(ref $pop) if  ref( $pop ) ne $APPLIESTO;

  my $term = $self->{_terminator};
  my $algo = $self->{_algo};
  #Evaluate population, just in case
  my $eval = $algo->{_eval};
  for ( @$pop ) {
    if ( !defined $_->Fitness() ) {
      $_->evaluate( $eval );
    }
  }
  #Run the algorithm
  do {
    $algo->apply( $pop );
    if  ($self->{_verbose}) {
      print "Best ", $pop->[0]->asString(), "\n" ;
      print "Median ", $pop->[@$pop/2]->asString(), "\n";
      print "Worst ", $pop->[@$pop-1]->asString(), "\n\n";
    }
  } while( $term->apply( $pop ) );
  
}

=head1 SEE ALSO

More or less in the same ballpark, alternatives to this one

=over 4

=item * 

L<Algorithm::Evolutionary::Op::CanonicalGA>.

=item *

L<Algorithm::Evolutionary::Op::Easy>.

=back 

Classes you can use within FullAlgorithm:

=over 4

=item * 

L<Algorithm::Evolutionary::Op::Convergence_Terminator>

=item * 

L<Algorithm::Evolutionary::Op::GenerationalTerm>

=item *

L<Algorithm::Evolutionary::Op::Generation_Skeleton>

=back

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/24 08:46:59 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/FullAlgorithm.pm,v 3.0 2009/07/24 08:46:59 jmerelo Exp $ 
  $Author: jmerelo $ 

=cut

"Who wants to rock the party";
