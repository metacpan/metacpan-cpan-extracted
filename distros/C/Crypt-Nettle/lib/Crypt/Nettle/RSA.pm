# ===========================================================================
# Crypt::Nettle:RSA
#
# Perl interface to RSA public key cryptography from libnettle
#
# Author: Daniel Kahn Gillmor E<lt>dkg@fifthhorseman.netE<gt>,
# Copyright © 2011.
#
# Use this software AT YOUR OWN RISK.
# See below for documentation.
#

package Crypt::Nettle::RSA;

use strict;
use warnings;
use Crypt::Nettle;
use Crypt::Nettle::Hash;


# rsa_sign and rsa_verify wrap the internal (XS-implemented,
# publicly-undocumented) rsa_sign_hash() and rsa_verify_hash()
# subroutines:

sub rsa_sign {
  my $self = shift;
  my $digest_algo = shift;
  my $data = shift;

  my $hash = Crypt::Nettle::Hash->new($digest_algo);
  $hash->update($data);
  my $signature = $self->rsa_sign_hash_context($hash);
  return $signature;
};

sub rsa_verify {
  my $self = shift;
  my $digest_algo = shift;
  my $data = shift;
  my $signature = shift;

  my $hash = Crypt::Nettle::Hash->new($digest_algo);
  $hash->update($data);
  return $self->rsa_verify_hash_context($hash, $signature);
};


1;
__END__

=head1 NAME

Crypt::Nettle::RSA - Perl interface to RSA public key cryptography from libnettle

=head1 SYNOPSIS

  use Crypt::Nettle::RSA;

  $n = '0x32deadbeef'... # imagine a long number here :P

  my $pubkey = Crypt::Nettle::RSA->new_public_key($n, '0x10001');


=head1 ABSTRACT

Crypt::Nettle::RSA provides an object interface to RSA public key
cryptography implemented in the nettle C library (using libhogweed).

Allowed RSA signature digest algorithms are: md5, sha1, sha256, and
sha512.

=head2 hashes_available()

Get a list of strings that refer to the digest functions this perl
module can use for creating and verifying RSA signatures.

 my @algos = Crypt::Nettle::RSA::hashes_available();

=head1 KEY CREATION

=head2 new_public_key($n, $e)

Create a new public key from the modulus and the exponent of the
public key. (see DATA REPRESENTATIONS below for how to format $n and
$e)

=head2 new_private_key($d, $p, $q)

Create a new private key from the private exponent and the two prime
factors. (see DATA REPRESENTATIONS below for how to format $d, $p and
$q)

=head2 generate_keypair($yarrow, $bits, $e = 65537)

Create a new private key of size $bits from a well-seeded random
number generator (see Crypt::Nettle::Yarrow).  You can select the
exponent manually via $e, though the default is probably fine.


=head1 KEY USE

=head2 rsa_sign($digest_algo, $data)

Return a packed binary string that is the key's signature over $data.

 my $sig = $private_key->rsa_sign('sha1', 'This is a test message');
 printf('Signature: 0x%s\n', unpack('H*', $sig));

Returns undefined if there was an error.

=head2 rsa_verify($digest_algo, $data, $signature)

Returns 1 if this public key was the author of $signature over $data.

Returns 0 if the signature did not check out.

Return undefined if there was an error.

 my $ret = $private_key->rsa_verify('sha1', 'This is a test message', $sig);
 printf('Signature: %s\n', (defined($ret) ? ($ret ? 'OK' : 'BAD') : 'ERROR'));

=head2 rsa_sign_hash_context($hash_ctx)

=head2 rsa_verify_hash_context($hash_ctx, $signature)

These functions let you pass a Crypt::Nettle::Digest object for RSA
signature/verification instead of needing to keep the entire $data in
memory.  Here's signing:

 my $hash = Crypt::Nettle::Hash->new('sha1');
 $hash->update($data);
 # ... more update()s ...
 my $sig = $private_key->rsa_sign_hash_context($hash);

And verifying:

 my $hash = Crypt::Nettle::Hash->new('sha1');
 $hash->update($data);
 # ... more update()s ...
 my $ok = $public_key->rsa_verify_hash_context($hash, $sig);

Note that the $hash_ctx will be re-initialized after calling either of
these functions.  If you don't want that to happen, consider passing
$hash->copy() instead of $hash.

=head2 rsa_sign_hash_context($hash_ctx)

=head2 rsa_verify_hash_context($hash_ctx, $signature)

These functions let you pass a raw digest for RSA
signature/verification instead of needing to keep the entire $data in
memory.  Here's signing:

 my $hash = Crypt::Nettle::Hash->new('sha1');
 $hash->update($data);
 # ... more update()s ...
 my $digest = $hash->digest();
 my $sig = $private_key->rsa_sign_digest('sha1', $digest);

And verifying:

 my $hash = Crypt::Nettle::Hash->new('sha1');
 $hash->update($data);
 # ... more update()s ...
 my $digest = $hash->digest();
 my $ok = $public_key->rsa_verify_hash_context($digest, $sig);

=head2 WARNING ABOUT CRYPTOGRAPHIC BLINDING

Note that rsa private key operations in the current implementation of
Nettle (2.1) are not currently blinded.  This means that if you use
this in an online service that an attacker can force signatures or
decryptions while observing timing, it's possible that the attacker
can derive information about your key.

For more info, see:
https://secure.wikimedia.org/wikipedia/en/wiki/RSA#Timing_attacks


=head1 KEY INFORMATION

=head2 key_params()

Return a hashref of the parameters of this object.  Public keys will
return a hashref with keys 'n' and 'e'.  Private keys will return a
hashref with keys 'p' and 'q'.

=head1 DATA REPRESENTATIONS

=head2 key parameters

When values are passed during key creation, they should be either in
integer or string form (not packed binary).  When passing a string, we
use GMP's mpz_set_str() to convert it into an internal number.  If the
string starts with '0x', it will be interpreted as hex.  Otherwise, if
it starts with '0', it will be interpreted as octal.  Otherwise, it
will be interpreted as decimal.

When any key parameters are returned to the user via key_params(),
they are returned in hexadecimal ASCII string representation with a
leading '0x'.

=head2 other data

Data, raw digests, and signatures sent to sign, verify, encrypt, or
decrypt functions should be sent as packed binary scalars.

Data returned from signature functions will be in packed binary form
as well.

=head1 BUGS AND FEEDBACK

Would be nice to implement progress feedback during key generation.

Functions are all named for the signature side of things. i think they
can be used for encryption as well, though that introduces padding
issues.

The test suite is currently only testing against itself, rather than
using external test vectors.

Produce various string representations (ASN1, OpenPGP, S-EXP etc) of
the keys?

Read keys from various string representations (ASN1, OpenPGP, S-EXP,
etc)?

Crypt::Nettle::RSA causes perl to load libhogweed and libgmp, while
the other Crypt::Nettle modules don't.  It'd be nice to make this
extra load contingent only on the use of Crypt::Nettle::RSA, so that
(for example) users who just want Crypt::Nettle::Cipher don't pay the
extra cost.

Crypt::Nettle::RSA has no other known bugs, mostly because no one
has found them yet.  Please write mail to the maintainer
(dkg@fifthhorseman.net) with your contributions, comments,
suggestions, bug reports or complaints.

=head1 AUTHORS AND CONTRIBUTORS

Daniel Kahn Gillmor E<lt>dkg@fifthhorseman.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright © Daniel Kahn Gillmor

Crypt::Nettle::RSA is free software, you may redistribute it and/or
modify it under the GPL version 2 or later (your choice).  Please see
the COPYING file for the full text of the GPL.

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
