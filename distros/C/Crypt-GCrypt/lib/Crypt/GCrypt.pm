# ===========================================================================
# Crypt::GCrypt
# 
# Perl interface to the GNU Cryptographic library
# 
# Author: Alessandro Ranellucci <aar@cpan.org>
# Copyright (c) 2005-06.
# 
# Use this software AT YOUR OWN RISK.
# See below for documentation.
# 

package Crypt::GCrypt;

use strict;
use warnings;

our $VERSION = '1.26';

require XSLoader;
XSLoader::load('Crypt::GCrypt', $VERSION);

sub CLONE_SKIP { 1 }

1;
__END__

=head1 NAME

Crypt::GCrypt - Perl interface to the GNU Cryptographic library

=head1 SYNOPSIS

  use Crypt::GCrypt;
  
  my $cipher = Crypt::GCrypt->new(
    type => 'cipher',
    algorithm => 'aes', 
    mode => 'cbc'
  );
  $cipher->start('encrypting');
  
  $cipher->setkey('my secret key');
  $cipher->setiv('my init vector');

  my $ciphertext  = $cipher->encrypt('plaintext');
  $ciphertext .= $cipher->finish;

  my $plaintext  = $cipher->decrypt($ciphertext);
  $plaintext .= $cipher->finish;

=head1 ABSTRACT

Crypt::GCrypt provides an object interface to the C libgcrypt library. It
currently supports symmetric encryption/decryption and message digests, 
while asymmetric cryptography is being worked on.

=head1 BINDING INFO

=head2 gcrypt_version()

Returns a string indicating the running version of gcrypt.

=head2 built_against_version()

Returns a string indicating the version of gcrypt that this module was
built against.  This is likely only to be useful in a debugging
situation.

=head1 SYMMETRIC CRYPTOGRAPHY

=head2 cipher_algo_available()

Determines whether a given cipher algorithm is available in the local
gcrypt installation:

  if (Crypt::GCrypt::cipher_algo_available('aes')) {
    # do stuff with aes
  }

=head2 new()

In order to encrypt/decrypt your data using a symmetric cipher you first have
to build a Crypt::GCrypt object:

  my $cipher = Crypt::GCrypt->new(
    type => 'cipher',
    algorithm => 'aes', 
    mode => 'cbc'
  );

The I<type> argument must be "cipher" and I<algorithm> is required too. See below
for a description of available algorithms and other initialization parameters:

=over 4

=item algorithm

This may be one of the following:

=over 8

=item B<3des> 

Triple-DES with 3 Keys as EDE.  The key size of this algorithm is
168 but you have to pass 192 bits because the most significant
bits of each byte are ignored.

=item B<aes> 

AES (Rijndael) with a 128 bit key.

=item B<aes192> 

AES (Rijndael) with a 192 bit key.

=item B<aes256> 

AES (Rijndael) with a 256 bit key.

=item B<blowfish>

The blowfish algorithm. The current implementation allows only for 
a key size of 128 bits (and thus is not compatible with Crypt::Blowfish).

=item B<cast5>

CAST128-5 block cipher algorithm.  The key size is 128 bits.

=item B<des> 

Standard DES with a 56 bit key. You need to pass 64 bit but the
high bits of each byte are ignored.  Note, that this is a weak
algorithm which can be broken in reasonable time using a brute
force approach.

=item B<twofish> 

The Twofish algorithm with a 256 bit key.

=item B<twofish128> 

The Twofish algorithm with a 128 bit key.

=item B<arcfour> 

An algorithm which is 100% compatible with RSA Inc.'s RC4
algorithm.  Note that this is a stream cipher and must be used
very carefully to avoid a couple of weaknesses.

=back

=item mode

This is a string specifying one of the following
encryption/decryption modes:

=over 8

=item B<stream> 

only available for stream ciphers

=item B<ecb> 

doesn't use an IV, encrypts each block independently

=item B<cbc> 

the current ciphertext block is encryption of current plaintext block 
xor-ed with last ciphertext block

=item B<cfb> 

the current ciphertext block is the current plaintext
block xor-ed with the current keystream block, which is the encryption
of the last ciphertext block

=item B<ofb> 

the current ciphertext block is the current plaintext
block xor-ed with the current keystream block, which is the encryption
of the last keystream block

=back

If no mode is specified then B<cbc> is selected for block ciphers, and
B<stream> for stream ciphers.

=item padding

When the last block of plaintext is shorter than the block size, it must be 
padded before encryption. Padding should permit a safe unpadding after 
decryption. Crypt::GCrypt currently supports two methods:

=over 8

=item B<standard>

This is also known as PKCS#5 padding, as it's binary safe. The string is padded
with the number of bytes that should be truncated. It's compatible with Crypt::CBC.

=item B<null>

Only for text strings. The block will be padded with null bytes (00). If the last 
block is a full block and blocksize is 8, a block of "0000000000000000" will be 
appended.

=item B<none>

By setting the padding method to "none", Crypt::GCrypt will only accept a multiple
of blklen as input for L</"encrypt()">.

=back

=item secure

If this option is set to a true value, all data associated with this cipher will be 
put into non-swappable storage, if possible.

=item enable_sync

Enable the CFB sync operation.

=back

Once you've got your cipher object the following methods are available:

=head2 start()

   $cipher->start('encrypting');
   $cipher->start('decrypting');

This method must be called before any call to setkey() or setiv(). It prepares
the cipher for encryption or decryption, resetting the internal state.

=head2 setkey()

   $cipher->setkey('my secret key');

