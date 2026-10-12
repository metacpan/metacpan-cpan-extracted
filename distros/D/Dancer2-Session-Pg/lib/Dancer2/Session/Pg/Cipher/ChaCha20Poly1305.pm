package Dancer2::Session::Pg::Cipher::ChaCha20Poly1305;

use strict;
use warnings;

use Moo;
use Crypt::AuthEnc::ChaCha20Poly1305 ();

our $VERSION = '0.002';

with 'Dancer2::Session::Pg::Cipher';

sub cipher_id   { return 4 }
sub cipher_name { return 'ChaCha20-Poly1305' }
sub key_bytes   { return 32 }
sub iv_bytes    { return 12 }
sub tag_bytes   { return 16 }

sub seal {
    my ( $self, $key, $iv, $plaintext, $aad ) = @_;
    return Crypt::AuthEnc::ChaCha20Poly1305::chacha20poly1305_encrypt_authenticate( $key, $iv, $aad, $plaintext );
}

sub unseal {    ## no critic (Subroutines::ProhibitManyArgs) -- six is the AEAD contract in Dancer2::Session::Pg::Cipher
    my ( $self, $key, $iv, $ciphertext, $tag, $aad ) = @_;
    return Crypt::AuthEnc::ChaCha20Poly1305::chacha20poly1305_decrypt_verify( $key, $iv, $aad, $ciphertext, $tag );
}

1;

__END__

=encoding utf8

=for stopwords ChaCha ChaCha20 Poly1305 ChaCha20Poly1305 AEAD AES GCM AESGCM nonce plaintext Mikko Koivunalho

=head1 NAME

Dancer2::Session::Pg::Cipher::ChaCha20Poly1305 - ChaCha20-Poly1305 for Dancer2::Session::Pg

=head1 VERSION

version 0.001

=head1 SYNOPSIS

    alg => 'ChaCha20-Poly1305'

=head1 DESCRIPTION

ChaCha20 with Poly1305 authentication, from L<CryptX>. A 32-byte key, a 96-bit
nonce and a 128-bit tag; cipher id C<4>.

Prefer it over AES-GCM on hardware without AES acceleration, where it is
markedly faster. It takes the same key length as C<AES-256-GCM>, which is what
makes those two interchangeable without logging anybody out -- see
L<Dancer2::Session::Pg/Replacing a cipher>.

Does L<Dancer2::Session::Pg::Cipher>.

=head1 METHODS

See L<Dancer2::Session::Pg::Cipher> for the contract.

=head1 SEE ALSO

L<Dancer2::Session::Pg>, L<Dancer2::Session::Pg::Cipher>, L<CryptX>

=begin Pod::Coverage

cipher_id
cipher_name
key_bytes
iv_bytes
tag_bytes
seal
unseal

=end Pod::Coverage

=head1 AUTHOR

Mikko Koivunalho <mikko.koivunalho@iki.fi>

=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2026 by Mikko Koivunalho.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
