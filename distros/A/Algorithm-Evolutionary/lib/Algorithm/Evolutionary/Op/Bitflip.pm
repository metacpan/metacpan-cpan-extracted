use strict; #-*-cperl-*-
use warnings;

use lib qw( ../../lib ../../../lib ../../../../lib);

=head1 NAME

Algorithm::Evolutionary::Op::Bitflip - Bit-flip mutation

=head1 SYNOPSIS

  my $xmlStr2=<<EOC; #howMany should be integer
  <op name='Bitflip' type='unary' rate='0.5' >
    <param name='howMany' value='2' /> 
  </op>
  EOC
  my $ref2 = XMLin($xmlStr2);

  my $op2 = Algorithm::Evolutionary::Op::Base->fromXML( $ref2 );
  print $op2->asXML(), "\n*Arity ", $op->arity(), "\n";

  my $op = new Algorithm::Evolutionary::Op::Bitflip 2; #Create from scratch with default rate

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Mutation operator for a GA; changes a single bit in the bitstring; 
does not need a rate

=head1 METHODS 

=cut

package Algorithm::Evolutionary::Op::Bitflip;

our ($VERSION) = ( '$Revision: 3.3 $ ' =~ /(\d+\.\d+)/ );

use Carp;
use Clone qw(clone);

use base 'Algorithm::Evolutionary::Op::Base';

#Class-wide constants
our $ARITY = 1;

=head2 new( [$how_many] [,$priority] )

Creates a new mutation operator with a bitflip application rate, which defaults to 0.5,
and an operator application rate (general for all ops), which defaults to 1.

=cut

sub new {
  my $class = shift;
  my $howMany = shift || 1; 
  my $rate = shift || 1;

  my $hash = { howMany => $howMany || 1};
  my $self = Algorithm::Evolutionary::Op::Base::new( 'Algorithm::Evolutionary::Op::Bitflip', $rate, $hash );
  return $self;
}

=head2 create()

Creates a new mutation operator.

=cut

sub create {
  my $class = shift;
  my $self = {};
  bless $self, $class;
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
#  my $victim = $arg->clone();
  my $victim; 
  if ( (ref $arg ) =~ /BitString/ ) {
    $victim = clone( $arg );
  } else {
    $victim = $arg->clone();
  }
  my $size =  $victim->size();
#  croak "Incorrect type ".(ref $victim) if ! $self->check( $victim );
  croak "Too many changes" if $self->{_howMany} >= $size;
  my @bits = 0..($size-1); # Hash with all bits
  for ( my $i = 0; $i < $self->{_howMany}; $i++ ) {
      my $rnd = int (rand( @bits ));
      my $who = splice(@bits, $rnd, 1 );
      $victim->Atom( $who, $victim->Atom( $who )?0:1 );
  }
  $victim->{'_fitness'} = undef ;
  return $victim;
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2011/02/13 17:45:53 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Bitflip.pm,v 3.3 2011/02/13 17:45:53 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.3 $
  $Name $

=cut

