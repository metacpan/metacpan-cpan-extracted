use strict;
use warnings;

use lib qw(../../../lib);

=encoding utf8

=head1 NAME

    Algorithm::Evolutionary::Individual::String - A character string to be evolved. Useful mainly in word games

=head1 SYNOPSIS

    use Algorithm::Evolutionary::Individual::String;

    my $indi = new Algorithm::Evolutionary::Individual::String ['a'..'z'], 10;
                                   # Build random bitstring with length 10

    my $indi3 = new Algorithm::Evolutionary::Individual::String;
    $indi3->set( { length => 20,
		   chars => ['A'..'Z'] } );   #Sets values, but does not build the string
    $indi3->randomize(); #Creates a random bitstring with length as above
    print $indi3->Atom( 7 );       #Returns the value of the 7th character
    $indi3->Atom( 3, 'Q' );       #Sets the value

    $indi3->addAtom( 'K' ); #Adds a new character to the bitstring at the end

    my $indi4 = Algorithm::Evolutionary::Individual::String->fromString( 'esto es un string');   #Creates an individual from that string

    my $indi5 = $indi4->clone(); #Creates a copy of the individual

    my @array = qw( a x q W z ñ); #Tie a String individual
    tie my @vector, 'Algorithm::Evolutionary::Individual::String', @array;

    print $indi3->as_string(); #Prints the individual

=head1 Base Class

L<Algorithm::Evolutionary::Individual::Base>

=head1 DESCRIPTION

String Individual for a evolutionary algorithm. Contains methods to handle strings 
easily. It is also TIEd so that strings can be handled as arrays.

=head1 METHODS

=cut

package Algorithm::Evolutionary::Individual::String;

use Carp;

our $VERSION = '3.7';

use base 'Algorithm::Evolutionary::Individual::Base';

=head2 MY_OPERATORS

Known operators that act on this subroutine. Probably will be deprecated, so don't rely on its presence

=cut

use constant MY_OPERATORS => qw(Algorithm::Evolutionary::Op::Crossover
				Algorithm::Evolutionary::Op::QuadXOver
				Algorithm::Evolutionary::Op::StringRand
				Algorithm::Evolutionary::Op::Permutation
				Algorithm::Evolutionary::Op::IncMutation
				Algorithm::Evolutionary::Op::ChangeLengthMutation );

=head2 new

Creates a new random string, with fixed initial length, and uniform
distribution of characters along the character class that is
defined. However, this character class is just used to generate new
individuals and in mutation operators, and the validity is not
enforced unless the client class does it

=cut

sub new {
  my $class = shift;
  my $self = Algorithm::Evolutionary::Individual::Base::new( $class );
  $self->{'_chars'} = shift || ['a'..'z'];
  $self->{'_length'} = shift || 10;
  $self->randomize();
  return $self;
}

sub TIEARRAY {
  my $class = shift;
  my $self = { _str => join("",@_),
               _length => scalar( @_ ),
               _fitness => undef };
  bless $self, $class;
  return $self;
}

=head2 randomize

Assigns random values to the elements

=cut

sub randomize {
  my $self = shift; 
  $self->{'_str'} = ''; # Reset string
  for ( my $i = 0; $i <  $self->{'_length'}; $i ++ ) {
	$self->{'_str'} .= $self->{'_chars'}[ rand( @{$self->{'_chars'}} ) ];
  }
}

=head2 addAtom

Adds an atom at the end

=cut

sub addAtom{
  my $self = shift;
  my $atom = shift;
  $self->{_str}.= $atom;
}

=head2 fromString

Similar to a copy ctor; creates a bitstring individual from a string. Will be deprecated soon

=cut

