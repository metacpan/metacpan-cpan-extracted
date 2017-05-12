package Crypt::Cryptoki::Raw;
use strict;

require XSLoader;
XSLoader::load('Crypt::Cryptoki::Raw');

1;
__END__
=head1 NAME

Crypt::Cryptoki::Raw - "Low-level" Perl extension for PKCS#11

=head1 SYNOPSIS

	use Crypt::Cryptoki::Raw;
	use Crypt::Cryptoki::Constant qw(:all);

	my $raw = Crypt::Cryptoki::Raw->new('/usr/lib64/softhsm/libsofthsm.so');

	$raw->C_Initialize;

	my $info = {};
	$raw->C_GetInfo($info);

	my $slots = [];
	$raw->C_GetSlotList(1,$slots);

	for my $id ( @$slots ) {
		my $slotInfo = {};
		$raw->C_GetSlotInfo($id,$slotInfo);

		my $tokenInfo = {};
		$raw->C_GetTokenInfo($id,$tokenInfo);
	}

	my $session = -1;
	$raw->C_OpenSession(0,CKF_SERIAL_SESSION|CKF_RW_SESSION,$session);

	$raw->C_Login($session, CKU_USER, '1234'));

	
	(see also: t/softhsm.t)


=head1 DESCRIPTION

This module brings the "Cryptoki" to perl. It is nearly a one-to-one mapping
from C to Perl and vice versa.

"RSA Security Inc. Public-Key Cryptography Standards (PKCS)"

Original documentation: L<ftp://ftp.rsasecurity.com/pub/pkcs/pkcs-11/v2-20/pkcs-11v2-20.pdf>

C header files and documentation are also part of the distribution.

=head2 FUNCTIONS

	C_Initialize
	C_GetInfo
	C_GetSlotList
	C_GetSlotInfo
	C_GetTokenInfo
	C_OpenSession
	C_GetSessionInfo
	C_Login
	C_GenerateKeyPair
	C_EncryptInit
	C_Encrypt
	C_DecryptInit
	C_Decrypt
	C_SignInit
	C_Sign
	C_VerifyInit
	C_Verify
	C_DestroyObject

=head2 EXPORT

None by default.

=head2 TODO

Everything to cover Cryptoki 2.20. Especially the incremental functions.

=head1 SEE ALSO

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
