use strict;
use warnings;

use lib qw(../../..);

=head1 NAME

Algorithm::Evolutionary::Op::ArithCrossover - Arithmetic crossover operator; performs the average of the n parents crossed
                 

=head1 SYNOPSIS

  my $xmlStr6=<<EOC; #Create it from XML
  <op name='ArithCrossover' type='binary' rate='1' />
  EOC
  my $ref6 = XMLin($xmlStr6);
  my $op6 = Algorithm::Evolutionary::Op::Base->fromXML( $ref6 );
  print $op6->asXML(), "\n";
  $op6->apply( $indi4, $indi5 );
  print $indi4->asString(), "\n"

  my $op = new Algorithm::Evolutionary::Op::ArithCrossover; #Create from scratch

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Crossover operator for a vector-rep individual

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::ArithCrossover;

our $VERSION =   sprintf "%d.%03d", q$Revision: 3.1 $ =~ /(\d+)\.(\d+)/g; # Hack for avoiding version mismatch

use Carp;
use Clone qw(clone);

use base 'Algorithm::Evolutionary::Op::Base';

#Class-wide constants
our $APPLIESTO =  'Algorithm::Evolutionary::Individual::Vector';
our $ARITY = 2;

=head2 create()

Creates the operator, but is more or less empty. Does not have instance variables

=cut

sub create {
  my $class = shift;
  my $self;
  bless $self, $class;
  return $self;
}

=head2 apply( $chromosome_1, $chromosome_2 )

Applies xover operator to a "Chromosome", a vector of stuff,
really. Can be applied only to I<victims> with the C<_array> instance
variable; but it checks before application that both operands are of
type L<Algorithm::Evolutionary::Individual::Vector|Algorithm::Evolutionary::Individual::Vector>. 
Returns the resulting chromosome

=cut

sub  apply ($$;$){
  my $self = shift;
  my $arg = shift || croak "No victim here!";
  my $victim = clone($arg);
  my $victim2 = shift || croak "No victim here!";
  croak "Incorrect type ".(ref $victim) if !$self->check($victim);
  croak "Incorrect type ".(ref $victim2) if !$self->check($victim2);
  for ( my $i = 0; $i < scalar @{$victim->{_array}}; $i++ ) {
	 $victim->{_array}[$i] = 
	   ( $victim2->{_array}[$i] + $victim->{_array}[$i] )/2;
  }
  $victim->Fitness( undef ); #It's been changed, so fitness is invalid
  return $victim;
}


=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2011/02/14 06:55:36 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/ArithCrossover.pm,v 3.1 2011/02/14 06:55:36 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $
  $Name $

=cut
