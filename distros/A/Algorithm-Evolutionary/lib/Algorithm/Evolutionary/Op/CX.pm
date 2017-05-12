use strict;
use warnings;

use lib qw( ../../../../lib ); # mainly to avoid syntax errors when saving

=head1 NAME

Algorithm::Evolutionary::Op::CX (Cycle crossover) - 2-point crossover operator; Builds offspring in such a way
    that each gene comes from one of the parents. Preserves the absolute position of the elements 
    in the parent sequence

=head1 SYNOPSIS

  my $op4 = new Algorithm::Evolutionary::Op::CX 3;

  my $indi = new Algorithm::Evolutionary::Individual::Vector 10;
  my $indi2 = $indi->clone();
  my $indi3 = $indi->clone();
  $op3->apply( $indi2, $indi3 );

=head1 Base Class

L<Algorithm::Evolutionary::Op::Base|Algorithm::Evolutionary::Op::Base>

=head1 DESCRIPTION

Cycle Crossover operator for a GA. It is applied to chromosomes that are
a permutation of each other; even as the class it applies to is
L<Algorithm::Evolutionary::Individual::Vector>, it will issue lots of
"La jodimos!" messages if the parents do not fulfill this condition. 

Some information on this operator can be obtained from
L<this
evolutionary computation tutorial|http://www.cs.bham.ac.uk/~rmp/slide_book/node4.html#SECTION00444300000000000000>

=head1 METHODS

=cut

package Algorithm::Evolutionary::Op::CX;

our $VERSION = '3.2';

use Carp;

use base 'Algorithm::Evolutionary::Op::Base';

#Class-wide constants
our $APPLIESTO =  'Algorithm::Evolutionary::Individual::Vector';
our $ARITY = 2;

=head2 new

Creates a new Algorithm::Evolutionary::Op::CX operator.

=cut

sub new {
  my $class = shift;
  my $hash = { numPoints => shift || 2 };
  my $rate = shift || 1;
  my $self = Algorithm::Evolutionary::Op::Base::new( __PACKAGE__, $rate, $hash );
  return $self;
}

=head2 create

Creates a new Algorithm::Evolutionary::Op::CX operator. But this is just to have a non-empty chromosome

=cut

sub create {
  my $class = shift;
  my $self;
  $self->{_numPoints} = shift || 2;
  bless $self, $class;
  return $self;
}

=head2 apply

Applies Algorithm::Evolutionary::Op::CX operator to a "Chromosome", a bitstring, really. Can be
applied only to I<victims> with the C<_bitstring> instance variable; but
it checks before application that both operands are of type
L<Individual::Vector|Algorithm::Evolutionary::Individual::Vector>.

=cut

sub  apply ($$;$){
  my $self = shift;
  my $p1 = shift || croak "No victim here!"; #first parent
  my $p2 = shift || croak "No victim here!"; #second parent
  my $child=$p1->clone(); #Child
  my $i; #Iterator
  my $j; #Iterator
  my $changed; 

  #Check parents type and size
  croak "Incorrect type ".(ref $p1) if !$self->check($p1);
  croak "Incorrect type ".(ref $p2) if !$self->check($p2);
  croak "Algorithm::Evolutionary::Op::CX Error: Parents don't have the same size " if ($p1->length() != $p2->length() );

  my $leng=$p1->length(); #Chrom length
  my $no='x';#-( $leng );#Uninitialized gene mark
 
  #Init child
  for ($i=0;$i < $leng; $i++)
  { $child->Atom($i, $no);}
  my %visto;
  map( $visto{$_}++,@{$p1->{_array}} ); 
  #Build child
#  print "CX \$leng = $leng\n";
  $changed=$i=0;
  while ($changed <  $leng ) {   
    my $found=0;
    #Looking for the next element in cycle
    for ($j=0; $j < $leng ; $j++) { 
      if ( $p1->Atom($j) == $p2->Atom($i)) {  
	$found=$j;
	last;
      }
    }
    #Look if the next element in cycle  was found
    if ($found) { 
      $child->Atom($found, $p1->Atom($found));
      #	  print "Found $found valor ", $child->Atom($found),  "\n";
      $i=$found;
      $changed++;
    }
    else { #End of the cycle, get the genes from the second parent
      $child->Atom(0, $p1->Atom(0) ); $changed++;
      for ($i=1;( $i < $leng ) && ( $changed < $leng )  ; $i++) { 
	if ($child->Atom($i) eq $no ) { 
	  #		  print "Cambiando $i valor ", $p2->Atom($i),  "\n";
	  $child->Atom($i,$p2->Atom($i));
	  $changed++;
	}
      }
    }
  }#End-while
  map( $visto{$_}++,@{$child->{_array}} ); 
  for (keys %visto) { 
	if ($visto{$_} ne 2 ) {
	  print "La jodimos!\n";
	}
	#print "$_ visto $visto{$_}\n";
  };
  for ( $i = 0; $i < $leng; $i ++ ) {
	if ($child->Atom($i) eq $no ){
	  print "Messed up!\n";
	}
  }
  return $child; #return Child, explicative comment if I've ever seen one
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut
