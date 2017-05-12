use strict; #-*-cperl-*-
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Convergence_Terminator  - Checks for termination of an algorithm, returns true if a certain percentage of the population is the same
                 
=head1 SYNOPSIS

  my $ct = new Algorithm::Evolutionary::Op::Convergence_Terminator 0.5; 
  do {
    $generation->apply($pop_hashref );
  } until ($ct->apply( $pop_hashref );

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Checks for termination after if population has converged

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Convergence_Terminator;

our ($VERSION) = ( '$Revision: 3.1 $ ' =~ / (\d+\.\d+)/ ) ;

use base 'Algorithm::Evolutionary::Op::Base';

=head2 new( [$population_proportion = 0.5] )

Creates a new generational terminator:

  my $ct = new Algorithm::Evolutionary::Op::Convergence_Terminator 0.5; 

will make the C<apply> method return false after if 50% of the
population are the same, that is, its "genetic" representation is equal.

=cut

sub new {
  my $class = shift;
  my $hash = { proportion => shift || 0.5 };
  my $self = Algorithm::Evolutionary::Op::Base::new( __PACKAGE__, 1, $hash );
  return $self;
}

=head2 apply()

Checks for population convergence

=cut

sub apply ($) {
  my $self = shift;
  my $population = shift;
  my %population_hash;
  for my $p (@$population ) {
    $population_hash{$p->as_string()}++;
  }
  my $convergence =0;
  for my $k ( keys %population_hash ) {
    if ( $population_hash{$k}/@$population >= $self->{'_proportion'} ) {
      $convergence =1;
      last;
    }
  }
  return $convergence;
  
}
  
=head1 See Also

L<Algorithm::Evolutionary::Op::FullAlgorithm> needs an object of this class to check
for the termination condition. It's normally used alongside "generation-type"
objects such as L<Algorithm::Evolutionary::Op::Easy>

There are other options for termination conditions: L<Algorithm::Evolutionary::Op::NoChangeTerm|Algorithm::Evolutionary::Op::NoChangeTerm> and  
L<Algorithm::Evolutionary::Op::DeltaTerm>.


=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/28 11:30:56 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Convergence_Terminator.pm,v 3.1 2009/07/28 11:30:56 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $
  $Name $

=cut

"The truth is out there";
