#!/usr/bin/perl -w 
#
# OOEnigma.pm
#
# Copyright (c) 2002 Ambriel Consulting
# sjb Mon Mar 18 20:55:53 GMT 2002
#
package Crypt::OOEnigma;

=head1 NAME

Crypt::OOEnigma - A World War II Enigma machine in a flexible OO framework

=head1 SYNOPSIS

  use Crypt::OOEnigma;
  
  my $enigma = Crypt::OOEnigma->new();
  
  # OR set the default rotors' start positions
  Crypt::OOEnigma->new( start_positions => [10,20,5] );
  
  # OR choose rotors from the set (0..5)
  Crypt::OOEnigma->new( rotor_choice    => [3,4,5]);
  
  # OR both
  Crypt::OOEnigma->new( rotor_choice    => [3,4,5],
                        start_positions => [10,20,5] );
  
  my $cipher = $enigma->encipher("Some Text");
  my $decode = $enigma->decipher($cipher);
  # OR, since Enigma's are self-inverse:
  my $decode = $enigma->encipher($cipher);

=cut 
use Carp;
use vars qw($VERSION);
$VERSION="0.3";

use Crypt::OOEnigma::Military;
use Crypt::OOEnigma::Rotor ;

=head1 DESCRIPTION

=head2 What is an Enigma?

The Enigma Machine was a much-used encryption device in the Second World War.
It was an electrical device, somewhat like a typewriter, combining substitution
and rotation ciphers in such a manner that the resulting overall cipher was
difficult to break, unlike the constituent ciphers. The machine could decode as
well as encoding messages.  

In short, the electrical Enigma is constructed from a number of rotors -
usually 3, each of which implements a simple substitution cipher on the letters
of the alphabet only, and a reflector.  The reflector is a self-inverse simple
substitution cipher with no short circuits.  On receiving a clear-text message
for transmission, the operator first replaces all spaces with the letter X,
before typing the message into the machine.  As each key is pressed, a current
passes through each rotor, the reflector and back through the rotors in reverse
order to produce the cipher-text message. As the message is processed, the
first rotor rotates once for every letter that is encoded, the second rotor
once every 26 letters, the third rotor every 26 squared letters and so on.

The Enigma is configured by selecting several rotors from a larger set, placing
them in a particular order and a particular start position.  Received messages
are decoded by setting the Enigma to the same state as the encoding Enigma and
processing the message again.  The result is clear text with the letter X
instead of spaces.

For a good description of the Enigma, including some interesting exercises, see
Part IV of "The Pleasures of Counting" by T W Korner, Cambridge University
Press.

=head2 The Commercial Enigma

The commercial Enigma typically consists of 3 rotors and a reflector.  A
Commercial Enigma is provided in the package.

=head2 The Military Enigma

It turns out that the Commercial Enigma is relatively easily cracked by brute
force methods  (see Korner) and that it can be easily strengthened by the
addition of a simple device known as the plugboard.  The plugboard is a set of
electrical plugs implementing the identity substitution (A -> A, B -> B etc)
with a number of pairs of letters - say, 6 - swapped.  The plugboard sits
between the operator's keyboard and the commercial enigma and it has an impact
far in excess of its complexity.

A Military Enigma Machine is included in the package.

=head2 The OOEnigma Module

For simplicity, this OOEnigma module supplies a number of rotors and a
military enigma machine so that the user can do one of:

=over 4

=item * Use a default Enigma

=item * Choose 3 rotors

=item * Choose start positions

=item * Choose both 3 rotors and their start positions

=back

And the Enigma takes care of the rest.  Users who wish to use their own
substitution codes or create their own Enigmas should see the documentation for
the individual modules. 

=head2 Creating your own Enigmas.

Enigmas based on an arbitrary number of rotors and using rotors, reflectors
and plugboards with any reasonable cipher may be easily constructed.  The
user creates the required Rotor, Reflector and Plugboard objects then uses
them to instantiate either a Military or Commercial Enigma.

=head1 NOTES

None

=head1 BUGS and CAVEATS

=head2 Enigma is weak!

Cryptographers talk of the strength of a cryptographic algorithm in term of
whether it is computationally feasible to break it.  It is, of course,
computationally feasible to break an Enigma cipher so don't use it for anything
serious!

=head1 HISTORY

