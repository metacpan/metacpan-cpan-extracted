package Crypt::Cryptoki;
use strict;

our $VERSION = '0.01';
$VERSION = eval $VERSION;

1;
__END__
=head1 NAME

Crypt::Cryptoki - Perl extension for PKCS#11

=head1 SYNOPSIS

	(in the meantime look at Crypt::Cryptoki::Raw)

=head1 DESCRIPTION

TBD: This module uses "Crypt::Cryptoki::Raw" to provide a object-oriented access to PKCS#11 instances.

"RSA Security Inc. Public-Key Cryptography Standards (PKCS)"
Please refer to Crypt::Cryptoki::Raw for more information about PKCS#11.


=head2 FUNCTIONS

=head2 METHODS

=head2 EXPORT

None by default.

=head2 TODO

=head1 SEE ALSO

L<Crypt::Cryptoki::Raw>

L<http://www.emc.com/emc-plus/rsa-labs/standards-initiatives/pkcs-11-cryptographic-token-interface-standard.htm>

L<https://www.oasis-open.org/committees/pkcs11>

=head1 AUTHOR

Markus Lauer, E<lt>mlarue@cpan.orgE<gt>

=head1 COPYRIGHT AND LICENSE

Copyright (C) 2014 by Markus Lauer

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.12.5 or,
at your option, any later version of Perl 5 you may have available.


=cut
