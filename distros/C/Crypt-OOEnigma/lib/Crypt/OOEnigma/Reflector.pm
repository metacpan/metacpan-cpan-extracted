#!/usr/bin/perl -w
#
# Reflector.pm
#
# Copyright (c) 2002 Ambriel Consulting
# sjb Sun Mar 17 20:43:56 GMT 2002
#

package Crypt::OOEnigma::Reflector ;
$VERSION="0.3";
=head1 NAME

Crypt::OOEnigma::Reflector - The Reflector object for use in Crypt::OOEnigma

=head1 SYNOPSIS

  my $reflector = Crypt::OOEnigma::Reflector->new();

  # OR

  my $subHash ={ # A self-inverse cipher with no short-circuits
                 A => "Z",
                 B => "G",
                 # etc
               };
  my $reflector = Crypt::OOEnigma::Reflector->new(cipher  => $subHash);

  # for internal use by Enigma machines
  my $reflected_letter = $reflector->reflect($some_letter);

=head1 DESCRIPTION

This is the Reflector for use in Crypt::OOEnigmas.  Use it when you want to
create your own Enigmas with specific properties.

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

CPAN already has a Crypt::Enigma which is not object oriented and implements
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
use Storable ;
use Carp ;

# The reflector's substitution must be self-inverse
my $subst = {
  A => "Z", B => "Y", C => "X", D => "W", E => "V",
  F => "U", G => "T", H => "S", I => "R", J => "Q",
  K => "P", L => "O", M => "N", N => "M", O => "L",
  P => "K", Q => "J", R => "I", S => "H", T => "G",
  U => "F", V => "E", W => "D", X => "C", Y => "B",
  Z => "A"
};

my %fields = (
  cipher   => $subst,
);

# use Autoloading for accessors
use subs qw(cipher);

sub new {
  my $invocant = shift ;
  my $class = ref($invocant) || $invocant ;
  my $self = { %fields, @_ } ; 
  bless $self, $class ;

  # TODO: check the cipher is in fact self-inverse

  return $self ;
}

sub reflect {
  my $self = shift;
  my $source = shift;
  return $self->cipher()->{$source};
}

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

1;