Encryption and decryption operations will use this key until a different
one is set. If your key is shorter than the cipher's keylen (see the
C<keylen> method) it will be zero-padded, if it is longer it will be
truncated.

=head2 setiv()

   $cipher->setiv('my iv');

Set the initialisation vector for the next encrypt/decrypt operation.
If I<IV> is missing a "standard" IV of all zero is used. The same IV is set in
newly created cipher objects.

=head2 encrypt()

   $ciphertext = $cipher->encrypt($plaintext);

This method encrypts I<$plaintext> with I<$cipher>, returning the
corresponding ciphertext. The output is buffered; this means that
you'll only get multiples of $cipher's block size and that at the 
end you'll have to call L</"finish()">.

=head2 finish()

    $ciphertext .= $cipher->finish;
    
    $plaintext .= $cipher->finish;

The CBC algorithm must buffer data blocks internally until there are even 
multiples of the encryption algorithm's blocksize (typically 8 or 16 bytes).
After the last call to encrypt() or decrypt() you should call finish() to flush 
the internal buffer and return any leftover data. This method will also take care
of padding/unpadding of data (see the L</padding> option above).

=head2 decrypt()

   $plaintext = $cipher->decrypt($ciphertext);

The counterpart to encrypt, decrypt takes a I<$ciphertext> and produces the
original plaintext (given that the right key was used, of course).
The output is buffered; this means that you'll only get multiples of $cipher's 
block size and that at the end you'll have to call L</"finish()">.

=head2 keylen()

   print "Key length is " . $cipher->keylen();

Returns the number of bytes of keying material this cipher needs.

=head2 blklen()

   print "Block size is " . $cipher->blklen();

As their name implies, block ciphers operate on blocks of data. This
method returns the size of this blocks in bytes for this particular
cipher. For stream ciphers C<1> is returned, since this implementation
does not feed less than a byte into the cipher.

=head2 sync()

   $cipher->sync();

Apply the CFB sync operation.

=head1 MESSAGE DIGESTS

=head2 digest_algo_available()

Determines whether a given digest algorithm is available in the local
gcrypt installation:

   if (Crypt::GCrypt::digest_algo_available('sha256')) {
      # do stuff with sha256
   }

=head2 new()

In order to create a message digest, you first have to build a
Crypt::GCrypt object:

  my $digest = Crypt::GCrypt->new(
    type => 'digest',
    algorithm => 'sha256',
  );

The I<type> argument must be "digest" and I<algorithm> is required too. See below
for a description of available algorithms and other initialization parameters:

=over 4

=item algorithm

Depending on your available version of gcrypt, this can be one of the
following hash algorithms.  Note that some gcrypt installations do not
implement certain algorithms (see digest_algo_available()).

=over 8

=item B<md4>

=item B<md5>

=item B<ripemd160>

=item B<sha1>

=item B<sha224>

=item B<sha256>

=item B<sha384>

=item B<sha512>

=item B<tiger192>

=item B<whirlpool>

=back

=item secure

If this option is set to a true value, all data associated with this 
digest will be put into non-swappable storage, if possible.

=item hmac

If the digest is expected to be used as a keyed-Hash Message
Authentication Code (HMAC), supply the key with this argument.  It is
good practice to ensure that the key is at least as long as the digest
used.

=back

Once you've got your digest object the following methods are available:

=head2 digest_length()

    my $len = $digest->digest_length();

Returns the length in bytes of the digest produced by this algorithm.

=head2 write()

    $digest->write($data);

Feeds data into the hash context.  Once you have called read(), this 
method can't be called anymore.

=head2 reset()

Re-initializes the digest with the same parameters it was initially
created with.  This allows write()ing again, after a call to read().

=head2 clone()

Creates a new digest object with the exact same internal state.  This
is useful if you want to retrieve intermediate digests (i.e.  read()
from the copy and continue write()ing to the original).

=head2 read()

    my $md = $digest->read();

Completes the digest and return the resultant string.  You can call this
multiple times, and it will return the same information.  Once a
digest object has been read(), it may not be written to.

=head1 THREAD SAFETY

libgcrypt is initialized with support for Pthread, so this module should be 
thread safe.

=head1 SEE ALSO

Crypt::GCrypt::MPI supports Multi-precision integers (bignum math)
using libgcrypt as the backend implementation.

=head1 BUGS AND FEEDBACK

There are no known bugs. You are very welcome to write mail to the author 
(aar@cpan.org) with your contributions, comments, suggestions, bug reports 
or complaints.

=head1 AUTHORS AND CONTRIBUTORS

Alessandro Ranellucci E<lt>aar@cpan.orgE<gt>

Daniel Kahn Gillmor (message digests) E<lt>dkg@fifthhorseman.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (c) Alessandro Ranellucci.
Crypt::GCrypt is free software, you may redistribute it and/or modify it under 
the same terms as Perl itself.

=head1 ACKNOWLEDGEMENTS

This module was initially inspired by the GCrypt.pm bindings made by 
Robert Bihlmeyer in 2002. Thanks to users who give feedback and submit 
patches (see Changelog).

=head1 DISCLAIMER

This software is provided by the copyright holders and contributors ``as
is'' and any express or implied warranties, including, but not limited to,
the implied warranties of merchantability and fitness for a particular
purpose are disclaimed. In no event shall the regents or contributors be
liable for any direct, indirect, incidental, special, exemplary, or
consequential damages (including, but not limited to, procurement of
substitute goods or services; loss of use, data, or profits; or business
interruption) however caused and on any theory of liability, whether in
contract, strict liability, or tort (including negligence or otherwise)
arising in any way out of the use of this software, even if advised of the
possibility of such damage.

=cut

