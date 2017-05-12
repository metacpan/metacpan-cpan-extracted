=head1 NAME

Crypt::Eksblowfish::Subkeyed - Blowfish/Eksblowfish with access to subkeys

=head1 SYNOPSIS

	use Crypt::Eksblowfish::Subkeyed;

	$block_size = Crypt::Eksblowfish::Subkeyed->blocksize;

	$cipher = Crypt::Eksblowfish::Subkeyed
			->new_from_subkeys(\@p_array, \@s_boxes);
	$cipher = Crypt::Eksblowfish::Subkeyed->new_initial;

	$block_size = $cipher->blocksize;
	$ciphertext = $cipher->encrypt($plaintext);
	$plaintext = $cipher->decrypt($ciphertext);

	$p_array = $cipher->p_array;
	$s_boxes = $cipher->s_boxes;
	if($cipher->is_weak) { ...

=head1 DESCRIPTION

An object of this class encapsulates a keyed instance of the Blowfish
or Eksblowfish block cipher, ready to encrypt and decrypt.  Normally
this class will not be used directly, but through subclasses such as
L<Crypt::Eksblowfish>.

Eksblowfish is a variant of the Blowfish cipher with a modified key setup
algorithm.  This class doesn't implement either form of key setup, but
only provides the actual encryption and decryption parts of the ciphers.
This part is shared between Blowfish and Eksblowfish, and also any other
cipher that uses the core of Blowfish but supplies its own key setup.
This class has "Eksblowfish" in its name rather than "Blowfish" merely
due to the historical accident that it is derived from the encryption
engine that was used to implement Eksblowfish.

The key setup phase of a block cipher, also known as the "key
schedule", produces a set of "subkeys", which are somewhat like ordinary
cryptographic keys (which are the input to the key setup algorithm) but
are much larger.  In some block ciphers the subkeys also have special
interrelationships.  In Blowfish the subkeys consist of a "P-array" of 18
32-bit entries (one per encryption round plus two more) and four "S-boxes"
("S" is for "substitution") each of which consists of 256 32-bit entries.
There is no special relationship between the values of the subkeys.

Methods in this class allow a cipher object to be constructed from
a full set of subkeys, and for the subkeys to be extracted from a
cipher object.  Normal users don't need to do either of these things.
It's mainly useful when devising a new key schedule to stick onto the
Blowfish core, or when performing cryptanalysis of the cipher algorithm.

Generating subkeys directly by a strong random process, rather than by
expansion of a smaller random key, is an expensive and slightly bizarre
way to get greater cryptographic strength from a cipher algorithm.
It eliminates attacks on the key schedule, and yields the full strength
of the core algorithm.  However, this is always a lot less strength than
the amount of subkey material, whereas a normal key schedule is designed
to yield strength equal to the length of the (much shorter) key.  Also,
any non-randomness in the source of the subkey material is likely to
lead to a cryptographic weakness, whereas a key schedule conceals any
non-randomness in the choice of the key.

=cut

package Crypt::Eksblowfish::Subkeyed;

{ use 5.006; }
use warnings;
use strict;

use XSLoader;

our $VERSION = "0.009";

XSLoader::load("Crypt::Eksblowfish", $VERSION);

=head1 CLASS METHODS

=over

=item Crypt::Eksblowfish::Subkeyed->blocksize

Returns 8, indicating the Eksblowfish block size of 8 octets.  This method
may be called on either the class or an instance.

=back

=head1 CONSTRUCTOR

=over

=item Crypt::Eksblowfish::Subkeyed->new_from_subkeys(ROUND_KEYS, SBOXES)

Creates a new Blowfish cipher object encapsulating the supplied subkeys.
ROUND_KEYS must be a reference to an array of 18 32-bit integers.
SBOXES must be a reference to an array of four references to 256-element
arrays of 32-bit integers.  These subkeys are used in the standard order
for Blowfish.

=item Crypt::Eksblowfish::Subkeyed->new_initial

The standard Blowfish key schedule is an iterative process, which uses
the cipher algorithm to progressively replace subkeys, thus mutating the
cipher for subsequent iterations of keying.  The Eksblowfish key schedule
works similarly, but with a lot more iterations.  In both cases, the
key setup algorithm begins with a standard set of subkeys, consisting
of the initial bits of the fractional part of pi.  This constructor
creates and returns a Blowfish block cipher object with that standard
initial set of subkeys.  This is probably useful only to designers of
novel key schedules.

=back

=head1 METHODS

=over

=item $cipher->blocksize

Returns 8, indicating the Eksblowfish block size of 8 octets.  This method
may be called on either the class or an instance.

=item $cipher->encrypt(PLAINTEXT)

PLAINTEXT must be exactly eight octets.  The block is encrypted, and
the ciphertext is returned.

=item $cipher->decrypt(CIPHERTEXT)

CIPHERTEXT must be exactly eight octets.  The block is decrypted, and
the plaintext is returned.

=item $cipher->p_array

Returns a reference to an 18-element array containing the 32-bit round
keys used in this cipher object.

=item $cipher->s_boxes

Returns a reference to a 4-element array containing the S-boxes used in
this cipher object.  Each S-box is a 256-element array of 32-bit entries.

=item $cipher->is_weak

Returns a truth value indicating whether this is a weak key.  A key is
considered weak if any S-box contains a pair of identical entries
(in any positions).  When Blowfish is used with such an S-box, certain
cryptographic attacks are possible that are not possible against most
keys.  The current (as of 2007) cryptanalytic results on Blowfish do
not include an actual break of the algorithm when weak keys are used,
but if a break is ever developed then it is likely to be achieved for
weak keys before it is achieved for the general case.

About one key in every 2^15 is weak (if the keys are randomly selected).
Because of the complicated key schedule in standard Blowfish it is not
possible to predict which keys will be weak without first performing the
full key setup, which is why this is a method on the keyed cipher object.
In some uses of Blowfish it may be desired to avoid weak keys; if so,
check using this method and generate a new random key when a weak key
is detected.  Bruce Schneier, the designer of Blowfish, says it is
probably not worth avoiding weak keys.

=back

=head1 SEE ALSO

L<Crypt::Eksblowfish>,
L<Crypt::Eksblowfish::Blowfish>,
L<http://www.schneier.com/paper-blowfish-fse.html>

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
