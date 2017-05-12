use strict;
use warnings;


=head1 NAME

    Algorithm::Evolutionary::Op::DeltaTerm - Termination condition for an algorithm; checks that 
                the difference of the best to a target is less than a delta
                 

=head1 SYNOPSIS

   my $target = 1;
   my $epsilon = 0.01;
   my $dt = new Algorithm::Evolutionary::Op::DeltaTerm $target, $epsilon; 
   #$dt->apply( \@pop ) when the best fitness is 1 plus/minus 0.1

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Termination condition for evolutionary algorithm loops; the C<apply>
method returns false when the first element in the array is as close
to the target as the differente indicated.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::DeltaTerm;
use Carp;

our ($VERSION) = ( '$Revision: 3.0 $ ' =~ / (\d+\.\d+)/ ) ;

use base 'Algorithm::Evolutionary::Op::Base';

=head2 new( $target[, $delta] )

Creates a new terminator. Takes as parameters the target and the
epsilon (or delta, whatever you want to call it): 

  my $target = 1; 
  my $epsilon = 0.01; 
  my $dt = new Algorithm::Evolutionary::Op::DeltaTerm $target, $epsilon; 

Delta can be 0, which means that application of this operator will
return true only when the first element fitness is the same as the
target. Use this judiciously when your fitness is a floating
point number.

=cut

sub new {
  my $class = shift;
  my $target = shift || croak "No target here!";
  my $delta = shift ; #  Could be 0
  my $hash = { target => $target,
	       delta =>  $delta };
  my $self = Algorithm::Evolutionary::Op::Base::new( $class, 1, $hash );
  return $self;
}


=head2 apply( $population )

Will return true while the difference between the fitness of the first element 
in the population and the target is less than C<$delta>, true otherwise

    $dt->apply( \@pop ) == 1 

if the target has not been reached. Population must be sorted before this.

=cut

sub apply ($) {
  my $self = shift;
  my $pop = shift;

  return abs( $pop->[0]->Fitness() -  $self->{_target} ) > $self->{_delta};
  
}
  
=head1 See Also

L<Algorithm::Evolutionary::Op::FullAlgorithm> needs an object of this class to check
for the termination condition. It's normally used alongside "generation-type"
objects such as L<Algorithm::Evolutionary::Op::Easy>.

There are other options for termination conditions: L<Algorithm::Evolutionary::Op::NoChangeTerm|Algorithm::Evolutionary::Op::NoChangeTerm> and  
L<Algorithm::Evolutionary::Op::GenerationalTerm>.


=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/24 08:46:59 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/DeltaTerm.pm,v 3.0 2009/07/24 08:46:59 jmerelo Exp $ 
  $Author: jmerelo $ 

=cut

"The truth is out there";
