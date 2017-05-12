package Crypt::CAST5;

require 5.004;
use strict;
use DynaLoader;

use vars qw( $VERSION @ISA );

$VERSION = "0.05";
@ISA = qw( DynaLoader );

bootstrap Crypt::CAST5 $VERSION;

1 # end Crypt::CAST5
__END__

=head1 NAME

Crypt::CAST5 - CAST5 block cipher

=head1 SYNOPSIS

    use Crypt::CBC;

    my $crypt = Crypt::CBC->new({
        key    => "secret key",
        cipher => "CAST5",
    });

    my $message = "All mimsy were the borogoves";
    my $ciphertext = $crypt->encrypt($message);
    print unpack("H*", $ciphertext), "\n";

    my $plaintext = $crypt->decrypt($ciphertext);
    print $plaintext, "\n";

=head1 DESCRIPTION

This module provides an implementation of the CAST5 block cipher using
compiled C code for increased speed. CAST5 is also known as CAST-128. It
is a product of the CAST design procedure developed by C. Adams and
S. Tavares.

The CAST5 cipher is available royalty-free.

=head1 FUNCTIONS

=head2 blocksize

Returns the CAST5 block size, which is 8 bytes. This function exists
so that Crypt::CAST5 can work with Crypt::CBC.

=head2 keysize

Returns the maximum CAST5 key size, 16 bytes.

=head2 new

    $cast5 = Crypt::CAST5->new($key);

Create a new encryption object. If the optional key parameter is given,
it will be passed to the init() function.

=head2 init

    $cast5->init($key);

Set or change the encryption key to be used. The key must be from 40 bits
(5 bytes) to 128 bits (16 bytes) in length. Note that if the key used is
80 bits or less, encryption and decryption will be somewhat faster.

It is best for the key to be random binary data, not something printable
like a password. A message digest function may be useful for converting
a password to an encryption key; see L<Digest::SHA1> or L<Digest::MD5>.
Note that Crypt::CBC runs the given "key" through MD5 to get the actual
encryption key.

=head2 encrypt

    $ciphertext = $cast5->encrypt($plaintext);

Encrypt a block of plaintext using the current encryption key, and return
the corresponding ciphertext. The input must be 8 bytes long, and the output
has the same length. Note that the encryption is in ECB mode, which means
that it encrypts each block independently. That can leave you vulnerable
to dictionary attacks, so it is generally best to use some form of chaining
between blocks; see L<Crypt::CBC>.

=head2 decrypt

    $plaintext = $cast5->decrypt($ciphertext);

Decrypt the ciphertext and return the corresponding plaintext.

=head1 SEE ALSO

RFC 2144, "The CAST-128 Encryption Algorithm", C. Adams, May 1997

L<Crypt::CBC>

=head1 AUTHOR

Bob Mathews, E<lt>bobmathews@alumni.calpoly.eduE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2002-2006 Bob Mathews

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

