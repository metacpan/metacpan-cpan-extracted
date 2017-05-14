# ===========================================================================
# Crypt::Nettle:Cipher
#
# Perl interface to symmetric encryption and decryption from libnettle
#
# Author: Daniel Kahn Gillmor E<lt>dkg@fifthhorseman.netE<gt>,
# Copyright © 2011.
#
# Use this software AT YOUR OWN RISK.
# See below for documentation.
#

package Crypt::Nettle::Cipher;

use strict;
use warnings;

use Crypt::Nettle;

1;
__END__

=head1 NAME

Crypt::Nettle::Cipher - Perl interface to symmetric encryption and decryption from libnettle

=head1 SYNOPSIS

  use Crypt::Nettle::Cipher;

  my $cleartext = '01234567';
  my $cipher = Crypt::Nettle::Cipher->new('encrypt', 'aes128', '02ds3m#soE2d^7dw', 'ecb');
  $ciphertext = $cipher->process($cleartext);
  printf("encrypted: %s\n", unpack('H*', $ciphertext));

=head1 ABSTRACT

Crypt::Nettle::Cipher provides an object interface to symmetric
encryption and decryption from the nettle C library.  Each
Crypt::Nettle::Cipher object is initialized to do either encryption or
decryption.  If you need both encryption and decryption, make a
separate object for each direction.

=head1 BASIC OPERATIONS

=head2 algos_available()

Get a list of strings that refer to the ciphers this perl module knows
how to coax out of libnettle:

 my @algos = Crypt::Nettle::Cipher::algos_available();

=head2 modes_available()

Get a list of strings that refer to the cipher block modes this perl
module knows how to coax out of libnettle:

 my @modes = Crypt::Nettle::Cipher::modes_available();


=head1 ENCRYPTION CONTEXT CREATION

=head2 new($is_encrypt, $algo, $key, $mode, $iv)

Create a new context for encryption:

  my $encrypt = Crypt::Nettle::Cipher->new('encrypt', 'aes128', '02ds3m#soE2d^7dw', 'ecb');

The parameter $algo must be the name of a symmetric encryption
algorithm supported by libnettle.

Note that $key must match the key_size() for the selected algorithm.

If $is_encrypt is 'decrypt' or 0, the new object will do decryption;
If $is_encrypt is 'encrypt' or 1, it will encrypt.

You can set the $mode of the cipher with 'ecb' (Electronic Code Book),
'cbc' (Cipher Block Chaining), or 'ctr' (Counter).  ECB is the default
because it is simpler to configure, but you probably want CBC or CTR
for security.

If you use CBC or CTR, you'll need to supply an initialization vector
(CBC) or initialization counter (CTR) in the $iv parameter.  $iv
should be the size of block_size().

On error, will return undefined.

Supported encryption algorithms are: aes128, aes192, aes256, arctwo40,
arctwo64, arctwo128, arctwo_gutmann128, arcfour128, camellia128,
camellia192, camellia256, cast128, serpent128, serpent192, serpent256,
twofish128, twofish192, twofish256.

(you can retrieve these programmatically with algos_available()).

Every algorithm supports ECB, but some algorithms don't support some
of the other modes.  I recommend sticking to AES if you can.

=head2 copy()

Copy an existing Crypt::Nettle::Cipher object, including its internal
state:

  my $new_cipher = $cipher->copy();

On error, will return undefined.

=head1 ENCRYPTION CONTEXT OPERATION

=head2 process($data)

Encrypt or decrypt $data with the cipher object:

  $cleartext = 'this is a secret';
  my $encrypt = Crypt::Nettle::Cipher->new('encrypt', 'aes128', '02ds3m#soE2d^7dw');
  $ciphertext = $encrypt->process($cleartext);

or:

  $ciphertext = 'adfasdfasdfasdf';
  my $encrypt = Crypt::Nettle::Cipher->new('decrypt', 'aes128', '02ds3m#soE2d^7dw');
  $cleartext = $encrypt->process($ciphertext);

Note that the length of $data must be an even multiple of
$cipher->block_size().

=head2 process_in_place($data)

Process $data with the cipher object, overwriting $data with the result:

  $text = 'this is a secret';
  $encrypt->process_in_place($text);

Note that the length of $data must be an even multiple of
$cipher->block_size().

=head1 ENCRYPTION DETAILS

=head2 is_encrypt()

Returns non-zero if the object is an encryption cipher, or zero if the
object is set up for decryption.

  printf("Direction: %s\n", ($cipher->is_encrypt() ? 'encrypt' : 'decrypt'));

=head2 name()

Return the name of the encryption/decryption algorithm:

  printf("Symmetric Encryption Algorithm: %s\n", $cipher->name());

=head2 mode()

Returns a string representing the cipher block mode.

  printf("Cipher Block Mode: %s\n", $cipher->mode());

=head2 key_size()

Return the size (in bytes) of the key for a given algorithm.  This can
be called either on an encryption context, or just by passing the name
of an algorithm to the module directly:

  printf("Key size: %d\n", $cipher->key_size());

or

  printf("Key size: %d\n", Crypt::Nettle::Cipher->key_size('aes128'));

=head2 block_size()

Return the block size (in bytes) of this encryption algorithm.  This
can be called either on an encryption context, or just by passing the
name of an algorithm to the module directly:

  printf("Block size: %d\n", $cipher->block_size());

or

  printf("Block size: %d\n", Crypt::Nettle::Cipher->block_size('aes128'));

=head1 BUGS AND FEEDBACK

For algorithms with known weak keys (e.g. DES, ARCFOUR, and BLOWFISH)
Crypt::Nettle::Cipher does not currently check for initialization with
a weak key.  It is recommended to use an algorithm like AES, which has
no known weak keys at the time of this writing (March 2011).

It would be nice to buffer input for process() so that
the user does not have to manage buffer sizes outside of
Crypt::Nettle.

At the moment, $key and $iv probably need to be exactly the right size
(key_size() and block_size(), respectively).  Should we try to pad
with zeros if the user passes the wrong size data?

It would be nice to be able to use a shorthand like 'aes' and have the
module select the correct flavor of aes based on the length of the key
argument.

Crypt::Nettle::Cipher has no other known bugs, mostly because no one
has found them yet.  Please write mail to the maintainer
(dkg@fifthhorseman.net) with your contributions, comments,
suggestions, bug reports or complaints.

=head1 AUTHORS AND CONTRIBUTORS

Daniel Kahn Gillmor E<lt>dkg@fifthhorseman.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright © Daniel Kahn Gillmor

Crypt::Nettle is free software, you may redistribute it and/or modify
it under the GPL version 2 or later (your choice).  Please see the
COPYING file for the full text of the GPL.

=head1 ACKNOWLEDGEMENTS

This module was initially inspired by the GCrypt.pm bindings made by
Alessandro Ranellucci.

=head1 DISCLAIMER

This software is provided by the copyright holders and contributors
"as is" and any express or implied warranties, including, but not
limited to, the implied warranties of merchantability and fitness for
a particular purpose are disclaimed. In no event shall the
contributors be liable for any direct, indirect, incidental, special,
exemplary, or consequential damages (including, but not limited to,
procurement of substitute goods or services; loss of use, data, or
profits; or business interruption) however caused and on any theory of
liability, whether in contract, strict liability, or tort (including
negligence or otherwise) arising in any way out of the use of this
software, even if advised of the possibility of such damage.

=cut
