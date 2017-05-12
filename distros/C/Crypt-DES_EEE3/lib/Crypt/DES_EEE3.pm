
package Crypt::DES_EEE3;
use strict;

use Crypt::DES;
use Crypt::DES_EDE3;
use vars qw( $VERSION @ISA );
$VERSION = '0.01';
@ISA= qw(Crypt::DES_EDE3);

sub encrypt {
    my($ede3, $block) = @_;
    $ede3->{des3}->encrypt(
        $ede3->{des2}->encrypt(
            $ede3->{des1}->encrypt($block)
        )
    );
}

sub decrypt {
    my($ede3, $block) = @_;
    $ede3->{des1}->decrypt(
        $ede3->{des2}->decrypt(
            $ede3->{des3}->decrypt($block)
        )
    );
}

1;
__END__

=head1 NAME

Crypt::DES_EEE3 - Triple-DES EEE encryption/decryption

=head1 SYNOPSIS

    use Crypt::DES_EEE3;
    my $ede3 = Crypt::DES_EEE3->new($key);
    $ede3->encrypt($block);

=head1 DESCRIPTION

I<Crypt::DES_EEE3> implements DES-EEE3 encryption. This is triple-DES
encryption where an encrypt operation is encrypt-encrypt-encrypt, and
decrypt is decrypt-decrypt-decrypt. This implementation uses I<Crypt::DES>
to do its dirty DES work, and simply provides a wrapper around that
module: setting up the individual DES ciphers, initializing the keys,
and performing the encryption/decryption steps.

DES-EEE3 encryption requires a key size of 24 bytes.

You're probably best off not using this module directly, as the I<encrypt>
and I<decrypt> methods expect 8-octet blocks. You might want to use the
module in conjunction with I<Crypt::CBC>, for example. This would be
DES-EEE3-CBC, or triple-DES in outer CBC mode.

=head1 USAGE

=head2 $ede3 = Crypt::DES_EEE3->new($key)

Creates a new I<Crypt::DES_EEE3> object (really, a collection of three DES
ciphers), and initializes each cipher with part of I<$key>, which should be
at least 24 bytes. If it's longer than 24 bytes, the extra bytes will be
ignored.

Returns the new object.

=head2 $ede3->encrypt($block)

Encrypts an 8-byte block of data I<$block> using the three DES ciphers in
an encrypt-decrypt-encrypt operation.

Returns the encrypted block.

=head2 $ede3->decrypt($block)

Decrypts an 8-byte block of data I<$block> using the three DES ciphers in
a decrypt-encrypt-decrypt operation.

Returns the decrypted block.

=head2 $ede3->blocksize

Returns the block size (8).

=head2 $ede3->keysize

Returns the key size (24).

=head1 LICENSE

Crypt::DES_EEE3 is free software; you may redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR & COPYRIGHTS

Copyright 2003 by Kang-min Liu <gugod@gugod.org>.

This program is free software; you can redistribute it and/or
modify it under the same terms as Perl itself.

See <http://www.perl.com/perl/misc/Artistic.html>

Thanks to the previous work of Crypt::DES_EDE3 by Benjamin Troot
<ben@rhumba.pair.com>

=cut
