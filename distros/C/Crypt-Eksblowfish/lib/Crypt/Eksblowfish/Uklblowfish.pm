=head1 NAME

Crypt::Eksblowfish::Uklblowfish - Blowfish cipher with unrestricted key length

=head1 SYNOPSIS

	use Crypt::Eksblowfish::Uklblowfish;

	$block_size = Crypt::Eksblowfish::Uklblowfish->blocksize;
	$key_size = Crypt::Eksblowfish::Uklblowfish->keysize;

	$cipher = Crypt::Eksblowfish::Uklblowfish->new($key);

	$block_size = $cipher->blocksize;
	$ciphertext = $cipher->encrypt($plaintext);
	$plaintext = $cipher->decrypt($ciphertext);

	$p_array = $cipher->p_array;
	$s_boxes = $cipher->s_boxes;
	if($cipher->is_weak) { ...

=head1 DESCRIPTION

An object of this type encapsulates a keyed instance of the Blowfish
block cipher, ready to encrypt and decrypt.  However, if you're
looking for an implementation of Blowfish you most likely want
L<Crypt::Eksblowfish::Blowfish>.  This class differs from the standard
Blowfish in that it accepts some keys that Blowfish officially does
not permit.

Blowfish is a symmetric cipher algorithm designed by Bruce Schneier in
1993.  It operates on 64-bit blocks, and takes a variable-length key.
Officially the key can vary from 32 bits (4 octets) to 448 bits (56
octets) in increments of 8 bits (1 octet).  In fact the algorithm can
easily operate on a key of any number of octets from 1 (8 bits) to 72
(576 bits).  Some implementations don't enforce the official key length
limits, and so for compatibility it is sometimes necessary to handle a
Blowfish key of a prohibited length.  That is what this class is for.
The "Ukl" in the name stands for "unrestricted key length".

Using a very short key is generally a bad idea because there aren't
very many keys of that length and so it's easy for an attacker to try
them all.  The official 32-bit minimum for Blowfish was already far
too short for serious security at the time that Blowfish was designed.
(A machine to crack 56-bit DES keys by brute force in a few days each
was publicly built only five years later.)  Do not base your security
on the secrecy of a short key.

Using overlong keys has more interesting effects, which depend on internal
features of Blowfish.  When the key exceeds 64 octets (512 bits), varying
key bits past that length results in subkeys which have predictable
relationships.  There is also some possibility of equivalent keys when
the keys exceed 64 octets and differ only in the first 8 octets (64 bits).
These phenomena have not been extensively studied in the open literature,
so it is difficult to judge the degree of cryptographic weakness that
results from them.  It is clear that beyond some length Blowfish keys
do not have as much strength as their length would suggest, and it is
possible that overlong keys have specific weaknesses that render them
weaker than shorter keys.  If choosing a key for security, it is advised
to stay within the official length limit of 56 octets.

In summary: using Blowfish keys of officially-unsupported lengths
causes security problems.  If you are using Blowfish for security,
and have the choice, use a key of an officially-supported length (and
a standard implementation such as L<Crypt::Eksblowfish::Blowfish>).
Use out-of-range key lengths (and this class) only for compatibility or
cryptanalytic reasons.

=cut

package Crypt::Eksblowfish::Uklblowfish;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.009";

use parent "Crypt::Eksblowfish::Subkeyed";

die "mismatched versions of Crypt::Eksblowfish modules"
	unless $Crypt::Eksblowfish::Subkeyed::VERSION eq $VERSION;

=head1 CLASS METHODS

=over

=item Crypt::Eksblowfish::Uklblowfish->blocksize

Returns 8, indicating the Blowfish block size of 8 octets.  This method
may be called on either the class or an instance.

=item Crypt::Eksblowfish::Uklblowfish->keysize

Returns 0, indicating that the key size is variable.  This situation is
handled specially by C<Crypt::CBC>.

=back

=cut

sub keysize { 0 }

=head1 CONSTRUCTOR

=over

=item Crypt::Eksblowfish::Uklblowfish->new(KEY)

Performs key setup on a new instance of the Blowfish algorithm, returning
the keyed state.  The KEY may be any length from 1 octet to 72 octets
inclusive.

=back

=head1 METHODS

=over

=item $cipher->blocksize

Returns 8, indicating the Blowfish block size of 8 octets.  This method
may be called on either the class or an instance.

=item $cipher->encrypt(PLAINTEXT)

PLAINTEXT must be exactly eight octets.  The block is encrypted, and
the ciphertext is returned.

=item $cipher->decrypt(CIPHERTEXT)

CIPHERTEXT must be exactly eight octets.  The block is decrypted, and
the plaintext is returned.

=item $cipher->p_array

=item $cipher->s_boxes

These methods extract the subkeys from the keyed cipher.
This is not required in ordinary operation.  See the superclass
L<Crypt::Eksblowfish::Subkeyed> for details.

=item $cipher->is_weak

This method checks whether the cipher has been keyed with a weak key.
It may be desired to avoid using weak keys.  See the superclass
L<Crypt::Eksblowfish::Subkeyed> for details.

This method does not detect any cryptographic weaknesses that might result
from the related-key properties and other features of overlong keys.

=back

=head1 SEE ALSO

L<Crypt::Eksblowfish::Blowfish>

=head1 AUTHOR

Eksblowfish guts originally by Solar Designer (solar at openwall.com).

Modifications and Perl interface by Andrew Main (Zefram)
<zefram@fysh.org>.

=head1 COPYRIGHT

Copyright (C) 2006, 2007, 2008, 2009, 2010, 2011
Andrew Main (Zefram) <zefram@fysh.org>

The original Eksblowfish code (in the form of crypt()) from which
this module is derived is in the public domain.  It may be found at
L<http://www.openwall.com/crypt/>.

=head1 LICENSE

This module is free software; you can redistribute it and/or modify it
under the same terms as Perl itself.

=cut

1;
