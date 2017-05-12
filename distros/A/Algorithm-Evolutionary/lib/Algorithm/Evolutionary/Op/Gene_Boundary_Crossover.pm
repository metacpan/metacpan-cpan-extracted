use strict;
use warnings;

=head1 NAME

Algorithm::Evolutionary::Op::Gene_Boundary_Crossover - n-point crossover
    operator that restricts crossing point to gene boundaries
             

=head1 SYNOPSIS

  #Create from XML description using EvoSpec
  my $xmlStr3=<<EOC;
  <op name='Gene_Boundary_Crossover' type='binary' rate='1'>
    <param name='numPoints' value='3' /> #Max is 2, anyways
  </op>
  EOC
  my $op3 = Algorithm::Evolutionary::Op::Base->fromXML( $xmlStr3 );
  print $op3->asXML(), "\n";

  #Apply to 2 Individuals of the String class
  my $indi = new Algorithm::Evolutionary::Individual::BitString 10;
  my $indi2 = $indi->clone();
  my $indi3 = $indi->clone();
  my $offspring = $op3->apply( $indi2, $indi3 ); #$indi2 == $offspring

  #Initialize using OO interface
  my $op4 = new Algorithm::Evolutionary::Op::Gene_Boundary_Crossover 3; #Gene_Boundary_Crossover with 3 crossover points

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

package Algorithm::Evolutionary::Op::Gene_Boundary_Crossover;

use lib qw(../../..);

our $VERSION =   sprintf "%d.%03d", q$Revision: 3.2 $ =~ /(\d+)\.(\d+)/g; # Hack for avoiding version mismatch

use Clone qw(clone);
use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

#Class-wide constants
our $APPLIESTO =  'Algorithm::Evolutionary::Individual::String';
our $ARITY = 2;

=head2 new( [$options_hash] [, $operation_priority] )

Creates a new n-point crossover operator, with 2 as the default number
of points, that is, the default would be
    my $options_hash = { numPoints => 2 };
    my $priority = 1;

=cut

sub new {
  my $class = shift;
  my $num_points = shift || 2;
  my $gene_size = shift || croak "No default gene size";
  my $hash = { numPoints =>  $num_points, gene_size => $gene_size };
  my $rate = shift || 1;
  my $self = Algorithm::Evolutionary::Op::Base::new( __PACKAGE__, $rate, $hash );
  return $self;
}

=head2 create( [$num_points] )

Creates a new 1 or 2 point crossover operator. But this is just to have a non-empty chromosome
Defaults to 2 point

=cut

sub create {
  my $class = shift;
  my $self;
  $self->{_numPoints} = shift || 2;
  $self->{_gene_size} = shift || croak "No default for gene size\n";
  bless $self, $class;
  return $self;
}

=head2 apply( $chromsosome_1, $chromosome_2 )

Applies xover operator to a "Chromosome", a string, really. Can be
applied only to I<victims> with the C<_str> instance variable; but
it checks before application that both operands are of type
L<BitString|Algorithm::Evolutionary::Individual::String>.

=cut

sub  apply ($$$){
  my $self = shift;
  my $arg = shift || croak "No victim here!";
#  my $victim = $arg->clone();
  my $gene_size = $self->{'_gene_size'};
  my $victim = clone( $arg );
  my $victim2 = shift || croak "No victim here!";
#  croak "Incorrect type ".(ref $victim) if !$self->check($victim);
#  croak "Incorrect type ".(ref $victim2) if !$self->check($victim2);
  my $minlen = (  length( $victim->{_str} ) >  length( $victim2->{_str} ) )?
	 length( $victim2->{_str} )/$gene_size: length( $victim->{_str} )/$gene_size;
  croak "Crossover not possible" if ($minlen == 1);
  my ($pt1, $range );
  if ( $minlen == 2 ) {
      $pt1 = $range = 1;
  }  else {
      $pt1 = int( rand( $minlen - 1 ) );
#  print "Puntos: $pt1, $range \n";
      croak "No number of points to cross defined" if !defined $self->{_numPoints};
      if ( $self->{_numPoints} > 1 ) {
	  $range =  int ( 1 + rand( length( $victim->{_str} )/$gene_size - $pt1 - 1) );
      } else {
	  $range = 1 + int( $minlen  - $pt1 );
      }
  }
  
  substr( $victim->{_str}, $pt1*$gene_size, $range*$gene_size ) 
      = substr( $victim2->{_str}, $pt1*$gene_size, $range*$gene_size );
  $victim->{'_fitness'} = undef;
  return $victim; 
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2011/02/14 06:55:36 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Gene_Boundary_Crossover.pm,v 3.2 2011/02/14 06:55:36 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.2 $
  $Name $

=cut
