use strict;  #-*-cperl-*-
use warnings;

=head1 NAME

Algorithm::Evolutionary::Individual::Vector - Array as an individual for evolutionary computation

=head1 SYNOPSIS

    use Algorithm::Evolutionary::Individual::Vector;
    my $indi = new Algorithm::Evolutionary::Individual::Vector 10 ; # Build random vector individual with length 10
                                   # Each element in the range 0 .. 1
    my $indi2 = new Algorithm::Evolutionary::Individual::Vector 20, -5, 5; #Same, with range between -5 and 5

    #Creating a vector step by step. In Perl, there's always more than one way of doing it
    my $indi3 = new Algorithm::Evolutionary::Individual::Vector;
    $indi3->set( {length => 20,
		  rangestart => -5,
		  rangeend => 5 } );   #Sets values, but does not build the array
    
    $indi3->randomize(); #Creates an array using above parameters

    print $indi3->Atom( 7 );       #Returns the value of the 7th character
    $indi3->Atom( 3 ) = '2.35';       #Sets the value

    $indi3->addAtom( 7.5 ); #Adds a new component to the array at the end

    my $indi4 = Algorithm::Evolutionary::Individual::Vector->fromString( '3.5,4.5, 0.1, 3.2');
       #Parses the comma-separated elements of the string and creates a Algorithm::Evolutionary::Individual::Vector from them

    my $indi5 = $indi4->clone(); #Creates a copy of the individual

    my @array = qw( 3.5 4.8 3.3 4.2 0.23); #Tie a vector individual
    tie my @vector, 'Algorithm::Evolutionary::Individual::Vector', @array;
    print tied( @vector )->asXML();

    print $indi3->as_string(); #Prints the individual
    print $indi3->asXML() #Prints it as XML. See L<XML> for more info on this

=head1 Base Class

L<Algorithm::Evolutionary::Individual::Base|Algorithm::Evolutionary::Individual::Base>

=head1 DESCRIPTION

Array individual for a EA. Generally used for floating-point
arrays. It can be also TIEd so that it can be handled as a normal
array. 

=cut

package Algorithm::Evolutionary::Individual::Vector;

use Carp;
use Exporter;

our ($VERSION) = ( '$Revision: 3.2 $ ' =~ / (\d+\.\d+)/ );

use base 'Algorithm::Evolutionary::Individual::Base';

=head1 METHODS 

=head2 new( [$length = 10] [, $start_of_range = 0] [, $end_of_range = 1] )

Creates a new random array individual, with fixed initial length, and uniform distribution
of values within a range

=cut

sub new {
  my $class = shift; 
  my $self;
  $self->{_length} = shift || 10;
  $self->{_array} = ();
  $self->{_rangestart} = shift || 0;
  $self->{_rangeend } = shift || 1;
 
  $self->{_fitness} = undef;
  bless $self, $class;
  $self->randomize();
  return $self;
}

=head2 size()

Returns vector size (dimension)

=cut

sub size {
  my $self = shift;
  return $self->{'_length'};
}

sub TIEARRAY {
  my $class = shift; 
  my $self = { _array => \@_,
               _length => scalar( @_ ),
               _fitness => undef };
  bless $self, $class;
  return $self;
}

=head2 set( $ref_to_hash )

Sets values of an individual; takes a hash as input. The array is
initialized to a null array, and the start and end range are
initialized by default to 0 and 1

=cut

sub set {
  my $self = shift; 
  my $hash = shift || croak "No params here";
  for ( keys %{$hash} ) {
    $self->{"_$_"} = $hash->{$_};
  }
  $self->{_array} = shift || ();
  $self->{_rangestart} =  $self->{_rangestart} || 0;
  $self->{_rangeend} =  $self->{_rangeend} || 1;
  $self->{_fitness} = undef;
}

=head2 randomize()

Assigns random values to the elements

=cut

