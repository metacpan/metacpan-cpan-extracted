package Crypt::Rot47;
use strict;
use warnings;
use base 'Exporter';
our @EXPORT_OK = qw(rot47);

our $VERSION = 0.06;

sub new
{
    my ($class) = @_;

    # This object is basically nothing,
    # and I provide an OOP interface just
    # to be API-consistent with other
    # similar Crypt:: modules.
    return bless [], $class;
}

sub encrypt
{
    return rot47($_[1]);
}

sub decrypt
{
    return rot47($_[1]);
}

sub rot47
{
    my ($text) = @_;
    return '' if !defined $text;

    # Rotate every character from decimal 33 '!' 
    # through 126 '~' by 47 positions
    $text =~ tr/!-~/P-~!-O/;

    return $text;
}

1;
__END__

=head1 NAME

Crypt::Rot47 - Encryption and decryption of ASCII text using the ROT47 substitution cipher. 

=head1 SYNOPSIS

  # Object-oriented interface
  use Crypt::Rot47; 

  my $cipher = new Crypt::Rot47();
  my $ciphertext = $cipher->encrypt('Shhh... this is a secret message');

  print "$ciphertext\n";     # Prints "$999]]] E9:D :D 2 D64C6E >6DD286"

  my $plaintext = $cipher->decrypt($ciphertext);

  print "$plaintext\n";        # Prints "Shhh... this is a secret message"

  # Simpler non-OOP interface
  use Crypt::Rot47 qw(rot47);

  my $ciphertext = rot47('Shhh... this is a secret message');
  my $plaintext  = rot47($ciphertext);

=head1 DESCRIPTION

This module applies the ROT47 substitution cipher to ASCII text, thereby scrambling
it and making it difficult for others to read. Applying the same ROT47 substitution
cipher on the scrambled text will then restore the original text.

The ROT47 substitution cipher is a very simple form of encryption that works simply by
rotating the ASCII characters from '!" to '~' by 47 positions (hence its name). Therefore,
spaces in the plain text remain unchanged, but other characters are replaced with their
rotated equivalents.

For example, a 'B' (ASCII 66) becomes a 'q' (ASCII 113) because 66 + 47 = 113. When the
sum exceeds ASCII 126 ('~'), it simply wraps around starting at ASCII 33 ('!').

Because there are 94 characters between '!' and '~' in the ASCII table, rotating them
twice by 47 places has no net effect. Therefore, encryption and decryption are identical
operations with ROT47.

For more information about ROT47, see L<http://en.wikipedia.org/wiki/ROT13>.

=head1 CONSTRUCTOR

=head2 new

  use Crypt::Rot47;
  my $cipher = new Crypt::Rot47();

Returns a newly created C<Crypt::Rot47> object.

=head1 METHODS

=head2 encrypt ( $plain_text )

  my $cipherText = $cipher->encrypt('Hello, world!');

Returns the ciphertext of the provided plaintext. 

=head2 decrypt ( $cipher_text )

  my $plainText  = $cipher->decrypt($cipherText);

Returns the plaintext of the provided ciphertext. Note that because
encrypting and decrypting using ROT47 are exactly the same operation,
you could technically just call C<encrypt()> to decrypt the ciphertext,
but I provided both methods to be consistent with the API of other
Crypt:: modules.

=head1 EXPORTABLE SUBROUTINES

=head2 rot47 ( $plain_text | $cipher_text )

  use Crypt::Rot47 qw(rot47);

  my $cipherText = rot47('Hello, world!'); 
  my $plainText = rot47($cipherText);

Encrypts or decrypts the provided text. For ROT47, encryption and decryption
are the same operation, so calling C<rot47()> on text twice has no effect.

=head1 SEE ALSO

C<Crypt::Rot13>, C<Crypt::Blowfish>, C<Crypt::IDEA>

=head1 AUTHOR

Zachary Blair, E<lt>zblair@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2012 by Zachary Blair

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.8 or,
at your option, any later version of Perl 5 you may have available.

=cut