This package was created in spring 2002 as an exercise in OO Perl and preparing
modules properly for CPAN.  More importantly, the Enigma is interesting.

CPAN already has a Crypt::Enigma which is not object-oriented and implements
only one Enigma (whereas you can create any Enigma-like machine with these
objects).  Hence the package name Crypt::OOEnigma

=head1 SEE ALSO

The Pleasures of Counting, T W Korner, CUP 1996.  A great book for anyone with
the slightest interest in mathematics:
  ISBN 0 521 56087 X hardback
  ISBN 0 521 56823 4 paperback 

The Enigmas:
  Crypt::OOEnigma::Military
  Crypt::OOEnigma::Commercial

The components:
  Crypt::OOEnigma::Rotor
  Crypt::OOEnigma::Reflector
  Crypt::OOEnigma::Plugboard

=head1 AUTHOR

S J Baker, Ambriel Consulting, http://ambrielconsulting.com

=head1 COPYRIGHT

This package is licenced under the same terms as Perl itself.

=cut

our $numrotors = 3 ; # As in a German Army Enigma

#
# We need a set of 6 substitutions for 6 rotors from which to choose 3
#
my @subs = (
    [V,U,D,J,A,E,Y,N,H,F,P,Q,C,X,G,K,L,T,W,Z,R,O,B,M,S,I],
    [P,Z,I,O,U,C,B,T,V,K,Q,L,H,G,W,D,F,X,A,J,E,R,N,S,M,Y],
    [W,S,D,B,I,J,V,M,X,K,Y,H,P,O,L,T,N,A,Q,F,Z,C,U,E,G,R],
    [R,K,A,T,Q,B,S,M,D,O,L,J,C,G,H,I,W,Y,P,X,E,U,Z,F,V,N],
    [Y,S,F,J,Z,V,N,A,P,R,T,I,H,G,U,O,L,E,C,M,W,Q,B,K,X,D],
    [W,U,R,B,E,L,K,O,X,V,Q,H,M,N,G,I,A,S,T,F,Z,Y,C,D,J,P],
);

#
# Now we can get on with the enigma
#
  
# use Autoloading for accessors
use subs qw(enigma rotor_choice start_positions);

sub AUTOLOAD {
  my $self = shift;
  # only access instance methods not class methods
  croak "$self is not an object" unless(ref($self));
  my $name = our $AUTOLOAD;
  return if($name =~ /::DESTROY/ );
  $name =~ s/.*://;   # strip fully-qualified portion
  unless (exists $self->{$name} ) {
    croak "Can't access `$name' field in object of class $self";
  } 
  if (@_) {
    return $self->{$name} = shift;
  } else {
    return $self->{$name};
  } 
}
my %fields = (
  enigma          => undef,
  rotor_choice    => [0,1,2],
  start_positions => [0,0,0]
);

sub new {
  my $invocant = shift ;
  my $class = ref($invocant) || $invocant ;
  my $self = { %fields, @_ } ; 
  bless $self, $class ;
  
  # Ensure we have a good set of rotors
  my $num_rotors = scalar(@{$self->rotor_choice()});
  croak "You must select exactly 3 rotors."   
    if($num_rotors != 3);
  croak "You must select rotors from the range 0 to 5" 
    if( grep !/[012345]/, @{$self->rotor_choice()} );

  my @rotors = ();
  my @alpha = (A..Z);

  #
  #  Set up the chosen rotors and the enigma
  #
  for( my $i = 0 ; $i < $numrotors ; ++$i ){
    
    # assembling the cipher hash for the rotor
    my $sublist = $subs[$self->rotor_choice->[$i]];
    my $subHash = {}; 
    for(my $j = 0 ; $j < 26 ; ++$j){
      $subHash->{$alpha[$j]} = $$sublist[$j]; 
    }

    # this rotor's start position
    my $pos = $self->start_positions->[$i];

    push @rotors, Crypt::OOEnigma::Rotor->new(cipher => $subHash, 
                                              start_position => $pos);
  }

  my $e = Crypt::OOEnigma::Military->new(rotors => \@rotors);
  $self->enigma($e);
  
  return $self ;
}


sub encipher {
  my $self = shift;
  return $self->enigma()->encipher(shift);
}

sub decipher {
  my $self = shift;
  # Enigmas are a self-inverse
  return $self->enigma()->encipher(shift);
}

1;

