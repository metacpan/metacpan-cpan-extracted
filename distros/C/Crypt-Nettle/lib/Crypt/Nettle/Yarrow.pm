# ===========================================================================
# Crypt::Nettle:Yarrow
#
# Perl interface to the Yarrow256 random number generator from libnettle
#
# Author: Daniel Kahn Gillmor E<lt>dkg@fifthhorseman.netE<gt>,
# Copyright © 2011.
#
# Use this software AT YOUR OWN RISK.
# See below for documentation.
#

package Crypt::Nettle::Yarrow;

use strict;
use warnings;

use Crypt::Nettle;

1;
__END__

=head1 NAME

Crypt::Nettle::Yarrow - Perl interface to the Yarrow256 random number generator from libnettle

=head1 SYNOPSIS

  use Crypt::Nettle::Yarrow;

  my $devrandom = IO::File->new('/dev/random', 'r');
  my $seed;
  $devrandom->read($seed, Crypt::Nettle::Yarrow::SEED_FILE_SIZE);

  my $rng = Crypt::Nettle::Yarrow->new();
  $rng->seed($devrandom->read();
  my $data = $rng->random(32);

=head1 ABSTRACT

Crypt::Nettle::Yarrow provides an object interface to the Yarrow256
random number generator from the nettle C library.

=head1 BASIC OPERATIONS

=head2 new()

Create a new Yarrow256 PRNG.

=head2 seed($data)

Set up an initial seed of the generator from unguessable $data.

=head2 random($length)

Return a scalar with $length random octets.

=head2 is_seeded()

Returns 1 if the generator is seeded.

=head1 VARIABLES

=head2 SEED_FILE_SIZE

The size of the seed file for Yarrow256.

=head1 DANGEROUS OPERATIONS

=head2 fast_reseed()

=head2 slow_reseed()

Cause a fast or slow reseed to take place immediately, regardless of
the current entropy estimates of the two pools. Use with care.

=head1 BUGS AND FEEDBACK

Updating the pool is not yet implemented.

It would be nice to have a convenience function for seeding from
/dev/random if the file is available.

Crypt::Nettle::Yarrow has no other known bugs, mostly because no one
has found them yet.  Please write mail to the maintainer
(dkg@fifthhorseman.net) with your contributions, comments,
suggestions, bug reports or complaints.

=head1 AUTHORS AND CONTRIBUTORS

Daniel Kahn Gillmor E<lt>dkg@fifthhorseman.netE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright © Daniel Kahn Gillmor

Crypt::Nettle::Yarrow is free software, you may redistribute it and/or
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
