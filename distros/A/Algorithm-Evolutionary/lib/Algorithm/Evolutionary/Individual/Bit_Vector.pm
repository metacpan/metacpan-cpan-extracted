use strict; #-*-cperl-*-
use warnings;

use lib qw(../../../../lib);

=head1 NAME

    Algorithm::Evolutionary::Individual::Bit_Vector - Classic bitstring individual for evolutionary computation; 
                 usually called chromosome, and using a different implementation from Algorithm::Evolutionary::Individual::BitString


=head1 SYNOPSIS

    use Algorithm::Evolutionary::Individual::BitVector;

    my $indi = new Algorithm::Evolutionary::Individual::Bit_Vector 10 ; # Build random bitstring with length 10
                                   # Each element in the range 0 .. 1

    my $indi3 = new Algorithm::Evolutionary::Individual::Bit_Vector;
    $indi3->set( { length => 20 } );   #Sets values, but does not build the string
    
    $indi3->randomize(); #Creates a random bitstring with length as above
 
    print $indi3->Atom( 7 );       #Returns the value of the 7th character
    $indi3->Atom( 3 ) = 1;       #Sets the value

    $indi3->addAtom( 1 ); #Adds a new character to the bitstring at the end

    my $indi4 = Algorithm::Evolutionary::Individual::Bit_Vector->fromString( '10110101');   #Creates an individual from that string

    my $indi5 = $indi4->clone(); #Creates a copy of the individual

    my @array = qw( 0 1 0 1 0 0 1 ); #Create a tied array
    tie my @vector, 'Algorithm::Evolutionary::Individual::Bit_Vector', @array;
    print tied( @vector )->asXML();

    print $indi3->asString(); #Prints the individual
    print $indi3->asXML() #Prints it as XML. See L<Algorithm::Evolutionary::XML>
    print $indi3->as_yaml() #Change of convention, I know...

=head1 Base Class

L<Algorithm::Evolutionary::Individual::String|Algorithm::Evolutionary::Individual::String>

=head1 DESCRIPTION

Bitstring Individual for a Genetic Algorithm. Used, for instance, in a canonical GA

=cut

package Algorithm::Evolutionary::Individual::Bit_Vector;

use Carp;
use Bit::Vector;
use String::Random; # For initial string generation

our ($VERSION) =  ( '$Revision: 3.1 $ ' =~ / (\d+\.\d+)/ );

use base 'Algorithm::Evolutionary::Individual::Base';

use constant MY_OPERATORS => ( qw(Algorithm::Evolutionary::Op::BitFlip Algorithm::Evolutionary::Op::Mutation )); 
 

=head1 METHODS

=head2 new( $arg )

Creates a new bitstring individual. C<$arg> can be either { length =>
    $length} or { string => [binary string] }. With no argument, a
    length of 16 is given by default.

=cut

sub new {
    my $class = shift; 
    my $self = Algorithm::Evolutionary::Individual::Base::new( $class );
    my $arg = shift || { length => 16};
    if ( $arg =~ /^\d+$/ ) { #It's a number
      $self->{'_bit_vector'} = _create_bit_vector( $arg );
    } elsif ( $arg->{'length'} ) {
      $self->{'_bit_vector'} = _create_bit_vector( $arg->{'length'} );
    } elsif ( $arg->{'string'} ) {
      $self->{'_bit_vector'} = 
	Bit::Vector->new_Bin( length($arg->{'string'}), $arg->{'string'} );
    } 
    croak "Incorrect creation options" if !$self->{'_bit_vector'};
    return $self;
}

sub _create_bit_vector {
   my $length = shift || croak "No length!";
   my $rander = new String::Random;
   my $hex_string = $rander->randregex("[0-9A-F]{".int($length/4)."}");
   return Bit::Vector->new_Hex( $length, $hex_string );
}

sub TIEARRAY {
  my $class = shift; 
  my $self = { _bit_vector => Bit::Vector->new_Bin(scalar( @_), join("",@_)) };
  bless $self, $class;
  return $self;
}

=head2 Atom

Sets or gets the value of the n-th character in the string. Counting
starts at 0, as usual in Perl arrays.

=cut

