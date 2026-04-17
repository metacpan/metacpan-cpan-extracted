package Apertur::SDK::Crypto;

use strict;
use warnings;

use MIME::Base64 qw(encode_base64);

use Exporter 'import';
our @EXPORT_OK = qw(encrypt_image);

sub encrypt_image {
    my ($image_data, $public_key_pem) = @_;

    # These modules are optional; only required when encryption is used.
    eval { require Crypt::OpenSSL::RSA }
        or die "Crypt::OpenSSL::RSA is required for encryption features. "
             . "Install it with: cpanm Crypt::OpenSSL::RSA\n";
    eval { require CryptX; require Crypt::AuthEnc::GCM; require Crypt::PRNG }
        or die "CryptX is required for encryption features. "
             . "Install it with: cpanm CryptX\n";

    # Generate random AES-256 key (32 bytes) and IV (12 bytes)
    my $aes_key = Crypt::PRNG::random_bytes(32);
    my $iv      = Crypt::PRNG::random_bytes(12);

    # Encrypt image data with AES-256-GCM
    my $gcm = Crypt::AuthEnc::GCM->new('AES', $aes_key, $iv);
    my $encrypted = $gcm->encrypt_add($image_data);
    my $auth_tag  = $gcm->encrypt_done();
    my $encrypted_with_tag = $encrypted . $auth_tag;

    # Wrap AES key with RSA-OAEP (SHA-256)
    my $rsa = Crypt::OpenSSL::RSA->new_public_key($public_key_pem);
    $rsa->use_pkcs1_oaep_padding();
    $rsa->use_sha256_hash();
    my $wrapped_key = $rsa->encrypt($aes_key);

    return {
        encrypted_key  => encode_base64($wrapped_key,           ''),
        iv             => encode_base64($iv,                    ''),
        encrypted_data => encode_base64($encrypted_with_tag,    ''),
        algorithm      => 'RSA-OAEP+AES-256-GCM',
    };
}

1;

__END__

=head1 NAME

Apertur::SDK::Crypto - Image encryption for Apertur uploads

=head1 SYNOPSIS

    use Apertur::SDK::Crypto qw(encrypt_image);

    my $result = encrypt_image($image_bytes, $public_key_pem);
    # $result->{encrypted_key}   - Base64-encoded RSA-wrapped AES key
    # $result->{iv}              - Base64-encoded 12-byte IV
    # $result->{encrypted_data}  - Base64-encoded AES-256-GCM ciphertext + tag
    # $result->{algorithm}       - "RSA-OAEP+AES-256-GCM"

=head1 DESCRIPTION

Encrypts image data using AES-256-GCM with a random key, then wraps
the AES key using RSA-OAEP with SHA-256. Requires optional dependencies
C<Crypt::OpenSSL::RSA> and C<CryptX>; these are loaded at runtime only
when encryption is actually used.

=head1 FUNCTIONS

=over 4

=item B<encrypt_image($image_data, $public_key_pem)>

Encrypts the given image bytes with the provided PEM-encoded RSA public
key. Returns a hashref with C<encrypted_key>, C<iv>, C<encrypted_data>,
and C<algorithm> (all strings, base64-encoded where applicable).

=back

=cut
