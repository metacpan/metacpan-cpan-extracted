use strict; #-*-cperl-*-
use warnings;

use lib qw(../../..);

=head1 NAME

Algorithm::Evolutionary::Op::Novelty_Mutation - Mutation guaranteeing new individual is not in the population

=head1 SYNOPSIS

  my $mmdp = new  Algorithm::Evolutionary::Fitness::MMDP;
  my $bits = 36;
  my @population;
  for ( 1..100 ) { #Create and evaluate a population
    my $indi = new Algorithm::Evolutionary::Individual::BitString $bits;
    $indi->evaluate( $mmdp );
    push @population, $indi;
  }
  my $nm = new Algorithm::Evolutionary::Op::Novelty_Mutation $mmdp->{'_cache'}; #Initialize using cache
  $nm->apply($population[$i]);
 
=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Attempts all possible mutations in order, until a "novelty" individual
is found. Generated individuals are checked against the population
hash, and discarded if they are already in the population.

=head1 METHODS 

=cut

package Algorithm::Evolutionary::Op::Novelty_Mutation;

our $VERSION =   sprintf "%d.%03d", q$Revision: 3.1 $ =~ /(\d+)\.(\d+)/g; # Hack for avoiding version mismatch

use Carp;
use Clone qw(clone);

use base 'Algorithm::Evolutionary::Op::Base';

#Class-wide constants
our $ARITY = 1;

=head2 new( $ref_to_population_hash [,$priority] )

Creates a new mutation operator with an operator application rate
(general for all ops), which defaults to 1, and stores the reference
to population hash.

=cut

sub new {
  my $class = shift;
  my $ref_to_population_hash = shift || croak "No pop hash here, fella!"; 
  my $rate = shift || 1;

  my $hash = { population_hashref => $ref_to_population_hash };
  my $self = Algorithm::Evolutionary::Op::Base::new( 'Algorithm::Evolutionary::Op::Novelty_Mutation', $rate, $hash );
  return $self;
}

=head2 apply( $chromosome )

Applies mutation operator to a "Chromosome", a bitstring, really. Can be
applied only to I<victims> composed of [0,1] atoms, independently of representation; but 
it checks before application that the operand is of type
L<BitString|Algorithm::Evolutionary::Individual::BitString>.

=cut

sub apply ($;$){
  my $self = shift;
  my $arg = shift || croak "No victim here!";
  my $test_clone; 
  my $size =  $arg->size();
  for ( my $i = 0; $i < $size; $i++ ) {
    if ( (ref $arg ) =~ /BitString/ ) {
      $test_clone = clone( $arg );
    } else {
      $test_clone = $arg->clone();
    }
    $test_clone->Atom( $i, $test_clone->Atom( $i )?0:1 );
    last if !$self->{'_population_hashref'}->{$test_clone->Chrom()}; #Exit if not found in the population
  }
  if ( $test_clone->Chrom() eq $arg->Chrom() ) { # Nothing done, zap
    for ( my $i = 0; $i < $size; $i++ ) {
      $test_clone->Atom( $i, (rand(100)>50)?0:1 );
    }
  }
  $test_clone->{'_fitness'} = undef ;
  return $test_clone;
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2011/02/14 06:55:36 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Novelty_Mutation.pm,v 3.1 2011/02/14 06:55:36 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $
  $Name $

=cut

