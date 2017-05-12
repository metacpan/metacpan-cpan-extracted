package Authen::Simple::Password;

use strict;
use warnings;

use Crypt::PasswdMD5 qw[];
use Digest::MD5      qw[];
use Digest::SHA      qw[];
use MIME::Base64     qw[];

sub check {
    my ( $class, $password, $encrypted ) = @_;

    # Plain
    return 1 if $password eq $encrypted;

    #                L   S
    # Des           13   2
    # Extended DES  20   9
    # $1$ MD5       34  12
    # $2$ Blowfish  34  16
    # $3$ NT-Hash    ?   ?

    # Crypt
    return 1 if crypt( $password, $encrypted ) eq $encrypted;

    # Crypt Modular Format
    if ( $encrypted =~ /^\$(\w+)\$/ ) {
        return 1 if $class->_check_modular( $password, $encrypted, lc($1) );
    }

    # LDAP Format
    if ( $encrypted =~ /^\{(\w+)\}/ ) {
        return 1 if $class->_check_ldap( $password, $encrypted, lc($1) );
    }

    # MD5
    if ( length($encrypted) == 16 ) {
        return 1 if Digest::MD5::md5($password) eq $encrypted;
    }

    if ( length($encrypted) == 22 ) {
        return 1 if Digest::MD5::md5_base64($password) eq $encrypted;
    }

    if ( length($encrypted) == 32 ) {
        return 1 if Digest::MD5::md5_hex($password) eq $encrypted;
    }

    # SHA-1
    if ( length($encrypted) == 20 ) {
        return 1 if Digest::SHA::sha1($password) eq $encrypted;
    }

    if ( length($encrypted) == 27 ) {
        return 1 if Digest::SHA::sha1_base64($password) eq $encrypted;
    }

    if ( length($encrypted) == 40 ) {
        return 1 if Digest::SHA::sha1_hex($password) eq $encrypted;
    }

    # SHA-2 256
    if ( length($encrypted) == 32 ) {
        return 1 if Digest::SHA::sha256($password) eq $encrypted;
    }

    if ( length($encrypted) == 43 ) {
        return 1 if Digest::SHA::sha256_base64($password) eq $encrypted;
    }

    if ( length($encrypted) == 64 ) {
        return 1 if Digest::SHA::sha256_hex($password) eq $encrypted;
    }

    return 0;
}

sub _check_ldap {
    my ( $class, $password, $encrypted, $scheme ) = @_;

    if ( $scheme eq 'cleartext' ) {
        my $hash = substr( $encrypted, 11 );
        return 1 if $password eq $hash;
    }

    if ( $scheme eq 'crypt' ) {
        my $hash = substr( $encrypted, 7 );
        return 1 if crypt( $password, $hash ) eq $hash;
    }

    if ( $scheme eq 'md5' ) {
        my $hash = MIME::Base64::decode( substr( $encrypted, 5 ) );
        return 1 if Digest::MD5::md5($password) eq $hash;
    }

    if ( $scheme eq 'smd5' ) {
        my $hash = MIME::Base64::decode( substr( $encrypted, 6 ) );
        my $salt = substr( $hash, 16 );
        return 1 if Digest::MD5::md5( $password, $salt ) . $salt eq $hash;
    }

    if ( $scheme eq 'sha' ) {
        my $hash = MIME::Base64::decode( substr( $encrypted, 5 ) );
        return 1 if Digest::SHA::sha1($password) eq $hash;
    }

    if ( $scheme eq 'ssha' ) {
        my $hash = MIME::Base64::decode( substr( $encrypted, 6 ) );
        my $salt = substr( $hash, 20 );
        return 1 if Digest::SHA::sha1( $password, $salt ) . $salt eq $hash;
    }

    return 0;
}

sub _check_modular {
    my ( $class, $password, $encrypted, $format ) = @_;

    if ( $format eq '1' ) {
        return 1 if Crypt::PasswdMD5::unix_md5_crypt( $password, $encrypted ) eq $encrypted;
    }

    if ( $format eq 'apr1' ) {
        return 1 if Crypt::PasswdMD5::apache_md5_crypt( $password, $encrypted ) eq $encrypted;
    }

    return 0;
}

1;

__END__

=head1 NAME

Authen::Simple::Password - Simple password checking

=head1 SYNOPSIS

    if ( Authen::Simple::Password->check( $password, $encrypted ) ) {
        # OK
    }

=head1 DESCRIPTION

Provides a simple way to verify passwords.

=head1 METHODS

=over 4

=item * check( $password, $encrypted )

Returns true on success and false on failure.

=back

=head1 SUPPORTED PASSWORD FORMATS

=over 4

=item * Plain

Plaintext

=item * Crypt

L<crypt(3)>

=item * Crypt Modular

=over 8

=item * $1$ 

MD5-based password algorithm

=item * $apr$ 

MD5-based password algorithm, Apache variant

=back

=item * LDAP

=over 8

=item * {CLEARTEXT}

Plaintext.

=item * {CRYPT}

Uses L<crypt(3)>

=item * {MD5}

MD5 algorithm

=item * {SMD5}

Seeded MD5 algorithm

=item * {SHA}

SHA-1 algorithm

=item * {SSHA}

Seeded SHA-1 algorithm

=back

=item * MD5 algorithm

Encoded as binary, Base64 or hexadecimal.

=item * SHA-1 algorithm

Encoded as binary, Base64 or hexadecimal.

=item * SHA-2 256 algorithm

Encoded as binary, Base64 or hexadecimal.

=back

=head1 SEE ALSO

L<Authen::Simple>

L<crypt(3)>.

=head1 AUTHOR

Christian Hansen C<chansen@cpan.org>

=head1 COPYRIGHT

This program is free software, you can redistribute it and/or modify 
it under the same terms as Perl itself.

=cut
