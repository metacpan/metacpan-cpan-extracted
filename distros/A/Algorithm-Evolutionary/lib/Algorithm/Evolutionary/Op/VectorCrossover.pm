use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::VectorCrossover - Crossover for L<Algorithm::Evolutionary::Individual::Vector>.

=head1 SYNOPSIS

  my $xmlStr5=<<EOC; #Create using XML from base class
  <op name='VectorCrossover' type='binary' rate='1'>
    <param name='numPoints' value='1' />
  </op>
  EOC
  my $ref5 = XMLin($xmlStr5);
  my $op5 = Algorithm::Evolutionary::Op::Base->fromXML( $ref5 );
  print $op5->asXML(), "\n";

  my $indi5 = new Algorithm::Evolutionary::Individual::Vector 10;
  print $indi5->asString(), "\n";
  $op5->apply( $indi4, $indi5 );
  print $indi4->asString(), "\n";

  my $op = new VectorCrossover 1; # Using ctor, with a single crossing point

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Crossover operator for a  individual with vector (array) representation

=cut

package Algorithm::Evolutionary::Op::VectorCrossover;

our ($VERSION) = ( '$Revision: 3.1 $ ' =~ / (\d+\.\d+)/ );

use Carp;
use Clone qw(clone);

use base 'Algorithm::Evolutionary::Op::Base';

#Class-wide constants
our $APPLIESTO =  'Algorithm::Evolutionary::Individual::Vector';
our $ARITY = 2;

=head2 new( [$number_of_crossing_points = 2], [$priority_rate = 1] )

Creates a new 1 or 2 point crossover operator. But this is just to have a non-empty chromosome
Defaults to 2 point crossover

=cut

sub new {
  my $class = shift;
  my $hash = { numPoints => shift || 2 };
  my $rate = shift || 1;
  my $self = Algorithm::Evolutionary::Op::Base::new( 'Algorithm::Evolutionary::Op::VectorCrossover', $rate, $hash );
  return $self;
}

=head2 create( [$number_of_crossing_points = 2] )

Creates a new 1 or 2 point crossover operator. But this is just to have a non-empty chromosome
Defaults to 2 point. 

=cut

sub create {
  my $class = shift;
  my $self;
  $self->{_numPoints} = shift || 2;
  bless $self, $class;
  return $self;
}

=head2 apply( $chromosome_1, $chromosome_2 )

Applies xover operator to a "Chromosome",  a vector of stuff,
really. Can be applied only to I<victims> with the C<_array> instance
variable; but it checks before application that both operands are of
type L<Algorithm::Evolutionary::Individual::Vector|Algorithm::Evolutionary::Individual::Vector>. 

=cut

sub  apply ($$;$){
  my $self = shift;
  my $arg = shift || croak "No victim here!";
  my $victim = clone($arg);
  my $victim2 = shift || croak "No victim here!";
  croak "Incorrect type ".(ref $victim) if !$victim->{'_array'};
  croak "Incorrect type ".(ref $victim2) if !$victim2->{'_array'};
  if ( (scalar @{$victim->{'_array'}} == 2) || (scalar @{$victim2->{'_array'}} == 2 ) ) {
    #Too small, don't pay attention to number of cutting points
    my $i = (rand() > 0.5 )? 0:1;
    $victim->{'_array'}[$i] =  $victim2->{'_array'}[$i];
  } else {
    my $pt1 = int( rand( @{$victim->{'_array'}} - 1 ) ) ; #in int env; contains $# +1
    
    my $possibleRange = @{$victim->{'_array'}} - $pt1 - 1;
    my $range;
    if ( $self->{'_numPoints'} > 1 ) {
      $range = 1+ int ( rand( $possibleRange ) );
    } else {
      $range = $possibleRange + 1;
    }
    #Check length to avoid unwanted lengthening
    return $victim if ( ( $pt1+$range >= @{$victim->{'_array'}} ) || ( $pt1+$range >= @{$victim2->{'_array'}} ));
    
    @{$victim->{'_array'}}[$pt1..($pt1+$range)] =  
      @{$victim2->{'_array'}}[$pt1..($pt1+$range)];
    $victim->Fitness( undef ); #It's been changed, so fitness is invalid
  }
  return $victim;
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2012/12/08 10:06:23 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/VectorCrossover.pm,v 3.1 2012/12/08 10:06:23 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $
  $Name $

=cut

"Sad, but true";
