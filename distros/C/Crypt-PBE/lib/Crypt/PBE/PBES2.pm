package Crypt::PBE::PBES2;

use strict;
use warnings;
use utf8;

use Carp;
use Crypt::CBC;
use Exporter qw(import);

use Crypt::PBE::PBKDF2;

our $VERSION = '0.103';

use constant KEY_SIZE => {
    'aes-128' => 16,
    'aes-192' => 24,
    'aes-256' => 32,
};

use constant ENCRYPTION => {
    'aes-128' => 'Crypt::OpenSSL::AES',
    'aes-192' => 'Crypt::OpenSSL::AES',
    'aes-256' => 'Crypt::OpenSSL::AES',
};

use constant HMAC => qw( hmac-sha1 hmac-224 hmac-sha256 hmac-sha384 hmac-sha512 );

sub new {

    my ( $class, %params ) = @_;

    my $self = {
        password   => $params{password}   || croak('Specify password'),
        hmac       => $params{hmac}       || croak('Specify HMAC digest algorithm'),
        encryption => $params{encryption} || croak('Specify encryption method'),
        count      => $params{count}      || 1_000,
        dk_len     => 0,
    };

    my $dk_len = KEY_SIZE->{ $params{encryption} };

    if ( !$dk_len ) {
        croak('Unknown encryption method');
    }

    $self->{dk_len} = $dk_len;

    return bless $self, $class;

}

sub encrypt {

    my ( $self, $data ) = @_;

    my $salt = Crypt::CBC->random_bytes(16);
    my $iv   = Crypt::CBC->random_bytes(16);

    my $key = pbkdf2(
        prf      => $self->{hmac},
        password => $self->{password},
        salt     => $salt,
        dk_len   => $self->{dk_len},
        count    => $self->{count}
    );

    my $cipher = Crypt::CBC->new(
        -key         => $key,
        -keysize     => length($key),
        -iv          => $iv,
        -header      => 'none',
        -literal_key => 1,
        -cipher      => ENCRYPTION->{ $self->{encryption} }
    );

    my $encrypted = $cipher->encrypt($data);

    my @result = ( $salt, $iv, $encrypted );

    return wantarray ? @result : join( '', @result );

}

sub decrypt {

    my ( $self, $salt, $iv, $encrypted ) = @_;

    if ( !$iv && !$encrypted ) {

        my $data = $salt;

        $salt      = substr( $data, 0,  16 );
        $iv        = substr( $data, 16, 16 );
        $encrypted = substr( $data, 32 );

    }

    my $key = pbkdf2(
        prf      => $self->{hmac},
        password => $self->{password},
        salt     => $salt,
        dk_len   => $self->{dk_len},
        count    => $self->{count}
    );

    my $cipher = Crypt::CBC->new(
        -key         => $key,
        -keysize     => length($key),
        -iv          => $iv,
        -header      => 'none',
        -literal_key => 1,
        -cipher      => ENCRYPTION->{ $self->{encryption} }
    );

    return $cipher->decrypt($encrypted);

}

1;

=head1 NAME

Crypt::PBE::PBES2 - Perl extension for PKCS #5 Password-Based Encryption Schema 2 (PBES2)

=head1 SYNOPSIS

    use Crypt::PBE::PBES2;

    my $pbes2 = Crypt::PBE::PBES2->new(
        'hmac'       => 'hmac-sha256',
        'encryption' => 'aes-128',
        'password'   => 'mypassword'
    );

    my $encrypted = $pbes2->encrypt('secret');
    say $pbes2->decrypt($encrypted); # secret


=head1 DESCRIPTION

PBES2 combines a password-based key derivation function, which shall be PBKDF2 
with an underlying encryption scheme.  The key length and any other parameters
for the underlying encryption scheme depend on the scheme.

PBES2 is recommended for new applications.


=head1 CONSTRUCTOR

=head2 Crypt::PBE::PBES2->new ( %params )

Params:

=over 4

=item * C<password> : The password to use for the derivation

=item * C<hmac> : HMAC digest algorithm ("hmac-sha1", "hmac-sha224", "hmac-sha256", "hmac-sha384" or "hmac-512")

=item * C<encryption> : Encryption method ("aes-128", "aes-192" or "aes-256")

=item * C<count> : The number of internal iteractions to perform for the derivation key (default "1_000")

=back


=head1 METHODS

=head2 $pbes2->encrypt( $message )

Perform the encryption and return the encrypted message in binary format.

You can encode the encrypted message in Base64 using L<MIME::Base64>:

    $b64_encrypted = encode_base64 $pbes2->encrypt('secret');


=head2 $pbes2->decrypt( $data )

Perform the decryption and return the original message.

    $decrypted = $pbes2->decrypt($encrypted);

You can decode the Base64 encrypted message using L<MIME::Base64>:

    $decrypted = $pbes2->decrypt(decode_base64 $b64_encrypted);


=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through the issue tracker
at L<https://github.com/giterlizzi/perl-Crypt-PBE/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/giterlizzi/perl-Crypt-PBE>

    git clone https://github.com/giterlizzi/perl-Crypt-PBE.git


=head1 AUTHOR

=over 4

=item * Giuseppe Di Terlizzi <gdt@cpan.org>

=back


=head1 SEE ALSO

=over 4

=item L<Crypt::PBE::PBKDF2>

=item L<Crypt::PBE::PBES1>

=item [RFC2898] PKCS #5: Password-Based Cryptography Specification Version 2.0 (L<https://tools.ietf.org/html/rfc2898>)

=item [RFC8018] PKCS #5: Password-Based Cryptography Specification Version 2.1 (L<https://tools.ietf.org/html/rfc8018>)

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020-2023 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
