package Crypt::OpenToken::Cipher::null;

use Moose;
use Crypt::NULL;
use namespace::autoclean;

with 'Crypt::OpenToken::Cipher';

sub keysize { 0 }
sub iv_len  { 0 }
sub cipher {
    # its a "NULL" cipher... there's *no* need for a key or an iv...
    return Crypt::NULL->new('dummy key');
}

1;

=head1 NAME

Crypt::OpenToken::Cipher::null - Null encryption support for OpenToken

=head1 DESCRIPTION

This library can be used by C<Crypt::OpenToken> to encrypt payloads using
NULL encryption.

Yes, that's right, "null encryption" (e.g. B<no> encryption of the data
whatsoever).  Horrible for real-world use, great for interoperability testing.

=head1 METHODS

=over

=item keysize()

Returns the key size used for NULL encryption; 0 bytes.

=item iv_len()

Returns the length of the Initialization Vector needed for NULL encryption; 0
bytes.

=item cipher($key, $iv)

Returns a C<Crypt::CBC> compatible cipher the implements the NULL encryption.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT & LICENSE

C<Crypt::OpenToken> is Copyright (C) 2010, Socialtext, and is released under
the Artistic-2.0 license.

=head1 SEE ALSO

L<Crypt::OpenToken::Cipher>

=cut
