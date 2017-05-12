=head1 NAME

Crypt::Twofish2 - Crypt::CBC compliant Twofish encryption module

=head1 SYNOPSIS

 use Crypt::Twofish2;

 # keysize() is 32, but 24 and 16 are also possible
 # blocksize() is 16

 $cipher = new Crypt::Twofish2 "a" x 32, Crypt::Twofish2::MODE_CBC;

 $crypted = $cipher->encrypt($plaintext);
 # - OR -
 $plaintext = $cipher->decrypt($crypted);

=head1 DESCRIPTION

This module implements the twofish cipher in a less braindamaged (read:
slow and ugly) way than the existing C<Crypt::Twofish> module.

Although it is C<Crypt::CBC> compliant you usually gain nothing by using
that module (except generality, which is often a good thing), since
C<Crypt::Twofish2> can work in either ECB or CBC mode itself.

=over 4

=cut

package Crypt::Twofish2;

use XSLoader;

$VERSION = '1.02';

XSLoader::load __PACKAGE__, $VERSION;

=item keysize

Returns the keysize, which is 32 (bytes). The Twofish2 cipher actually
supports keylengths of 16, 24 or 32 bytes, but there is no way to
communicate this to C<Crypt::CBC>.

=item blocksize

The blocksize for Twofish2 is 16 bytes (128 bits), which is somewhat
unique. It is also the reason I need this module myself ;)

=item $cipher = new $key [, $mode]

Create a new C<Crypt::Twofish2> cipher object with the given key (which
must be 128, 192 or 256 bits long). The additional C<$mode> argument is
the encryption mode, either C<MODE_ECB> (electronic cookbook mode, the
default), C<MODE_CBC> (cipher block chaining, the same that C<Crypt::CBC>
does) or C<MODE_CFB1> (1-bit cipher feedback mode).

ECB mode is very insecure (read a book on cryptography if you don't know
why!), so you should probably use CBC mode. CFB1 mode is not tested and is
most probably broken, so do not try to use it.

In ECB mode you can use the same cipher object to encrypt and decrypt
data. However, every change of "direction" causes an internal reordering
of key data, which is quite slow, so if you want ECB mode and
encryption/decryption at the same time you should create two seperate
C<Crypt::Twofish2> objects with the same key.

In CBC mode you have to use seperate objects for encryption/decryption in
any case.

The C<MODE_*>-constants are not exported by this module, so you must
specify them as C<Crypt::Twofish2::MODE_CBC> etc. (sorry for that).

=item $cipher->encrypt($data)

Encrypt data. The size of C<$data> must be a multiple of C<blocksize> (16
bytes), otherwise this function will croak. Apart from that, it can be of
(almost) any length.

=item $cipher->decrypt($data)

The pendant to C<encrypt> in that it I<de>crypts data again.

=back

=head1 SEE ALSO

L<Crypt::CBC>, L<Crypt::Twofish>.

=head1 BUGS

Should EXPORT or EXPORT_OK the MODE constants.

There should be a way to access initial IV contents :(

Although I tried to make the original twofish code portable, I can't say
how much I did succeed. The code tries to be portable itself, and I hope
I got the endianness issues right. The code is also copyright Counterpane
Systems, no license accompanied it, so using it might actually be illegal
;)

I also cannot guarantee for security, but the module is used quite a bit,
so there are no obvious bugs left.

=head1 AUTHOR

 Marc Lehmann <schmorp@schmorp.de>
 http://home.schmorp.de/

 The actual twofish encryption is written in horribly microsoft'ish looking
 almost ansi-c by Doug Whiting.

=cut

1;

