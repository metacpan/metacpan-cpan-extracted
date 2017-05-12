# ===========================================================================
# Crypt::Nettle:Hash
#
# Perl interface to cryptographic digests from libnettle
#
# Author: Daniel Kahn Gillmor E<lt>dkg@fifthhorseman.netE<gt>,
# Copyright © 2011.
#
# Use this software AT YOUR OWN RISK.
# See below for documentation.
#

package Crypt::Nettle::Hash;

use strict;
use warnings;

use Crypt::Nettle;

sub hash_data {
  my $algo = shift;
  my $data = shift;
  my $digest = Crypt::Nettle::Hash->new($algo);
  $digest->update($data);
  return $digest->digest();
}

sub hmac_data {
  my $algo = shift;
  my $data = shift;
  my $key = shift;
  my $digest = Crypt::Nettle::Hash->new_hmac($algo, $key);
  $digest->update($data);
  return $digest->digest();
}

1;
__END__

=head1 NAME

Crypt::Nettle::Hash - Perl interface to cryptographic digests from libnettle

=head1 SYNOPSIS

  use Crypt::Nettle::Hash;

  my $digest = Crypt::Nettle::Hash->new('sha1');
  $digest->update('abc123');
  my $output = $digest->digest();
  printf("sha1: %s\n", unpack('H*', $output));

=head1 ABSTRACT

Crypt::Nettle::Hash provides an object interface to cryptographic
digests from the nettle C library.

=head1 BASIC OPERATIONS

=head2 algos_available()

Get a list of strings that refer to the digests this perl module knows
how to coax out of libnettle:

 my @algos = Crypt::Nettle::Hash::algos_available();

=head2 hash_data($algo, $data)

This is a convenience function to avoid needing to create digest
contexts.

 my $hash = Crypt::Nettle::Hash::hash_data('sha1', $buffer);

=head2 hmac_data($algo, $data, $key)

This is a convenience function to avoid needing to create digest
contexts.

 my $hmac = Crypt::Nettle::Hash::hmac_data('sha1', $buffer, $key);


=head2 new($algo)

Create a new digest context:

  my $digest = Crypt::Nettle::Hash->new('sha1');

The parameter $algo must be the name of a digest algorithm supported
by libnettle.

On error, will return undefined.

Supported digest algorithms are: md2, md4, md5, sha1, sha224, sha256,
sha384, and sha512 (you can retrieve these programmatically with
algos_available()).


=head2 new_hmac($algo, $key)

Create a new HMAC digest context using a given key:

  my $digest = Crypt::Nettle::Hash->new_hmac('sha1', 'akeY$wkxEYS9d2MaW_ge');

It is recommended that you use a key of the same size as the
digest_length() of the chosen digest algorithm.


=head2 is_hmac()

Returns non-zero if this digest context is an HMAC digest context:

  printf("Is HMAC: %s\n", ($digest->is_hmac() ? 'yes' : 'no'));

=head2 copy()

Copy an existing Crypt::Nettle::Hash object, including its internal
state:

  my $new_digest = $digest->copy();

On error, will return undefined.

=head2 update($data)

Pass data into the digest context:

  $digest->update($data);

$data is expected to be a string.  You can call this function as many
times as needed on a $digest object.

=head2 digest()

Return the completed digest over the concatenation of all data passed
to update():

  $output = $digest->digest();

This will also resets the state to be the same as when it was new().

=head2 name()

Return the name of the digest algorithm:

  printf("Digest Algorithm: %s\n", $digest->name());

=head2 digest_size()

Return the size (in bytes) of the digest algorithm in use:

  printf("Digest size: %d\n", $digest->digest_size());

or

  printf("Digest size: %d\n", Crypt::Nettle::Hash->digest_size('sha1'));

=head2 block_size()

Return the internal block size (in bytes) of this digest algorithm:

  printf("Block size: %d\n", $digest->block_size());

or

  printf("Block size: %d\n", Crypt::Nettle::Hash->block_size('sha1'));

=head1 BUGS AND FEEDBACK

Crypt::Nettle::Hash has no known bugs, mostly because no one has
found them yet.  Please write mail to the maintainer
(dkg@fifthhorseman.net) with your contributions, comments,
suggestions, bug reports or complaints.

=head1 AUTHORS AND CONTRIBUTORS

Daniel Kahn Gillmor E<lt>dkg@fifthhorseman.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright © Daniel Kahn Gillmor

Crypt::Nettle::Hash is free software, you may redistribute it and/or
modify it under the GPL version 2 or later (your choice).  Please see
the COPYING file for the full text of the GPL.

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
