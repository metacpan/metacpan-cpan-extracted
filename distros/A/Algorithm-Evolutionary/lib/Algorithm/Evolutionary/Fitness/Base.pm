use strict; #-*-cperl-*-
use warnings;

use lib qw( ../../../../lib );

=head1 NAME

Algorithm::Evolutionary::Fitness::Base - Base class for fitness functions

=head1 SYNOPSIS

Shouldn't be used directly, it's an abstract class whose siblings are
used to implement fitness functions.

=head1 DESCRIPTION

This module includes functionality that should be common to all fitness. Or at least it
would be nice to have it in common. It counts the number of evaluations and includes a common API for caching evaluations.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Fitness::Base;

use Carp;

our $VERSION = '3.1';


=head2 new()

Initializes common variables, like the number of evaluations. Cache is not initialized.

=cut 

sub new {
  my $class = shift;
  my $self = {};
  bless $self, $class;
  $self->initialize();
  return $self;
}

=head2 initialize()

Called from new, initializes the evaluations counter. 

=cut 

sub initialize {
  my $self = shift;
  $self->{'_counter'} = 0; 
  $self->{'_cache'} = {}; # This is optional; should be used from derived classes
}


=head2 apply( $individual )

Applies the instantiated problem to a chromosome. Actually it is a
wrapper around C<_apply>

=cut

sub apply {
    my $self = shift;
    my $individual = shift;
    $self->{'_counter'}++;
    return $self->_apply( $individual );
}

=head2 _apply( $individual )

This is the one that really does the stuff. Should be overloaded by
derived clases

=cut

sub _apply {
  croak "You should have overloaded this\n";
}


=head2 evaluations() 

Returns the number of evaluations made with this object. Useful for
collecting stats

=cut

sub evaluations {
  my $self = shift;
  return $self->{'_counter'};
}

=head2 reset_evaluations() 

Sets to 0 the number of evaluations; useful for repeated use of the fitness object

=cut

sub reset_evaluations {
  my $self = shift;
  $self->{'_counter'} = 0;
}

=head2 cache() 

Returns a reference to the internal evaluations cache. Not very encapsulated, but...

=cut

sub cache {
    my $self = shift;
    return $self->{'cache'};
}

=head1 Known subclasses

=over 4

=item * 

L<Algorithm::Evolutionary::Fitness::MMDP>

=item * 

L<Algorithm::Evolutionary::Fitness::P_Peaks>

=item * 

L<Algorithm::Evolutionary::Fitness::wP_Peaks>

=item * 

L<Algorithm::Evolutionary::Fitness::Knapsack>

=item * 

L<Algorithm::Evolutionary::Fitness::ECC>

=item * 

L<Algorithm::Evolutionary::Fitness::Royal_Road>

=item * 

L<Algorithm::Evolutionary::Fitness::String>

=item * 

L<Algorithm::Evolutionary::Fitness::Trap>

=item * 

L<Algorithm::Evolutionary::Fitness::Noisy>

=back

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut

"What???";
