package Crypt::PBE;

use strict;
use warnings;
use utf8;

use Carp;

use Crypt::PBE::PBES1;
use Crypt::PBE::PBES2;

our $VERSION = '0.103';

use Exporter qw(import);

my @JCE_PBE_ALGORITHMS = qw(

    PBEWithMD5AndDES

    PBEWithHmacSHA1AndAES_128
    PBEWithHmacSHA1AndAES_192
    PBEWithHmacSHA1AndAES_256

    PBEWithHmacSHA224AndAES_128
    PBEWithHmacSHA224AndAES_192
    PBEWithHmacSHA224AndAES_256

    PBEWithHmacSHA256AndAES_128
    PBEWithHmacSHA256AndAES_192
    PBEWithHmacSHA256AndAES_256

    PBEWithHmacSHA384AndAES_128
    PBEWithHmacSHA384AndAES_192
    PBEWithHmacSHA384AndAES_256

    PBEWithHmacSHA512AndAES_128
    PBEWithHmacSHA512AndAES_192
    PBEWithHmacSHA512AndAES_256
);

our @EXPORT_OK = @JCE_PBE_ALGORITHMS;

our %EXPORT_TAGS = ( 'jce' => \@JCE_PBE_ALGORITHMS );

# JCE algorithm PBEWith<digest>And<encryption>

my $pbes1_map = {
    'PBEWithMD2AndDES'  => { hash => 'md2',  encryption => 'des' },
    'PBEWithMD5AndDES'  => { hash => 'md5',  encryption => 'des' },
    'PBEWithSHA1AndDES' => { hash => 'sha1', encryption => 'des' },
};

my $pbes2_map = {
    'PBEWithHmacSHA1AndAES_128'   => { hmac => 'hmac-sha1',   encryption => 'aes-128' },
    'PBEWithHmacSHA1AndAES_192'   => { hmac => 'hmac-sha1',   encryption => 'aes-192' },
    'PBEWithHmacSHA1AndAES_256'   => { hmac => 'hmac-sha1',   encryption => 'aes-256' },
    'PBEWithHmacSHA224AndAES_128' => { hmac => 'hmac-sha224', encryption => 'aes-128' },
    'PBEWithHmacSHA224AndAES_192' => { hmac => 'hmac-sha224', encryption => 'aes-192' },
    'PBEWithHmacSHA224AndAES_256' => { hmac => 'hmac-sha224', encryption => 'aes-256' },
    'PBEWithHmacSHA256AndAES_128' => { hmac => 'hmac-sha256', encryption => 'aes-128' },
    'PBEWithHmacSHA256AndAES_192' => { hmac => 'hmac-sha256', encryption => 'aes-192' },
    'PBEWithHmacSHA256AndAES_256' => { hmac => 'hmac-sha256', encryption => 'aes-256' },
    'PBEWithHmacSHA384AndAES_128' => { hmac => 'hmac-sha384', encryption => 'aes-128' },
    'PBEWithHmacSHA384AndAES_192' => { hmac => 'hmac-sha384', encryption => 'aes-192' },
    'PBEWithHmacSHA384AndAES_256' => { hmac => 'hmac-sha384', encryption => 'aes-256' },
    'PBEWithHmacSHA512AndAES_128' => { hmac => 'hmac-sha512', encryption => 'aes-128' },
    'PBEWithHmacSHA512AndAES_192' => { hmac => 'hmac-sha512', encryption => 'aes-192' },
    'PBEWithHmacSHA512AndAES_256' => { hmac => 'hmac-sha512', encryption => 'aes-256' },
};

# PBES1 + PBDKF1

foreach my $sub_name ( keys %{$pbes1_map} ) {

    my $params = $pbes1_map->{$sub_name};

    no strict 'refs';    ## no critic

    *{$sub_name} = sub {
        my ( $password, $count ) = @_;
        my $pbes1 = Crypt::PBE::PBES1->new(
            password   => $password,
            count      => ( $count || 1_000 ),
            hash       => $params->{hash},
            encryption => $params->{encryption},
        );
        return $pbes1;
    };

}

# PBES2 + PBDKF2

