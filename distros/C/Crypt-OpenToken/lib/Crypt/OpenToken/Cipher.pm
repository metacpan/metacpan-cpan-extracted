package Crypt::OpenToken::Cipher;

use Moose::Role;
use namespace::autoclean;

requires 'keysize';
requires 'iv_len';
requires 'cipher';

1;

=head1 NAME

Crypt::OpenToken::Cipher - Interface for OpenToken Ciphers

=head1 DESCRIPTION

This module defines an interface for ciphers.

=head1 METHODS

=over

=item keysize()

Returns the key sized used for encryption, in bytes.

=item iv_len()

Returns the length of the Initialization Vector needed for encryption, in
bytes.

=item cipher($key, $iv)

Returns a C<Crypt::CBC> compatible cipher object which implements the
encryption.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT & LICENSE

C<Crypt::OpenToken> is Copyright (C) 2010, Socialtext, and is released under
the Artistic-2.0 license.

=head1 SEE ALSO

L<Crypt::OpenToken::Cipher::AES128>
L<Crypt::OpenToken::Cipher::AES256>
L<Crypt::OpenToken::Cipher::DES3>
L<Crypt::OpenToken::Cipher::NULL>

=cut
