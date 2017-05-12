use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::TreeMutation - GP-like mutation operator for trees

=head1 SYNOPSIS

  my $op = new Algorithm::Evolutionary::Op::TreeMutation (0.5 ); #Create from scratch

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Mutation operator for a genetic programming, mutates tree nodes with
a certain probability

=cut

package Algorithm::Evolutionary::Op::TreeMutation;

our ($VERSION) = ( '$Revision: 3.1 $ ' =~ /(\d+\.\d+)/ );

use Carp;

use Algorithm::Evolutionary::Op::Base;
our @ISA = qw (Algorithm::Evolutionary::Op::Base);

#Class-wide constants
our $APPLIESTO =  'Algorithm::Evolutionary::Individual::Tree';
our $ARITY = 1;

=head1 METHODS

=head2 new

Creates a new mutation operator with an application rate. Rate defaults to 0.1.

=cut

sub new {
  my $class = shift;
  my $mutRate = shift || 0.5; 
  my $rate = shift || 1;

  my $hash = { mutRate => $mutRate };
  my $self = Algorithm::Evolutionary::Op::Base::new( 'Algorithm::Evolutionary::Op::TreeMutation', $rate, $hash );
  return $self;
}


=head2 create

Creates a new mutation operator with an application rate. Rate defaults to 0.5.

Called create to distinguish from the classwide ctor, new. It just
makes simpler to create a Mutation Operator

=cut

sub create {
  my $class = shift;
  my $rate = shift || 0.5; 

  my $self = {_mutRate => $rate };

  bless $self, $class;
  return $self;
}

=head2 apply

Applies mutation operator to a "Chromosome", but
it checks before application that both operands are of type
L<Algorithm::Evolutionary::Individual::Tree|Algorithm::Evolutionary::Individual::Tree>.

=cut

sub apply ($;$) {
  my $self = shift;
  my $arg = shift || croak "No victim here!";
  my $victim = $arg->clone();
  croak "Incorrect type ".(ref $victim) if ! $self->check( $victim );
  my $node = $victim->{_tree};
  #Build the list of primitives
  my %primitives = %{$victim->{_primitives}};
  my @arities;
  for ( keys %primitives ) {
	push @{$arities[ $primitives{$_}[0] ]}, $_;
  }
  $node->walk_down( { callback => \&mutate, 
		      mutrate => $self->{_mutRate},
		      arities => \@arities,
		      primitives => $victim->{_primitives}  });

  return $victim;
}

=head2 mutate 

Callback routine called from apply; decides on mutation application, and
applies it. If appliable, substitutes a node by other with the same arity.
Builds a lists of nodes before, to speed up operation

=cut

sub mutate {
  my $node = shift;
  my $hashref = shift;

  my $mutrate = $hashref->{mutrate};
  my @arities = @{$hashref->{arities}};
  my %primitives = %{$hashref->{primitives}};
  if ( rand > $mutrate ) { #Mutate
    my $primitive = $node->name();
    my $arity = $primitives{$primitive}[0];
    my $newName;
    do { 
      $newName = $arities[$arity][ rand( @{$arities[$arity]} )];
    } until ($newName ne $primitive);
    $node->name( $newName );
  }
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/28 11:30:56 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/TreeMutation.pm,v 3.1 2009/07/28 11:30:56 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $

=cut