foreach my $sub_name ( keys %{$pbes2_map} ) {

    my $params = $pbes2_map->{$sub_name};

    no strict 'refs';    ## no critic

    *{$sub_name} = sub {
        my ( $password, $count ) = @_;
        my $pbes2 = Crypt::PBE::PBES2->new(
            password   => $password,
            count      => ( $count || 1_000 ),
            hmac       => $params->{hmac},
            encryption => $params->{encryption},
        );
        return $pbes2;
    };

}

1;
__END__
=head1 NAME

Crypt::PBE - Perl extension for PKCS #5 Password-Based Encryption Algorithms

=head1 SYNOPSIS

    use Crypt::PBE qw(:jce);

    my $pbe = PBEWithMD5AndDES('mypassword');

    my $encrypted = $pbe->encrypt('secret'); # Base64 encrypted data

    print $pbe->decrypt($encrypted);


=head1 DESCRIPTION



=head2 PBES and PBKDF

=over 4

=item L<Crypt::PBE::PBKDF1> - Password-Based Key Derivation Function 1

=item L<Crypt::PBE::PBES1> - Password-Based Key Encryption Schema 1

=item L<Crypt::PBE::PBKDF2> - Password-Based Key Derivation Function 2

=item L<Crypt::PBE::PBES2> - Password-Based Key Encryption Schema 2

=back

=head2 EXPORTED JCE-STYLE FUNCTIONS

=head3 PBES1 (Password-Based Encryption Schema 1)

=over 4

=item * C<PBEWithMD2AndDES> : Password-Based Encryption with MD2 and DES

=item * C<PBEWithMD5AndDES> : Password-Based Encryption with MD5 and DES

=item * C<PBEWithSHA1AndDES> : Password-Based Encryption with SHA1 and DES

=back

=head3 PBES2 (Password-Based Encryption Schema 2)

=over 4

=item * C<PBEWithHmacSHA1AndAES_128> : Password-Based Encryption with SHA-1 HMAC and AES 128 bit

=item * C<PBEWithHmacSHA1AndAES_192> : Password-Based Encryption with SHA-1 HMAC and AES 192 bit

=item * C<PBEWithHmacSHA1AndAES_256> : Password-Based Encryption with SHA-1 HMAC and AES 256 bit

=item * C<PBEWithHmacSHA224AndAES_128> : Password-Based Encryption with SHA-224 HMAC and AES 128 bit

=item * C<PBEWithHmacSHA224AndAES_192> : Password-Based Encryption with SHA-224 HMAC and AES 192 bit

=item * C<PBEWithHmacSHA224AndAES_256> : Password-Based Encryption with SHA-224 HMAC and AES 256 bit

=item * C<PBEWithHmacSHA256AndAES_128> : Password-Based Encryption with SHA-256 HMAC and AES 128 bit

=item * C<PBEWithHmacSHA256AndAES_192> : Password-Based Encryption with SHA-256 HMAC and AES 192 bit

=item * C<PBEWithHmacSHA256AndAES_256> : Password-Based Encryption with SHA-256 HMAC and AES 256 bit

=item * C<PBEWithHmacSHA384AndAES_128> : Password-Based Encryption with SHA-384 HMAC and AES 128 bit

=item * C<PBEWithHmacSHA384AndAES_192> : Password-Based Encryption with SHA-384 HMAC and AES 192 bit

=item * C<PBEWithHmacSHA384AndAES_256> : Password-Based Encryption with SHA-384 HMAC and AES 256 bit

=item * C<PBEWithHmacSHA512AndAES_128> : Password-Based Encryption with SHA-512 HMAC and AES 128 bit

=item * C<PBEWithHmacSHA512AndAES_192> : Password-Based Encryption with SHA-512 HMAC and AES 192 bit

=item * C<PBEWithHmacSHA512AndAES_256> : Password-Based Encryption with SHA-512 HMAC and AES 256 bit

=back

=head1 SEE ALSO

=over 4

=item [RFC2898] PKCS #5: Password-Based Cryptography Specification Version 2.0 (L<https://tools.ietf.org/html/rfc2898>)

=item [RFC8018] PKCS #5: Password-Based Cryptography Specification Version 2.1 (L<https://tools.ietf.org/html/rfc8018>)

=item [RFC6070] PKCS #5: Password-Based Key Derivation Function 2 (PBKDF2) - Test Vectors (L<https://tools.ietf.org/html/rfc6070>)

=item [RFC2307] An Approach for Using LDAP as a Network Information Service (L<https://tools.ietf.org/html/rfc2307>)

=back


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


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020-2023 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
