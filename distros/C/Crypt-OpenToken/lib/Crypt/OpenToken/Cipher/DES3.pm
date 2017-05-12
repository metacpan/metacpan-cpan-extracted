package Crypt::OpenToken::Cipher::DES3;

use Moose;
use Crypt::CBC;
use Crypt::DES_EDE3;

with 'Crypt::OpenToken::Cipher';

sub keysize { 24 }
sub iv_len  { 8 }
sub cipher {
    my ($self, $key, $iv) = @_;

    my $cipher = Crypt::CBC->new(
        -key         => $key,
        -literal_key => 1,
        -cipher      => 'DES_EDE3',
        -header      => 'none',
        -iv          => $iv,
    );
    return $cipher;
}

1;

=head1 NAME

Crypt::OpenToken::Cipher::DES3 - DES3 encryption support for OpenToken

=head1 DESCRIPTION

This library can be used by C<Crypt::OpenToken> to encrypt payloads using
DES3 encryption.

=head1 METHODS

=over

=item keysize()

Returns the key size used for DES3 encryption; 24 bytes.

=item iv_len()

Returns the length of the Initialization Vector needed for DES3 encryption; 8
bytes.

=item cipher($key, $iv)

Returns a C<Crypt::CBC> compatible cipher the implements the DES3 encryption.

=back

=head1 AUTHOR

Graham TerMarsch (cpan@howlingfrog.com)

=head1 COPYRIGHT & LICENSE

C<Crypt::OpenToken> is Copyright (C) 2010, Socialtext, and is released under
the Artistic-2.0 license.

=head1 SEE ALSO

L<Crypt::OpenToken::Cipher>

=cut
