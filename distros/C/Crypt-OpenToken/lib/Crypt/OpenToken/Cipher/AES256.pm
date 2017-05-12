package Crypt::OpenToken::Cipher::AES256;

use Moose;
# Crypt::Rijndael will figure out whether its 128 or 256 bit mode depending on
# the key we use, so leverage the implementation in C:OT:C:AES128
extends 'Crypt::OpenToken::Cipher::AES128';

sub keysize { 32 }

1;

=head1 NAME

Crypt::OpenToken::Cipher::AES256 - AES256 encryption support for OpenToken

=head1 DESCRIPTION

This library can be used by C<Crypt::OpenToken> to encrypt payloads using
AES-256 encryption.

=head1 METHODS

=over

=item keysize()

Returns the key size used for AES-256 encryption; 32 bytes.

=item iv_len()

Returns the length of the Initialization Vector needed for AES-256 encryption;
16 bytes.

=item cipher($key, $iv)

Returns a C<Crypt::CBC> compatible cipher the implements the AES-256
encryption.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT & LICENSE

C<Crypt::OpenToken> is Copyright (C) 2010, Socialtext, and is released under
the Artistic-2.0 license.

=head1 SEE ALSO

L<Crypt::OpenToken::Cipher>

=cut
