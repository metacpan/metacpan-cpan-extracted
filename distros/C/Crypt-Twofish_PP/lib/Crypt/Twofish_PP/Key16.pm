#! /bin/false

# vim: tabstop=4
# $Id: Key16.pm,v 1.1.1.1 2003/11/21 21:06:56 guido Exp $

# Twofish in pure Perl.
# Copyright (C) 2003 Guido Flohr <guido@imperia.net>, all rights reserved.

# This program is free software; you can redistribute it and/or modify it
# under the same terms and conditions as Perl itsels (see the Artistic
# license included).

package Crypt::Twofish_PP::Key16;

use strict;

use Crypt::Twofish_PP;
use base qw (Crypt::Twofish_PP);

use vars qw ($KEYSIZE);

# See method keysize() below for an explanation.
$KEYSIZE = 16;

sub keysize
{
	my $self = shift;

	if (ref $self) {
		return $self->{__keylength} * 8;
	} else {
		# When called as a class method, return a constant value.
		return $KEYSIZE;
	}
}

1;

__END__

=head1 NAME

Crypt::Twofish_PP::Key16 - Twofish with 16 byte (128 bits) keysize

=head1 SYNOPSIS

  use Crypt::CBC;
  my $cipher = Crypt::CBC->new (key => 'my secret key',
                                cipher => 'Twofish_PP::Key16');

=head1 DESCRIPTION

This module is only a helper module and you should never use it
directly.  Use Crypt::Twofish_PP(3) instead and see there for more
documentation.

The standard module for Cipher Block Chaining (CBC) in Perl,
Crypt::CBC(3) cannot grok with variable key sizes.  However, the
Twofish algorithm is defined for key sizes of 16, 24, and 32 bytes,
but there is no way to communicate that to Crypt::CBC.

If you want to use Crypt::Twofish_PP(3) in CBC mode with a keysize of
16, simply specify B<Crypt::Twofish_PP::Key16> as the algorithm.  It
is eqeuivalent to Crypt::Twofish_PP(3) but it will report a default
keysize of 16 bytes back to Crypt::CBC(3).

Note that this is not necessarily the real keysize.  The method
keysize() of Crypt::Twofish_PP(3) only exists to satisfy Crypt::CBC(3).
The module will derive the real keysize from the length of the key
you supply.

=head1 AUTHOR

Copyright (C) 2003, Guido Flohr E<lt>guido@imperia.netE<gt>, all
rights reserved.  See the source code for details.

This software is contributed to the Perl community by Imperia
(L<http://www.imperia.net/>).

=head1 SEE ALSO

Crypt::CBC(3), Crypt::Twofish_PP(3), Crypt::Twofish::Key24(3),
Crypt::Twofish_PP::Key32(3), perl(1)

=cut
Local Variables:
mode: perl
perl-indent-level: 4
perl-continued-statement-offset: 4
perl-continued-brace-offset: 0
perl-brace-offset: -4
perl-brace-imaginary-offset: 0
perl-label-offset: -4
cperl-indent-level: 4
cperl-continued-statement-offset: 2
tab-width: 4
End:
=cut
