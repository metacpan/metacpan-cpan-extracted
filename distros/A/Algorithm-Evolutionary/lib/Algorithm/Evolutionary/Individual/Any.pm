use strict; #-*-cperl-*-
use warnings;

=head1 NAME

Algorithm::Evolutionary::Individual::Any - Wrapper around any Perl data structure, turns it into a I<Chromosome> 

=head1 SYNOPSIS

    use Algorithm::Evolutionary::Individual::Any;
    use Class::Name; # Your class here; it's required if not included anyways

    my $indi = new Algorithm::Evolutionary::Individual::Any Class::Name $class_args ; 

    $indi->Fitness( $fitness );
    print $indi->Fitness();

=head1 Base Class

L<Algorithm::Evolutionary::Individual::Base>

=head1 DESCRIPTION

Bitstring Individual for a Genetic Algorithm. Used, for instance, in a
canonical GA. That does not mean it can be used for mutation or
crossover; normally you'll have to write your own classes 

=cut

package Algorithm::Evolutionary::Individual::Any;
use Carp;

our ($VERSION) =  ( '$Revision: 3.0 $ ' =~ /(\d+\.\d+)/ );

use base 'Algorithm::Evolutionary::Individual::Base';

=head1 METHODS

=head2 new( $base_class, $base_class_args )

Creates a new individual by instantiating one of the given class with
the arguments also issued here, which are forwarded to the class
constructor.

=cut

sub new {
  my $class = shift; 
  my $base_class = shift || croak "Need a base class";
  my $base_class_args = shift; # Arguments optional
  my $self = 
      Algorithm::Evolutionary::Individual::Base::new( 'Algorithm::Evolutionary::Individual::Any');
  if ( !$INC{"$base_class\.pm"} ) {
    eval "require $base_class" || croak "Can't find $base_class Module";
  }
  
  my $inner_self = $base_class->new( $base_class_args ) || croak "Something is wrong when creating $base_class: $@\n";
  $self->{'_inner'} = $inner_self;
  return $self;
}


=head2 Atom([$index]) 

No matter what kind of underlying structure is there, it will return the wrapped object. You can
subclass and overload, however, but then you earn nothing to use this
class; you're better off creating a new one altogether.

=cut 

sub Atom {
  my $self = shift;
  return $self->{'_inner'};
}


=head2 size()

Returns 1. Here for compatibility

=cut 

sub size {
  1;
}



=head2 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut
