# ===========================================================================
# Crypt::Netle
#
# Perl interface to the Nettle Cryptographic library
#
# Author: Daniel Kahn Gillmor <dkg@fifthhorseman.net>
# Copyright (c) 2011
#
# Use this software AT YOUR OWN RISK.
# See below for documentation.
#

package Crypt::Nettle;

use strict;
use warnings;

our $VERSION = '0.2';

require XSLoader;
XSLoader::load('Crypt::Nettle', $VERSION);

1;
__END__

=head1 NAME

Crypt::Nettle - Perl interface to the Nettle Cryptographic library

=head1 SYNOPSIS

  use Crypt::Nettle;

=head1 ABSTRACT

Crypt::Nettle provides an object interface to the C nettle library. It
currently supports message digests (including HMAC), symmetric
encryption and decryption, pseudo-random number generation, and RSA
public-key crypto.

In the future, it should also support DSA for public-key signatures.

=head1 MESSAGE DIGESTS (HASH FUNCTIONS)

See Crypt::Nettle::Hash for digest functions and HMAC.

=head1 SYMMETRIC ENCRYPTION

See Crypt::Nettle::Cipher for symmetric encryption and decryption.

=head1 RANDOM NUMBER GENERATION

See Crypt::Nettle::Yarrow for a cryptographic random number generator.

=head1 ASYMMETRIC CRYPTOGRAPHY

The only public-key crypto algorithm supported by Crypt::Nettle at the
moment is RSA.  See Crypt::Nettle::RSA for details.

=head1 BUGS AND FEEDBACK

Crypt::Nettle has no known bugs, mostly because no one has reported
any. Please mail to the author (dkg@fifthhorseman.net) with your
contributions, comments, suggestions, bug reports or complaints.

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

