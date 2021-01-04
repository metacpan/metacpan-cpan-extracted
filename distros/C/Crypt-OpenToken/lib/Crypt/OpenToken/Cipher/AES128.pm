package Crypt::OpenToken::Cipher::AES128;

use Moose;
use Crypt::Rijndael;
use namespace::autoclean;

with 'Crypt::OpenToken::Cipher';

sub keysize { 16 }
sub iv_len  { 16 }
sub cipher {
    my ($self, $key, $iv) = @_;
    my $crypto = Crypt::Rijndael->new($key, Crypt::Rijndael::MODE_CBC());
    $crypto->set_iv($iv);
    return $crypto;
}

1;

=head1 NAME

Crypt::OpenToken::Cipher::AES128 - AES128 encryption support for OpenToken

=head1 DESCRIPTION

This library can be used by C<Crypt::OpenToken> to encrypt payloads using
AES-128 encryption.

=head1 METHODS

=over

=item keysize()

Returns the key size used for AES-128 encryption; 16 bytes.

=item iv_len()

Returns the length of the Initialization Vector needed for AES-128 encryption;
16 bytes.

=item cipher($key, $iv)

Returns a C<Crypt::CBC> compatible cipher the implements the AES-128
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
