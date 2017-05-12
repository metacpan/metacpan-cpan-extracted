use strict;
use warnings;

use lib qw(../../..);

=head1 NAME

Algorithm::Evolutionary::Op::Inverover  - Michalewicz's inver-over Operator. 

=head1 SYNOPSIS

  my $xmlStr3=<<EOC;
  <op name='Inverover' type='binary' rate='1' />
  EOC
  my $ref3 = XMLin($xmlStr3);

  my $op3 = Algorithm::Evolutionary::Op::Base->fromXML( $ref3 );
  print $op3->asXML(), "\n";

  my $indi = new Algorithm::Evolutionary::Individual::BitString 10;
  my $indi2 = $indi->clone();
  my $indi3 = $indi->clone();
  $op3->apply( $indi2, $indi3 );

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Inver-over operator for a GA. Created by Michalewicz et al., mainly
for the travelling salesman problem. Takes two chromosomes, which are
permutations of each other.

There is some information on this operator in this interview
with Michalewicz: L<http://www.dcs.napier.ac.uk/coil/news/feature48.html>. You can also download papers from his home page: L<http://www.cs.adelaide.edu.au/~zbyszek/Papers/>.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::Inverover;

our ($VERSION) = ( '$Revision: 3.0 $ ' =~ /(\d+\.\d+)/ );

use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

#Class-wide constants
our $APPLIESTO =  'Algorithm::Evolutionary::Individual::Vector';
our $ARITY = 2;

=head2 new( $rate )

Creates a new Algorithm::Evolutionary::Op::Inverover operator.

=cut

sub new {
  my $class = shift;
  my $rate = shift || 0.5;
  my $hash;

  my $self = Algorithm::Evolutionary::Op::Base::new( 'Algorithm::Evolutionary::Op::Inverover', $rate, $hash );
  return $self;
}

=head2 create

Creates a new Algorithm::Evolutionary::Op::Inverover operator. 

=cut

sub create {
  my $class = shift;
  my $self;
  bless $self, $class;
  return $self;
}

=head2 apply( $first, $second )

Applies Algorithm::Evolutionary::Op::Inverover operator to a
    "Chromosome". Can be applied to anything with the Atom method. 

=cut

sub  apply ($$$){
  my $self = shift;
  my $p1 = shift || croak "No victim here!"; #first parent
  my $p2 = shift || croak "No victim here!"; #second parent
  my $child=$p1->clone(); #Clone S' (child) from First parent
  my $i; #Iterator


  #Check parents type and size
  croak "Incorrect type ".(ref $p1) if !$self->check($p1);
  croak "Incorrect type ".(ref $p2) if !$self->check($p2);
  croak "Inver-over Error: Parents haven't sime size " if ($p1->length() != $p2->length() );
  my $leng=$p1->length(); #Chrom length

  #Select randomly a atom c from S' (child)
  my $c=int( rand( $leng/2 ) );
  my $c2; #The another atom c' (called c2)

  #Build Algorithm::Evolutionary::Op::Inverover child
  while ( 1 )
  {
    if (rand() <= $self->rate)
    { #Select c' (c2) from the remaining cities of S'(child)
      $c2=int( rand( $leng - $c ) + $c);
      $c2+=2 if (($c2 == $c+1) && ($c2 < $leng -2) );

    }
    else
    { #Assign to c' (c2) the 'next' atom to the atom c in the second parent
      for ($c2=0;$c2 < $leng; $c2++)
      { last if ( $child->Atom($c) == $p2->Atom($c2) );}
      $c2= ($c2+1) % $leng;
    }

#   print "\nc= $c c2= $c2 lneg= $leng   atom(c2)=".$child->Atom($c2)." atom(c+1)=".$child->Atom(($c+1) % $leng)."\n";
   #Check if finish
   last if ( ($child->Atom($c2) == $child->Atom( ($c+1)% $leng) ) || ($c+1==$leng) );

   # Inverse the section from the next atom of atom c to the atom c' (c2) in S' (child)
   for ($i=0;$i+$c <= ($c2/2) ; $i++)
   {
#     print "\n\tCambio de Atom(".($i+$c+1).")=".$child->Atom($i+$c+1)." por Atom(".($c2-$i).")=".$child->Atom($c2-$i);
     my $aux=$child->Atom($i+$c+1);
     $child->Atom($i+$c+1,$child->Atom($c2-$i) );
     $child->Atom(($c2-$i),$aux);
   }

  $c=$c2;
  }#End-while

  return $child; #return Child
}


=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2009/07/24 08:46:59 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Op/Inverover.pm,v 3.0 2009/07/24 08:46:59 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.0 $
  $Name $  

=cut
