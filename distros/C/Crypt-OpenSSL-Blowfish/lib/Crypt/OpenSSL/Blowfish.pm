package Crypt::OpenSSL::Blowfish;

use strict;
use Carp;

use vars qw/$VERSION @ISA/;

require DynaLoader;
@ISA = qw/DynaLoader/;

$VERSION = '0.08';

bootstrap Crypt::OpenSSL::Blowfish $VERSION;

sub blocksize   {  8; }
sub keysize     {  0; }
sub min_keysize {  8; }
sub max_keysize { 56; }

sub encrypt {
    my ($self, $data) = @_;

    return $self->crypt($data, 1);

}

sub decrypt {
    my ($self, $data) = @_;

    return $self->crypt($data, 0);

}

1;

__END__

=head1 NAME

Crypt::OpenSSL::Blowfish - Blowfish Algorithm using OpenSSL

=head1 SYNOPSIS

    use Crypt::OpenSSL::Blowfish;

    my $cipher = Crypt::OpenSSL::Blowfish->($key, {});

    or (for compatibility.with 0.02 and below)

    my $cipher = Crypt::OpenSSL::Blowfish->($key); # DON'T do this

    my $ciphertext = $cipher->encrypt($plaintext);
    my $plaintext = $cipher->decrypt($ciphertext);

=head1 BLOWFISH IS CONSIDERED LEGACY BY OPENSSL v3

This module has been updated with support for OpenSSL v3 but should
be considered to be end of life.  OpenSSL requires the I<legacy> provider
to be specifically loaded to use Blowfish.  It is a deprecated encryption
module and you B<need> to move to a different encryption algorithm.

=head1 COMPATIBILITY WARNING

B<WARNING> Version 0.02 and below B<DO NOT> produce OpenSSL compatible
encryption or decrypt OpenSSL encrypted messages properly.

Basically, those versions call BF_encrypt and BF_decrypt without properly
converting the input to big endian and the output to little endian where
needed.

Version 0.03 and above correctly calls BF_ecb_encrypt and BF_ecb_decrypt
or the EVP_* functions but I<DEFAULTS> to the B<incorrect> method for
compatibility.  This B<MAY> change in subsequent versions.

To obtain the correct method you B<must> provide a second option in the new
constructor.  Even an empty hash will work and will be compatible with later
versions.

    my $cipher = Crypt::OpenSSL::Blowfish($key, {});

The encryption/decryption method is then compatible with the BF_ecb_encrypt
and BF_ecb_decrypt and well as the new EVP_ methods using B<EVP_bf_ecb> cipher
when compiled with openssl v3.

=head1 DESCRIPTION

Crypt::OpenSSL::Blowfish implements the Blowfish Algorithm using functions
contained in the OpenSSL crypto library.  Crypt::OpenSSL::Blowfish has an
interface similar to Crypt::Blowfish, but produces different result than
Crypt::Blowfish. This is no longer correct if you use the new method to
instantiate Crypt::OpenSSL::Blowfish.  Using the new method results in
encryption which is compatible with Crypt::Blowfish.

=head1 METHODS

=head2 new($key, ... )

    # New method - openssl compatible
    my $cipher = Crypt::OpenSSL::Blowfish->new($key, {});

    # Old method - NOT openssl compatible
    my $cipher = Crypt::OpenSSL::Blowfish->new($key);

=head2 encrypt(data)

    my $encrypted = $cipher->encrypt($plaintext);

=head2 encrypt(data)

    my $decrypted = $cipher->decrypt($ciphertext);

=head2 get_little_endian(data)

Converts the data to little-endian format. Required to convert the old
encryption to openssl compatible bf-ecb/EVP_bf_ecb.

See t/upgrade.t for examples to handle the endian conversion and encryption
upgrades.

    my $leval = get_little_endian(data)

=head2 get_big_endian(data)

Converts the data to little-endian format. Required to convert the old
encryption to openssl compatible bf-ecb/EVP_bf_ecb

See t/upgrade.t for examples to handle the endian conversion and encryption
upgrades.

    my $beval = get_big_endian(data)

=head1 SEE ALSO

L<Crypt::Blowfish>

http://www.openssl.org/

=head1 AUTHOR

Vitaly Kramskikh, E<lt>vkramskih@cpan.orgE<gt>
Timothy Legge, E<lt>timlegge@cpan.orgE<gt>

=head1 LICENSE

No license was mentioned in the original version 0.01 or 0.02. Based
on the changes made by TIMLEGGE, 0.03 and forward will be as follows:

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself, either Perl version 5.8.5 or,
at your option, any later version of Perl 5 you may have available.

In the unlikely chance that that is an issue for anyone feel free to
contact TIMLEGGE

=cut