sub fromString  {
  my $class = shift; 
  my $str = shift;
  my $self = Algorithm::Evolutionary::Individual::Base::new( $class );
  $self->{_str} =  $str;
  my %chars;
  map ( $chars{$_} = 1, split(//,$str) );
  my @chars = keys %chars; 
  $self->{_length} = length( $str  );
  $self->{'_chars'} = \@chars;
  return $self;
}

=head2 from_string

Similar to a copy ctor; creates a bitstring individual from a string. 

=cut

sub from_string  {
  my $class = shift; 
  my $chars = shift;
  my $str = shift;
  my $self = Algorithm::Evolutionary::Individual::Base::new( $class );
  $self->{'_chars'} = $chars;
  $self->{'_str'} =  $str;
  $self->{'_length'} = length( $str  );
  return $self;
}

=head2 clone

Similar to a copy ctor: creates a new individual from another one

=cut

sub clone {
  my $indi = shift || croak "Indi to clone missing ";
  my $self = { '_fitness' => undef };
  bless $self, ref $indi;
  for ( qw( _chars _str _length)  ) {
	$self->{ $_ } = $indi->{$_};
  }
  return $self;
}


=head2 asString

Returns the individual as a string with the fitness as a suffix.

=cut

sub asString {
  my $self = shift;
  my $str = $self->{'_str'} . " -> ";
  if ( defined $self->{'_fitness'} ) {
	$str .=$self->{'_fitness'};
  }
  return $str;
}

=head2 Atom

Sets or gets the value of the n-th character in the string. Counting
starts at 0, as usual in Perl arrays.

=cut

sub Atom {
  my $self = shift;
  my $index = shift;
  if ( @_ ) {
    substr( $self->{_str}, $index, 1 ) = substr(shift,0,1);
  } else {
    substr( $self->{_str}, $index, 1 );
  }
}

=head2 TIE methods

String implements FETCH, STORE, PUSH and the rest, so an String
can be tied to an array and used as such.

=cut

sub FETCH {
  my $self = shift;
  return $self->Atom( @_ );
}

sub STORE {
  my $self = shift;
  $self->Atom( @_ );
}

sub PUSH {
  my $self = shift;
  $self->{_str}.= join("", @_ );
}

sub UNSHIFT {
  my $self = shift;
  $self->{_str} = join("", @_ ).$self->{_str} ;
}

sub POP {
  my $self = shift;
  my $pop = substr( $self->{_str}, length( $self->{_str} )-1, 1 );
  substr( $self->{_str}, length( $self->{_str} ) -1, 1 ) = ''; 
  return $pop;
}

sub SHIFT {
  my $self = shift;
  my $shift = substr( $self->{_str}, 0, 1 );
  substr( $self->{_str}, 0, 1 ) = ''; 
  return $shift;
}

sub SPLICE {
  my $self = shift;
  my $offset = shift;
  my $length = shift || length( $self->{'_str'} - $offset );
  my $sub_string =  substr( $self->{_str}, $offset, $length );
#  if ( @_ ) {
    substr( $self->{_str}, $offset, $length ) = join("", @_ );
#  } 
  return split(//,$sub_string);
}

sub FETCHSIZE {
  my $self = shift;
  return length( $self->{_str} );
}

=head2 size()

Returns length of the string that stores the info; overloads abstract base method. 

=cut 

sub size {
  my $self = shift;
  return length($self->{_str}); #Solves ambiguity
}

=head2 as_string() 
    
    Returns the string used as internal representation

=cut

sub as_string {
    my $self = shift;
    return $self->{_str};
}

=head2 Chrom

Sets or gets the variable that holds the chromosome. Not very nice, and
I would never ever do this in C++

=cut

sub Chrom {
  my $self = shift;
  if ( defined $_[0] ) {
    $self->{_str} = shift;
  }
  return $self->{_str}
}

=head1 Known subclasses

=over 4

=item *

L<Algorithm::Evolutionary::Individual::BitString|Algorithm::Evolutionary::Individual::BitString>

=back

=head2 Copyright

  This file is released under the GPL. See the LICENSE file included in this distribution,
  or go to http://www.fsf.org/licenses/gpl.txt

=cut
