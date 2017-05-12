use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::ChangeLengthMutation - Increases/decreases by one atom the length of the string

=head1 SYNOPSIS

  my $xmlStr2=<<EOC;
  <op name='ChangeLengthMutation' type='unary' rate='0.5' />
  EOC
  my $ref2 = XMLin($xmlStr2);

  my $op2 = Algorithm::Evolutionary::Op::Base->fromXML( $ref2 );
  print $op2->asXML(), "\n*Arity ", $op->arity(), "\n";

  my $op = new Algorithm::Evolutionary::Op::ChangeLengthMutation 1, 0.5, 0.5; #Create from scratch

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Increases or decreases the length of a string, by adding a random element, or
eliminating it.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::ChangeLengthMutation;

our ($VERSION) = ( '$Revision: 3.1 $ ' =~ /(\d+\.\d+)/ );

use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

#Class-wide constants
our $APPLIESTO =  'Algorithm::Evolutionary::Individual::String';
our $ARITY = 1;

=head2 new( $rate[, $increment_probability] [, $decrement_probability]

Creates a new operator. It is called with 3 arguments: the rate it's
going to be applied, and the probability of adding and substracting an
element from the string each time it's applied.

=cut

sub new {
  my $class = shift;
  my $rate = shift;
  my $probplus = shift || 1;
  my $probminus = shift || 1;
  my $self = { rate => $rate, 
	       _probplus => $probplus,
	       _probminus => $probminus };

  bless $self, $class;
  return $self;
}

=head2 create

Creates a new operator. It is called with 3 arguments: the rate it's
going to be applied, and the probability of adding and substracting an
element from the string each time it's applied. Rates default to one.

=cut

sub create {
  my $class = shift;
  my $rate = shift;
  my $probplus = shift || 1;
  my $probminus = shift || 1;
  my $self = { _rate => $rate, 
	       _probplus => $probplus,
	       _probminus => $probminus };
  bless $self, $class;
  return $self;
}

=head2 apply

This is the function that does the stuff. The probability of adding
and substracting are normalized. Depending on a random draw, a random
char is added to the string (at the end) or eliminated from a random
position within the string..

=cut

sub apply ($$){
  my $self = shift;
  my $arg = shift || croak "No victim here!";
  my $victim = $arg->clone();
  croak "Incorrect type ".(ref $victim) if ! $self->check( $victim );

  #Select increment or decrement
  my $total = $self->{_probplus} + $self->{_probminus};
  my $rnd = rand( $total );
  if ( $rnd < $self->{_probplus} ) { #Incrementar
	my $idx = rand( @{$victim->{_chars}} );
	my $char = $victim->{_chars}[$idx];
	$victim->addAtom( $char );
  } else {
	my $idx = rand( length($victim->{_str}) );
	substr( $victim->{_str}, $idx, 1 ) ='';
  }
  $victim->Fitness(undef);
  return $victim;
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/09/13 12:49:04 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/ChangeLengthMutation.pm,v 3.1 2009/09/13 12:49:04 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $
  $Name $

=cut

