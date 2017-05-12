=head1 NAME

Crypt::Eksblowfish - the Eksblowfish block cipher

=head1 SYNOPSIS

	use Crypt::Eksblowfish;

	$block_size = Crypt::Eksblowfish->blocksize;

	$cipher = Crypt::Eksblowfish->new(8, $salt, $key);

	$block_size = $cipher->blocksize;
	$ciphertext = $cipher->encrypt($plaintext);
	$plaintext = $cipher->decrypt($ciphertext);

	$p_array = $cipher->p_array;
	$s_boxes = $cipher->s_boxes;
	if($cipher->is_weak) { ...

=head1 DESCRIPTION

An object of this type encapsulates a keyed instance of the Eksblowfish
block cipher, ready to encrypt and decrypt.

Eksblowfish is a variant of the Blowfish cipher, modified to make
the key setup very expensive.  ("Eks" stands for "expensive key
schedule".)  This doesn't make it significantly cryptographically
stronger, but is intended to hinder brute-force attacks.  It also
makes it unsuitable for any application requiring key agility.  It was
designed by Niels Provos and David Mazieres for password hashing in
OpenBSD.  See L<Crypt::Eksblowfish::Bcrypt> for the hash algorithm.
See L<Crypt::Eksblowfish::Blowfish> for the unmodified Blowfish cipher.

Eksblowfish is a parameterised (family-keyed) cipher.  It takes a cost
parameter that controls how expensive the key scheduling is.  It also
takes a family key, known as the "salt".  Cost and salt parameters
together define a cipher family.  Within each family, a key determines an
encryption function in the usual way.  See L<Crypt::Eksblowfish::Family>
for a way to encapsulate an Eksblowfish cipher family.

=cut

package Crypt::Eksblowfish;

{ use 5.006; }
use warnings;
use strict;

our $VERSION = "0.009";

use parent "Crypt::Eksblowfish::Subkeyed";

die "mismatched versions of Crypt::Eksblowfish modules"
	unless $Crypt::Eksblowfish::Subkeyed::VERSION eq $VERSION;

=head1 CLASS METHODS

=over

=item Crypt::Eksblowfish->blocksize

Returns 8, indicating the Eksblowfish block size of 8 octets.  This method
may be called on either the class or an instance.

=back

=head1 CONSTRUCTOR

=over

=item Crypt::Eksblowfish->new(COST, SALT, KEY)

Performs key setup on a new instance of the Eksblowfish algorithm,
returning the keyed state.  The KEY may be any length from 1 octet to
72 octets inclusive.  The SALT is a family key, and must be exactly
16 octets.  COST is an integer parameter controlling the expense of
keying: the number of operations in key setup is proportional to 2^COST.
All three parameters influence all the subkeys; changing any of them
produces a different encryption function.

Due to the mandatory family-keying parameters (COST and SALT), this
constructor does not match the interface expected by C<Crypt::CBC>
and similar crypto plumbing modules.  To
use Eksblowfish with them it is necessary to have an object that
encapsulates a cipher family and provides a constructor that takes only a
key argument.  That facility is supplied by C<Crypt::Eksblowfish::Family>.

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

L<Crypt::Eksblowfish::Bcrypt>,
L<Crypt::Eksblowfish::Blowfish>,
L<Crypt::Eksblowfish::Family>,
L<Crypt::Eksblowfish::Subkeyed>,
L<http://www.usenix.org/events/usenix99/provos/provos_html/node4.html>

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
