use strict;
use warnings;

=encoding utf8

=head1 NAME

Algorithm::Evolutionary::Op::Combined - Combinator of several operators of the same arity, unary or binary

=head1 SYNOPSIS


  #Initialize using OO interface
  my $op = new Algorithm::Evolutionary::Op::Mutation 0.1 3
  my $another_op = new Algorithm::Evolutionary::Op::Permutation 2
  # Single operator with  rate of application = 3
  my $combined_op = new Algorithm::Evolutionary::Op::Combined [ $op, $another_op ], 3; 

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Some algorithms (such as
L<Algorithm::Evolutionary::Op::Canonical_GA_NN>) need a single
"mutation" and a single "crossover" operator. If you want to combine
several (like above, mutation and permutation), each one with its own
rate, you have to give them a façade like this one.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Combined;

use lib qw(../../..);

our $VERSION =   '1.2';

use Algorithm::Evolutionary::Wheel;
use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

#Class-wide constants
our $APPLIESTO =  'Algorithm::Evolutionary::Individual::String';
our $ARITY = 2;
our %parameters = ( numPoints => 2 );

=head2 new( $ref_to_operator_array [, $operation_priority] )

Priority defaults to one, operator array has no defaults.

=cut

sub new {
  my $class = shift;
  croak "Need operator array" if (!@_) ;
  my $hash = { ops => shift };
  my $rate = shift || 1;
  my $self = Algorithm::Evolutionary::Op::Base::new( $class, $rate, $hash );
  return $self;
}

=head2 apply( @operands )

Applies the operator to the set of operands. All are passed, as such,
to  whatever operator is selected

=cut

sub  apply ($$$){
  my $self = shift;
  my @victims = @_; # No need to clone, any operator will also clone.
  my $op_wheel = new Algorithm::Evolutionary::Wheel map( $_->{'rate'}, @{$self->{'_ops'}} );
  my $selected_op = $self->{'_ops'}->[ $op_wheel->spin()];
 
  return $selected_op->apply(@victims); 
}

=head1 SEE ALSO

=over 4

=item L<Algorithm::Evolutionary::Op::Mutation> a mutation operator.

=item L<Algorithm::Evolutionary::Op::Uniform_Crossover> another more mutation-like crossover. These two operators can be combined using this one, for instance.

=back

=head1 Copyright
  
This file is released under the GPL. See the LICENSE file included in this distribution,
or go to http://www.fsf.org/licenses/gpl.txt

=cut
