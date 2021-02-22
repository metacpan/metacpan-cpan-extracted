package Crypt::PBE::PBES1;

use strict;
use warnings;
use utf8;

use Carp;
use Crypt::CBC;
use Exporter qw(import);

use Crypt::PBE::PBKDF1;

our $VERSION = '0.102';

use constant ENCRYPTION => { 'des' => 'Crypt::DES', };

sub new {

    my ( $class, %params ) = @_;

    my $self = {
        password   => $params{password}   || croak('Specify password'),
        count      => $params{count}      || 1_000,
        hash       => $params{hash}       || croak('Specify hash digest algorithm'),
        encryption => $params{encryption} || 'des',                                    # TODO add support for RC2
        dk_len     => 0,
    };

    my $dk_len = 20;
    $dk_len = 16 if ( $self->{hash} =~ '/md(2|5)/' );

    $self->{dk_len} = $dk_len;

    return bless $self, $class;

}

sub encrypt {

    my ( $self, $data ) = @_;

    my $salt = Crypt::CBC->random_bytes(8);
    my $DK   = pbkdf1(
        hash     => $self->{hash},
        password => $self->{password},
        salt     => $salt,
        count    => $self->{count},
        dk_len   => $self->{dl_len}
    );

    my $key = substr( $DK, 0, 8 );
    my $iv  = substr( $DK, 8, 8 );

    my $crypt = Crypt::CBC->new(
        -key         => $key,
        -iv          => $iv,
        -literal_key => 1,
        -header      => 'none',
        -cipher      => 'Crypt::DES',
    );

    my @result = ( $salt, $crypt->encrypt($data) );

    return wantarray ? @result : join( '', @result );

}

sub decrypt {

    my ( $self, $salt, $encrypted ) = @_;

    if ( !$encrypted ) {
        my $data = $salt;
        $salt      = substr( $data, 0, 8 );
        $encrypted = substr( $data, 8 );
    }

    my $DK = pbkdf1(
        hash     => $self->{hash},
        password => $self->{password},
        salt     => $salt,
        count    => $self->{count},
        dk_len   => $self->{dl_len}
    );

    my $key = substr( $DK, 0, 8 );
    my $iv  = substr( $DK, 8, 8 );

    my $ciper = Crypt::CBC->new(
        -key         => $key,
        -iv          => $iv,
        -literal_key => 1,
        -header      => 'none',
        -cipher      => 'Crypt::DES',
    );

    my $decrypted = $ciper->decrypt($encrypted);

    return $decrypted;

}

1;

=head1 NAME

Crypt::PBE::PBES1 - Perl extension for PKCS #5 Password-Based Encryption Schema 1 (PBES1)

=head1 SYNOPSIS

    use Crypt::PBE::PBES1;

    my $pbes1 = Crypt::PBE::PBES1->new(
        'hash'       => 'md5',
        'encryption' => 'des',
        'password'   => 'mypassword'
    );

    my $encrypted = $pbes1->encrypt('secret');
    say $pbes1->decrypt($encrypted); # secret


=head1 DESCRIPTION

PBES1 combines the PBKDF1 function with an underlying block cipher, which shall
be either DES or RC2 in cipher block chaining (CBC) mode.

PBES1 is recommended only for compatibility with existing applications, since it
supports only two underlying encryption schemes, each of which has a key size
(56 or 64 bits) that may not be large enough for some applications.


=head1 CONSTRUCTOR

=head2 Crypt::PBE::PBES1->new ( %params )

Params:

=over 4

=item * C<password> : The password to use for the derivation

=item * C<hash> : Hash algorithm ("md2", "md5 or "sha1")

=item * C<encryption> : Encryption method ("des")

=item * C<count> : The number of internal iteractions to perform for the derivation key (default "1_000")

=back


=head1 METHODS

=head2 $pbes1->encrypt( $message )

Perform the encryption and return the encrypted message in binary format.

You can encode the encrypted message in Base64 using L<MIME::Base64>:

    $b64_encrypted = encode_base64 $pbes1->encrypt('secret');


=head2 $pbes1->decrypt( $data )

Perform the decryption and return the original message.

    $decrypted = $pbes1->decrypt($encrypted);

You can decode the Base64 encrypted message using L<MIME::Base64>:

    $decrypted = $pbes1->decrypt(decode_base64 $b64_encrypted);


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

=item L<Crypt::PBE::PBKDF1>

=item L<Crypt::PBE::PBES2>

=item [RFC2898] PKCS #5: Password-Based Cryptography Specification Version 2.0 (L<https://tools.ietf.org/html/rfc2898>)

=item [RFC8018] PKCS #5: Password-Based Cryptography Specification Version 2.1 (L<https://tools.ietf.org/html/rfc8018>)

=back


=head1 LICENSE AND COPYRIGHT

This software is copyright (c) 2020-2021 by Giuseppe Di Terlizzi.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
