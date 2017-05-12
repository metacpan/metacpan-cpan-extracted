#!/usr/bin/perl -w
#
# Rotor.pm:
#
# Copyright (c) 2002 Ambriel Consulting
# sjb Sun Mar 17 20:43:56 GMT 2002
#

package Crypt::OOEnigma::Rotor ;
$VERSION="0.3";

=head1 NAME

Crypt::OOEnigma::Rotor - The Rotor object for use in Crypt::OOEnigma

=head1 SYNOPSIS

  my $rotor = Crypt::OOEnigma::Rotor->new();
  
  # OR
  my $subHash ={ # the substitution code for the cipher for all A..Z
                 A => "Z",
                 B => "G",
                 # etc
               };
  my $freq = 2 ; # The number of letters enciphered per rotation
  my $start_position = 20 ; # modulo 26
  my $rotor = Crypt::OOEnigma::Rotor->new(cipher  => $subHash, 
                                          freq    => $freq
                                          start_position => $pos);


  # for internal use by Enigma machines:
  $rotor->init(); # returns the Rotor to its initial state
  my $op = $rotor->encode($some_letter); # encode a letter in the forward direction
  $op    = $rotor->revencode($some_letter); # encode a letter in the reverse direction
  $rotor->next(); # prepare for the next encoding, rotating as required
  $rotor->rotate(); # rotate to the next position

=head1 DESCRIPTION

This is the Rotor for use in Crypt::OOEnigmas.  Use it when you want to
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

# This rotor's substitution, identity by default
my @alpha = (A..Z);
my $subst = {};
foreach  my $val (@alpha){ 
  $subst->{$val} = $val ; 
}

my %fields = (
  cipher          => $subst,
  current_cipher  => {},
  inverse_cipher  => {},
  start_position  => 0,
  freq            => 1,
  use_count       => 0
);

# use Autoloading for accessors
use subs qw(cipher current_cipher inverse_cipher start_position freq use_count);

sub new {
  my $invocant = shift ;
  my $class = ref($invocant) || $invocant ;
  my $self = { %fields, @_ } ; 
  bless $self, $class ;
  $self->init(); # rotate the rotor to the correct position
  return $self ;
}

sub init {
  my $self = shift ; 
  # the current_cipher is based on the initial wiring of the rotor
  $self->current_cipher(Storable::dclone($self->cipher()));
  # Set the rotor to the correct position
  $self->rotate($self->start_position());
  # and set the appropriate reverse cipher
  my %inverse = reverse( %{$self->current_cipher()} );
  $self->inverse_cipher(\%inverse);
  # reset the use count
  $self->use_count(0);
}

sub encode {
  my $self = shift ; 
  my $source = shift;
  croak("Give me uppercase letters only") unless( $source =~ /[A-Z]/);
  my $result = $self->current_cipher()->{$source};
  $self->use_count($self->use_count() + 1);
  return $result;
}

# "reverse encode"
sub revencode {
  my $self = shift ; 
  my $source = shift;
  return $self->inverse_cipher()->{$source};
}

sub next{
  my $self = shift ; 
  # rotate if required
  if( ($self->use_count() % $self->freq()) == 0 ){
    $self->rotate(1);
  }
}

sub rotate {
  # TODO consider efficiency
  my $self = shift ; 
  my $places = shift;
  my @alpha = (A..Z);
  
  # get the old substitution and rotate it
  my @sub = (); 
  foreach my $key (@alpha){ 
    push @sub, $self->current_cipher()->{$key};
  }
  for(my $i = 0 ; $i < $places ; ++$i){
    unshift @sub, (pop @sub);
  }

  # create a new substitution hash from the new substitution
  my $newSub = {};
  foreach  my $key (@alpha){ 
    $newSub->{$key} = shift @sub ; 
  }

  # set up the new ciphers
  $self->current_cipher($newSub);
  my %inverse = reverse( %{$self->current_cipher()} );
  $self->inverse_cipher(\%inverse);

  return ;
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