sub randomize {
  my $self = shift; 
  my $range = $self->{_rangeend} - $self->{_rangestart};
  for ( my $i = 0; $i < $self->{_length}; $i++  ) {
    push @{$self->{_array}}, rand( $range ) + $self->{_rangestart};
  }
}

=head2 Atom

Gets or sets the value of an atom

=cut

sub Atom{
  my $self = shift;
  my $index = shift;
  if ( @_ ) {
    $self->{_array}[$index] = shift;
  } else {
    return $self->{_array}[$index];
  }
}

sub FETCH {
  my $self = shift;
  return $self->Atom( @_ );
}

sub STORE {
  my $self = shift;
  $self->Atom( @_ );
}

=head2 addAtom

Adds an atom at the end

=cut

sub addAtom{
  my $self = shift;
  my $atom = shift || croak "No atom to add\n";
  push( @{$self->{_array}}, $atom );
  $self->{_length}++;
}

sub PUSH {
  my $self = shift;
  push( @{$self->{_array}}, @_ );
  $self->{_length}++;
}

sub UNSHIFT {
  my $self = shift;
  unshift( @{$self->{_array}}, @_ );
  $self->{_length}++;
}

sub POP {
  my $self = shift;
  return pop ( @{$self->{_array}} );
   $self->{_length}--;
}

sub SHIFT {
  my $self = shift;
  return shift  @{$self->{_array}} ;
  $self->{_length}--;
}

sub SPLICE {
  my $self = shift;
  splice( @{$self->{_array}}, shift, shift, @_ );
  
}

sub FETCHSIZE {
  my $self = shift;
  return @{$self->{_array}} -1;
}

=head2 length()

Returns the number of atoms in the individual

=cut 

sub length {
  my $self = shift;
  return scalar @{$self->{_array}};
}

=head2 fromString( $string )

Similar to a copy ctor; creates a vector individual from a string composed of 
stuff separated by a separator

=cut

sub fromString  {
  my $class = shift; 
  my $str = shift;
  my $sep = shift || ",";
  my @ary = split( $sep, $str );
  my $self = { _array => \@ary,
               _fitness => undef };
  bless $self, $class;
  return $self;
}

=head2 clone()

Similar to a copy ctor: creates a new individual from another one

=cut

sub clone {
  my $indi = shift || croak "Indi to clone missing ";
  my $self = { _fitness => undef,
               _length => $indi->{_length} };
  $self->{_array} = ();
  push(@{$self->{_array}}, @{$indi->{_array}});
  bless $self, ref $indi;
  die "Something is wrong " if scalar( @{$self->{_array}} ) >  scalar( @{$indi->{_array}} );
  return $self;
}


=head2 asString()

Returns a string with chromosome plus fitness. OK, this is a bit confusing

=cut

sub asString {
  my $self = shift;
  my $str = $self->as_string();
  if ( defined $self->{_fitness} ) {
	$str .=", " . $self->{_fitness};
  }
  return $str;
}

=head2 as_string()

Returns just the chromosome, not the fitness

=cut

sub as_string {
  my $self = shift;
  my $str = join( ", ", @{$self->{_array}});
  return $str;
}

=head2 asXML()

Prints it as XML. See the L<Algorithm::Evolutionary::XML|lgorithm::Evolutionary::XML> OPEAL manual for details.

=cut

sub asXML {
  my $self = shift;
  my $str = $self->SUPER::asXML();
  my $str2 = ">" .join( "", map( "<atom>$_</atom> ", @{$self->{_array}} ));
  $str =~ s/\/>/$str2/e ;
  return $str."\n</indi>";
}

=head2 Chrom( [$ref_to_array]

Sets or gets the array that holds the chromosome. Not very nice, and
I would never ever do this in C++

=cut

sub Chrom {
  my $self = shift;
  if ( defined $_[0] ) {
	$self->{_array} = shift;
  }
  return $self->{_array}
}

=head1 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2011/11/23 10:59:47 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Individual/Vector.pm,v 3.2 2011/11/23 10:59:47 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.2 $

=cut
