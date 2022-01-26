package Crypt::Cipher::Vigenere;

our $VERSION = '0.03';

use v5.20;
use strict;
use warnings;
use experimental 'signatures';

sub new ($class, $key) {
  bless( { key => $key, pos => 0 }, $class )
}

# return the current key character and advance the position
sub _next_key_letter ($self)
{
  my $c = substr($self->{key}, $self->{pos}, 1);
  $self->{pos}++;
  $self->{pos} = 0 unless $self->{pos} < length($self->{key});
  return $c;
}

# enciphering/deciphering function; the only difference is the direction of the
# shifts
sub _cipher ($self, $plaintext, $direction)
{
  my $ciphertext = '';

  # split into individual characters
  my @pt = split(//, $plaintext);

  # process plaintext characters
  foreach my $letter (@pt) {

    # we only operate on the 26 letters of the English alphabet, everything else
    # is passed through unchanged
    unless($letter =~ /[A-Z]/i) {
      $ciphertext .= $letter;
      next;
    }

    # get number of shifts
    my $shift = ord(uc $self->_next_key_letter) - ord('A');

    # shift the plaintext letter
    my $cipherletter .= chr(
      (
        (
          (
            ord(uc $letter) - ord('A')
          ) + $direction * $shift
        ) % 26
      ) + ord('A')
    );

    # preserve case
    $cipherletter = lc $cipherletter if $letter =~ /[a-z]/;

    # finish this iteration
    $ciphertext .= $cipherletter;
  }

  return $ciphertext;
}

# encode/decode mapped to the internal _cipher() function
sub encode ($self, $plaintext) { $self->_cipher($plaintext, 1) };
sub decode ($self, $ciphertext) { $self->_cipher($ciphertext, -1) };

# reset key position
sub reset ($self) { $self->{pos} = 0 }

1;

__END__

=pod

=head1 NAME

Crypt::Cipher::Vigenere - implementation of Vigenere cipher

=head1 SYNOPSIS

    use Crypt::Cipher::Vigenere;

    my $vigenere = Crypt::Cipher::Vigenere->new( $key );

    # encode plaintext
    my $cipher_text = $vigenere->encode( $plain_text );

    # decode ciphertext
    my $plain_text = $vigenere->decode( $cipher_rtext );

    # reset internal position in the key
    $vigenere->reset;

=head1 DESCRIPTION

Perl implementation of the Vigenere cipher. Cipher key is specified as argument
to the constructor and it should only contain letters A to Z (case is ignored).
Using anything but ASCII letters will result in undefined behaviour.

Plaintext can be any sequence of characters, but anything but letters A to Z
is passed through unenciphered. Letters preserve their case through the
enciphering/deciphering.

The instance keeps track of the last position in the key, so subsequent call
properly continue in the enciphering process. If need to reset the position,
use the 'reset' method. Please note, that this key position is shared for both
enciphering and deciphering, so when you want to use the same instance for
deciphering text you just enciphered, you must reset it.

=head1 METHODS

=head2 C<new>

Returns new instance with key specified as the only argument. The key is
a character string where only [A-Za-z] characters are allowed. Case has no
bearing on the enciphering/deciphering process.

=head2 C<encode>

Takes plaintext as argument and returns ciphertext. Subsequent calls to this
method do not reset the position in the key, but continue where the last call
left off.

=head2 C<decode>

Takes ciphertext as argument and returns plaintext. Subsequent calls to this
method do not reset the position in the key, but continue where the last call
left off.

=head2 C<reset>

Reset the internal position to the start of the key.

=head1 AUTHOR

Borek Lupomesky <borek@lupomesky.cz>

=cut