sub Atom: lvalue {
  my $self = shift;
  my $index = shift;
  my $last_index = $self->{'_bit_vector'}->Size()-1;
  if ( @_ ) {
      $self->{'_bit_vector'}->Bit_Copy($last_index-$index, shift );
  } else {
      $self->{'_bit_vector'}->bit_test($last_index - $index);
  }
}

=head2 size()

Returns size in bits 

=cut

sub size {
    my $self = shift;
    return $self->{'_bit_vector'}->Size();
}

=head2 clone()

Clones using native methods. Does not work with general Clone::Fast, since it's implemented as an XS

=cut

sub clone {
    my $self = shift;
    my $clone = Algorithm::Evolutionary::Individual::Base::new( ref $self );
    $clone->{'_bit_vector'} = $self->{'_bit_vector'}->Clone();
    return $clone;
}

=head2 as_string() 

Overrides the default; prints the binary chromosome 

=cut

sub as_string {
  my $self = shift;
  return $self->{'_bit_vector'}->to_Bin();
}

=head2 Chrom()

Returns the internal bit_vector

=cut

sub Chrom {
  my $self = shift;
  return $self->{'_bit_vector'};
}

=head2 TIE methods

String implements FETCH, STORE, PUSH and the rest, so an String
can be tied to an array and used as such.

=cut

sub FETCH {
  my $self = shift;
  my $bit_vector = $self->{'_bit_vector'};
  return $bit_vector->bit_test( $bit_vector->Size() - 1 - shift );
}

sub STORE {
  my $self = shift;
  my $bit_vector = $self->{'_bit_vector'};
  my $index = shift;
  $self->{'_bit_vector'}->Bit_Copy($bit_vector->Size()- 1 -$index, shift );
}

sub PUSH {
    my $self = shift;
    my $new_vector =  Bit::Vector->new_Bin(scalar(@_), join("",@_));
    $self->{'_bit_vector'} = $self->{'_bit_vector'}->Concat( $new_vector );
}

sub UNSHIFT {
    my $self = shift;
    my $new_vector =  Bit::Vector->new_Bin(scalar(@_), join("",@_));
    $self->{'_bit_vector'}  = Bit::Vector->Concat_List( $new_vector, $self->{'_bit_vector'}) ;
}

sub POP {
  my $self = shift;
  my $bit_vector = $self->{'_bit_vector'};
  my $length = $bit_vector->Size();
  my $pop = $bit_vector->lsb();
  $self->{'_bit_vector'}->Delete(0,1);
  $self->{'_bit_vector'}->Resize($length-1);
  return $pop;
}

sub SHIFT {
  my $self = shift;
  my $length = $self->{'_bit_vector'}->Size();
  my $bit =  $self->{'_bit_vector'}->shift_left('0');
  $self->{'_bit_vector'}->Reverse( $self->{'_bit_vector'});
  $self->{'_bit_vector'}->Resize($length-1);
  $self->{'_bit_vector'}->Reverse( $self->{'_bit_vector'});

  return $bit;
}

sub SPLICE {
  my $self = shift;
  my $offset = shift;
  my $bits = shift;
  my $new_vector;
  my $slice = Bit::Vector->new($bits);
  my $size =  $self->{'_bit_vector'}->Size();
  $slice->Interval_Copy(  $self->{'_bit_vector'}, 0, $size-$offset-$bits,  $bits );
  if ( @_ ) {
    $new_vector =  Bit::Vector->new_Bin(scalar(@_), join("",@_));
    $self->{'_bit_vector'}->Interval_Substitute( $new_vector, 
						 $size-$offset-$bits, 0 , 0, 
						 $new_vector->Size() );
  } else {
    $self->{'_bit_vector'}->Interval_Substitute( Bit::Vector->new(0), $size-$offset-$bits, $bits,
						 0, 0  );
  } 
  return split(//,$slice->to_Bin());

}

sub FETCHSIZE {
  my $self = shift;
  return length( $self->{'_bit_vector'}->Size() );
}


=head2 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

  CVS Info: $Date: 2010/12/19 21:39:12 $ 
  $Header: /media/Backup/Repos/opeal/opeal/Algorithm-Evolutionary/lib/Algorithm/Evolutionary/Individual/Bit_Vector.pm,v 3.1 2010/12/19 21:39:12 jmerelo Exp $ 
  $Author: jmerelo $ 
  $Revision: 3.1 $
  $Name $

=cut
