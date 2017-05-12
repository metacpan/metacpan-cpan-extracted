#------------------------------------------------------------------------------#
# Crypt::Solitaire
#
# Solitaire cryptosystem, as used in Neal Stephenson's novel _Cryptonomicon_
# Designed by Bruce Schneier (President, Counterpane Systems)
# Original Perl Code by Ian Goldberg <ian@cypherpunks.ca>, 19980817
# Minor changes and module-ification by Kurt Kincaid <sifukurt@yahoo.com>
#
#       Last Modified:  28-Nov-2001 04:20:10 PM
#       Copyright(c) 2001, Kurt Kincaid. All Rights Reserved.
#
# This is free software and may be modified and/or redistributed under the
# same terms as perl itself.
#------------------------------------------------------------------------------#

package Crypt::Solitaire;
use strict;
use vars qw($VERSION @ISA @EXPORT @EXPORT_OK $multFactor $k $D $c $v $Deck $text $passphrase $mode $class );

require Exporter;

@ISA       = qw(Exporter AutoLoader);
@EXPORT_OK = qw(Pontifex);

$VERSION = "2.0";

sub new {
    ( $class, $passphrase ) = @_;
    $passphrase =~ y/a-z/A-Z/;
    $passphrase =~ s/[A-Z]/$k=ord($&)-64,&e/eg;
    my $self = bless {}, $class;
    return $self;
}

sub encrypt {
    my $self = shift;
    ( $text, $passphrase ) = @_;
    return Pontifex( $text, $passphrase, "e" );
}

sub decrypt {
    my $self = shift;
    ( $text, $passphrase ) = @_;
    return Pontifex( $text, $passphrase, "d" );
}

sub Pontifex {
    if ( ref $_[ 0 ] ) {
        my $self = shift;
    }
    ( $text, $passphrase, $mode ) = @_;
    if ( $mode =~ /^e/i ) {
        $multFactor = 1;
    } elsif ( $mode =~ /^d/i ) {
        $multFactor = -1;
    } else {
        return undef;
    }

    $Deck = pack( 'C*', 33 .. 86 );

    $k = 0;

    $text =~ y/a-z/A-Z/;
    $text =~ y/A-Z//dc;
    if ( $multFactor == 1 ) {
        $text .= "X" while length( $text ) % 5;
    }
    $text =~ s/./chr((ord($&)-13+$multFactor*&e)%26+65)/eg;

    if ( $multFactor == -1 ) {
        $text =~ s/X*$//;
    }
    $text =~ s/.{5}/$& /g;
    return $text;
}

sub v {
    $v = ord( substr( $D, $_[ 0 ] ) ) - 32;
    $v > 53 ? 53 : $v;
}

sub e {
    $D =~ s/(.*)U$/U$1/;
    $D =~ s/U(.)/$1U/;

    $D =~ s/(.*)V$/V$1/;
    $D =~ s/V(.)/$1V/;
    $D =~ s/(.*)V$/V$1/;
    $D =~ s/V(.)/$1V/;

    $D =~ s/(.*)([UV].*[UV])(.*)/$3$2$1/;

    $c = &v( 53 );
    $D =~ s/(.{$c})(.*)(.)/$2$1$3/;

    if ( $k ) {
        $D =~ s/(.{$k})(.*)(.)/$2$1$3/;
        return;
    }

    $c = &v( &v( 0 ) );

    $c > 52 ? &e : $c;
}

1;
__END__


=head1 NAME

Crypt::Solitaire - Solitaire encryption

=head1 SYNOPSIS

# OO Interface
  use Crypt::Solitaire;
  $ref = Crypt::Solitaire->new( $passphrase );
  $encrypted = $ref->encrypt( $text );
  
  $ref2 = Crypt::Solitaire->new( $passphrase );
  $decrypted = $ref2->decrypt( $encrypted );
  
# Functional Interface

  use Crypt::Solitaire;
  my $encrypted = Pontifex( $plaintext, $passphrase, $mode );

=head1 DESCRIPTION

Solitaire is a top-notch pencil-and-paper encryption system developed by Bruce Schneier.
Here is the description in Schneier's own words:

"In Neal Stephenson's novel Cryptonomicon, the character Enoch Root describes a
cryptosystem code-named "Pontifex" to another character named Randy Waterhouse, and later
reveals that the steps of the algorithm are intended to be carried out using a deck of
playing cards. These two characters go on to exchange several encrypted messages using
this system. The system is called "Solitaire" (in the novel, "Pontifex" is a code name
intended to temporarily conceal the fact that it employs a deck of cards) and I designed
it to allow field agents to communicate securely without having to rely on electronics or
having to carry incriminating tools. An agent might be in a situation where he just does
not have access to a computer, or may be prosecuted if he has tools for secret
communication. But a deck of cards...what harm is that? 

"Solitaire gets its security from the inherent randomness in a shuffled deck of cards. By
manipulating this deck, a communicant can create a string of "random" letters that he
then combines with his message. Of course Solitaire can be simulated on a computer, but
it is designed to be implemented by hand. 

"Solitaire may be low-tech, but its security is intended to be high-tech. I designed
Solitaire to be secure even against the most well-funded military adversaries with the
biggest computers and the smartest cryptanalysts. Of course, there is no guarantee that
someone won't find a clever attack against Solitaire, but the algorithm is certainly
better than any other pencil-and-paper cipher I've ever seen."

Simple system, easy to use, and relatively fast.

=head1 LIMITATIONS

Restricted only to letters A..Z. Lower case letters are converted to upper
case, and due to the fact that Solitaire applies its own formatting to the text, the
output can be a little tricky at first glance.

It also should be noted that there is a verified bias in the algorithm. Fore more
information on this, go here: http://www.ciphergoth.org/crypto/solitaire/

=head1 METHODS

=over 4

=item B<Pontifex> $text, $passphrase, $mode

$text is encrypted using $passphrase.  Encrypts or decrypts, based on $mode.  Mode must
be set to "e" or "d," for encrypting and decrypting, respectively.

=back

=head1 AUTHOR

Designed by Bruce Schneier (President, Counterpane Systems)

Original Perl Code by Ian Goldberg <ian@cypherpunks.ca>, 19980817

Minor changes and module-ification by Kurt Kincaid <sifukurt@yahoo.com>

=head1 SEE ALSO

perl(1), Counterpane System (http://www.counterpane.com).

=cut

