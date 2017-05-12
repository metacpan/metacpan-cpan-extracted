=head1 NAME

Crypt::Eksblowfish::Blowfish - Blowfish block cipher via Eksblowfish engine

=head1 SYNOPSIS

	use Crypt::Eksblowfish::Blowfish;

	$block_size = Crypt::Eksblowfish::Blowfish->blocksize;
	$key_size = Crypt::Eksblowfish::Blowfish->keysize;

	$cipher = Crypt::Eksblowfish::Blowfish->new($key);

	$block_size = $cipher->blocksize;
	$ciphertext = $cipher->encrypt($plaintext);
	$plaintext = $cipher->decrypt($ciphertext);

	$p_array = $cipher->p_array;
	$s_boxes = $cipher->s_boxes;
	if($cipher->is_weak) { ...

=head1 DESCRIPTION

An object of this type encapsulates a keyed instance of the Blowfish
block cipher, ready to encrypt and decrypt.

Blowfish is a symmetric cipher algorithm designed by Bruce Schneier
in 1993.  It operates on 64-bit blocks, and takes a variable-length key
from 32 bits (4 octets) to 448 bits (56 octets) in increments of 8 bits
(1 octet).

This implementation of Blowfish uses an encryption engine that was
originally implemented in order to support Eksblowfish, which is a
variant of Blowfish modified to make keying particularly expensive.
See L<Crypt::Eksblowfish> for that variant; this class implements the
original Blowfish.

=cut

package Crypt::Eksblowfish::Blowfish;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.009";

use parent "Crypt::Eksblowfish::Subkeyed";

die "mismatched versions of Crypt::Eksblowfish modules"
	unless $Crypt::Eksblowfish::Subkeyed::VERSION eq $VERSION;

=head1 CLASS METHODS

=over

=item Crypt::Eksblowfish::Blowfish->blocksize

Returns 8, indicating the Blowfish block size of 8 octets.  This method
may be called on either the class or an instance.

=item Crypt::Eksblowfish::Blowfish->keysize

Returns 0, indicating that the key size is variable.  This situation is
handled specially by C<Crypt::CBC>.

=back

=cut

sub keysize { 0 }

=head1 CONSTRUCTOR

=over

=item Crypt::Eksblowfish::Blowfish->new(KEY)

Performs key setup on a new instance of the Blowfish algorithm, returning
the keyed state.  The KEY may be any length from 4 octets to 56 octets
inclusive.

You may occasionally come across an alleged Blowfish key that is outside
this length range, and so is rejected by this constructor.  Blowfish
can internally process a key of any octet length up to 72 octets, and
some implementations don't enforce the official length restrictions.
If it is necessary for compatibility, a key of out-of-range length can
be processed by L<Crypt::Eksblowfish::Uklblowfish>.

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

=back

=head1 SEE ALSO

L<Crypt::Eksblowfish>,
L<Crypt::Eksblowfish::Subkeyed>,
L<Crypt::Eksblowfish::Uklblowfish>,
L<http://www.schneier.com/blowfish.html>

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
