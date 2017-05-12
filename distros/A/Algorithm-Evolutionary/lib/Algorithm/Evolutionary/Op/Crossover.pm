use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Crossover - n-point crossover
    operator; puts fragments of the second operand into the first operand
             

=head1 SYNOPSIS

  #Create from XML description using EvoSpec
  my $xmlStr3=<<EOC;
  <op name='Crossover' type='binary' rate='1'>
    <param name='numPoints' value='3' /> #Max is 2, anyways
  </op>
  EOC
  my $op3 = Algorithm::Evolutionary::Op::Base->fromXML( $xmlStr3 );
  print $op3->asXML(), "\n";

  #Apply to 2 Individuals of the String class
  my $indi = new Algorithm::Evolutionary::Individual::BitString 10;
  my $offspring = $op3->apply( $indi2, $indi3 ); #$indi2 == $offspring

  #Initialize using OO interface
  my $op4 = new Algorithm::Evolutionary::Op::Crossover 2; #Crossover with 2 crossover points

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Crossover operator for a Individuals of type
L<Algorithm::Evolutionary::Individual::String|Individual::String> and
their descendants
(L<Algorithm::Evolutionary::Individual::BitString|Individual::BitString>). Crossover
for L<Algorithm::Evolutionary::Individual::Vector|Individual::Vector>
would be  L<Algorithm::Evolutionary::Op::VectorCrossover|Op::VectorCrossover>

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Crossover;

use lib qw(../../..);

our $VERSION =   sprintf "%d.%03d", q$Revision: 3.2 $ =~ /(\d+)\.(\d+)/g; # Hack for avoiding version mismatch

use Clone qw(clone);
use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

#Class-wide constants
our $APPLIESTO =  'Algorithm::Evolutionary::Individual::String';
our $ARITY = 2;
our %parameters = ( numPoints => 2 );

=head2 new( [$options_hash] [, $operation_priority] )

Creates a new n-point crossover operator, with 2 as the default number
of points, that is, the default would be
    my $options_hash = { numPoints => 2 };
    my $priority = 1;

=cut

sub new {
  my $class = shift;
  my $hash = { numPoints => shift || 2 };
  my $rate = shift || 1;
  my $self = Algorithm::Evolutionary::Op::Base::new( $class, $rate, $hash );
  return $self;
}

=head2 apply( $chromsosome_1, $chromosome_2 )

Applies xover operator to a "Chromosome", a string, really. Can be
applied only to I<victims> with the C<_str> instance variable; but
it checks before application that both operands are of type
L<BitString|Algorithm::Evolutionary::Individual::String>.

Changes the first parent, and returns it. If you want to change both
parents at the same time, check L<QuadXOver|Algorithm::Evolutionary::Op::QuadXOver>

=cut

sub  apply ($$$){
  my $self = shift;
  my $arg = shift || croak "No victim here!";
  my $victim = clone( $arg );
  my $victim2 = shift || croak "No victim here!";
  my $minlen = (  length( $victim->{_str} ) >  length( $victim2->{_str} ) )?
	 length( $victim2->{_str} ): length( $victim->{_str} );
  my $pt1 = int( rand( $minlen ) );
  my $range = 1 + int( rand( $minlen  - $pt1 ) );
#  print "Puntos: $pt1, $range \n";
  croak "No number of points to cross defined" if !defined $self->{_numPoints};
  if ( $self->{_numPoints} > 1 ) {
	$range =  int ( rand( length( $victim->{_str} ) - $pt1 ) );
  }
  
  substr( $victim->{_str}, $pt1, $range ) = substr( $victim2->{_str}, $pt1, $range );
  $victim->{'_fitness'} = undef;
  return $victim; 
}

=head1 SEE ALSO

=over 4

=item L<Algorithm::Evolutionary::Op::QuadXOver> for pass-by-reference xover

=item L<Algorithm::Evolutionary::Op::Uniform_Crossover> another more mutation-like xover

=item L<Algorithm::Evolutionary::Op::Gene_Boundary_Crossover> don't disturb the building blocks!

=item L<Algorithm::Evolutionary::Op::Uniform_Crossover_Diff> vive la difference!

=back

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2011/02/14 06:55:36 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Crossover.pm,v 3.2 2011/02/14 06:55:36 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.2 $
  $Name $

=cut
