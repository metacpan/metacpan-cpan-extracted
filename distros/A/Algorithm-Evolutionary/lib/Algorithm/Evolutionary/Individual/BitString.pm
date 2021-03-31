use strict; #-*-cperl-*-
use warnings;

=head1 NAME

Algorithm::Evolutionary::Individual::BitString - Classic bitstring individual for evolutionary computation; usually called I<chromosome>


=head1 SYNOPSIS

    use Algorithm::Evolutionary::Individual::BitString;

    my $indi = new Algorithm::Evolutionary::Individual::BitString 10 ; # Build random bitstring with length 10
                                   # Each element in the range 0 .. 1

    my $indi3 = new Algorithm::Evolutionary::Individual::BitString;
    $indi3->set( { length => 20 } );   #Sets values, but does not build the string

    $indi3->randomize(); #Creates a random bitstring with length as above

    print $indi3->Atom( 7 );       #Returns the value of the 7th character
    $indi3->Atom( 3 ) = 1;       #Sets the value

    $indi3->addAtom( 1 ); #Adds a new character to the bitstring at the end
    my $size = $indi3->size(); #Common interface to all individuals, should return 21

    my $indi4 = Algorithm::Evolutionary::Individual::BitString->fromString( '10110101');   #Creates an individual from that string

    my $indi5 = $indi4->clone(); #Creates a copy of the individual

    my @array = qw( 0 1 0 1 0 0 1 ); #Create a tied array
    tie my @vector, 'Algorithm::Evolutionary::Individual::BitString', @array;

    print $indi3->asString(); #Prints the individual
    print $indi3->as_yaml() #Change of convention, I know...

    my $gene_size = 5;
    my $min = -1;
    my $range = 2;
    my @decoded_vector = $indi3->decode( $gene_size, $min, $range);

=head1 Base Class

L<Algorithm::Evolutionary::Individual::String>

=head1 DESCRIPTION

Bitstring Individual for a Genetic Algorithm. Used, for instance, in a canonical GA

=cut

package Algorithm::Evolutionary::Individual::BitString;

use Carp;

our $VERSION =  '3.4';

use base 'Algorithm::Evolutionary::Individual::String';

use constant MY_OPERATORS => ( Algorithm::Evolutionary::Individual::String::MY_OPERATORS, 
			       qw(Algorithm::Evolutionary::Op::BitFlip Algorithm::Evolutionary::Op::Mutation )); 

use Algorithm::Evolutionary::Utils qw(decode_string); 

=head1 METHODS

=head2 new( $length )

Creates a new random bitstring individual, with fixed initial length, and 
uniform distribution of bits. Options as in L<Algorithm::Evolutionary::Individual::String>

=cut

sub new {
  my $class = shift; 
  my $chars = [ '0', '1' ];
  my $self = 
      Algorithm::Evolutionary::Individual::String::new( $class, $chars, @_ );
  return $self;
}

=head2 from_string

Similar to a copy ctor; creates a bitstring individual from a string. Will be deprecated soon

=cut

sub from_string  {
  my $class = shift; 
  my $chars = [ '0', '1' ];
  my $self = 
      Algorithm::Evolutionary::Individual::String::from_string( 'Algorithm::Evolutionary::Individual::BitString', $chars, @_ );
  return $self;
}

=head2 set( $hash )

Sets values of an individual; takes a hash as input. Keys are prepended an
underscore and turn into instance variables

=cut

sub set {
  my $self = shift; 
  my $hash = shift || croak "No params here";
  $self->{_chars} = [ '0', '1' ];
  $self->SUPER::set( $hash );
}

=head2 decode( $gene_size, $min, $range )

Decodes to a vector, each one of whose components ranges between $min
and $max. Returns that vector

=cut

sub decode {
  my $self = shift;
  my ( $gene_size, $min, $range ) = @_;
  my $chromosome = $self->{'_str'};
  return decode_string( $chromosome, $gene_size, $min, $range );
}

=head2 Copyright
  
  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut
