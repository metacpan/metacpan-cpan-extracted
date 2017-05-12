use strict;
use warnings;

package Crypt::TripleDES::CBC;

# PODNAME: Crypt::TripleDES::CBC
# ABSTRACT: Triple DES in CBC mode Pure implementation
#
# This file is part of Crypt-TripleDES-CBC
#
# This software is copyright (c) 2016 by Shantanu Bhadoria.
#
# This is free software; you can redistribute it and/or modify it under
# the same terms as the Perl 5 programming language system itself.
#
our $VERSION = '0.006'; # VERSION

# Dependencies

use Moose;
use 5.010;
use Crypt::DES;


has cipher1 => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_cipher1 {
    my ($self) = @_;
    my $cipher = new Crypt::DES( substr( $self->key, 0, 8 ) );
}


has cipher2 => (
    is         => 'ro',
    lazy_build => 1,
);

sub _build_cipher2 {
    my ($self) = @_;
    my $cipher = new Crypt::DES( substr( $self->key, 8 ) );
}


has key => (
    is       => 'ro',
    required => 1,
);


has iv => (
    is       => 'ro',
    required => 1,
    default  => pack( "H*", "0000000000000000" ),
);


sub encrypt {
    my ( $self, $cleartext ) = @_;
    my $length = length($cleartext);
    my $result = '';
    my $iv     = $self->iv;
    while ( $length > 8 ) {
        my $block = substr( $cleartext, 0, 8 );
        $cleartext = substr( $cleartext, 8 );
        my $ciphertext = $self->_encrypt_3des( $block ^ $iv );
        $result .= $ciphertext;
        $iv     = $ciphertext;
        $length = length($cleartext);
    }
    my $ciphertext = $self->_encrypt_3des( $cleartext ^ $iv );
    $result .= $ciphertext;
    return $result;
}


sub decrypt {
    my ( $self, $ciphertext ) = @_;
    my $length = length($ciphertext);
    my $result = '';
    my $iv     = $self->iv;
    while ( $length > 8 ) {
        my $block = substr( $ciphertext, 0, 8 );
        $ciphertext = substr( $ciphertext, 8 );
        my $cleartext = $self->_decrypt_3des($block);
        $result .= $cleartext ^ $iv;
        $iv     = $block;
        $length = length($ciphertext);
    }
    my $cleartext = $self->_decrypt_3des($ciphertext);
    $result .= $cleartext ^ $iv;
    return $result;
}

sub _encrypt_3des {
    my ( $self, $plaintext ) = @_;
    return $self->cipher1->encrypt(
        $self->cipher2->decrypt( $self->cipher1->encrypt($plaintext) ) );
}

sub _decrypt_3des {
    my ( $self, $ciphertext ) = @_;
    return $self->cipher1->decrypt(
        $self->cipher2->encrypt( $self->cipher1->decrypt($ciphertext) ) );
}

1;

__END__

=pod

=head1 NAME

Crypt::TripleDES::CBC - Triple DES in CBC mode Pure implementation



=begin html

<p>
<img src="https://img.shields.io/badge/perl-5.10+-brightgreen.svg" alt="Requires Perl 5.10+" />
<a href="https://travis-ci.org/shantanubhadoria/perl-Crypt-TripleDES-CBC"><img src="https://api.travis-ci.org/shantanubhadoria/perl-Crypt-TripleDES-CBC.svg?branch=build/master" alt="Travis status" /></a>
<a href="http://matrix.cpantesters.org/?dist=Crypt-TripleDES-CBC%200.006"><img src="https://badgedepot.code301.com/badge/cpantesters/Crypt-TripleDES-CBC/0.006" alt="CPAN Testers result" /></a>
<a href="http://cpants.cpanauthors.org/dist/Crypt-TripleDES-CBC-0.006"><img src="https://badgedepot.code301.com/badge/kwalitee/Crypt-TripleDES-CBC/0.006" alt="Distribution kwalitee" /></a>
<a href="https://gratipay.com/shantanubhadoria"><img src="https://img.shields.io/gratipay/shantanubhadoria.svg" alt="Gratipay" /></a>
</p>

=end html

=head1 VERSION

version 0.006

=head1 SYNOPSIS

   use Crypt::TripleDES::CBC;
 
   my $key = pack("H*"
     , "1234567890123456"
     . "7890123456789012");
   my $iv = pack("H*","0000000000000000");
   my $crypt = Crypt::TripleDES::CBC->new(
     key => $key,
     iv  => $iv,
   );
 
   say unpack("H*",$crypt->encrypt(pack("H*","0ABC0F2241535345631FCE")));            # Output F64F2268BF6185A16DADEFD7378E5CE5
   say unpack("H*",$crypt->decrypt(pack("H*","F64F2268BF6185A16DADEFD7378E5CE5")));  # Output 0ABC0F2241535345631FCE0000000000

=head1 DESCRIPTION

Most Modules on CPAN don't do a standards compliant implementation, while they
are able to decrypt what they encrypt. There are corner cases where certain
blocks of data in a chain don't decrypt properly. This is (almost)a pure perl
implementation of TripleDES in CBC mode using Crypt::DES to encrypt individual
blocks.

=head1 ATTRIBUTES

=head2 cipher1

First Crypt::DES Cipher object generated from the key. This is built
automatically. Do not change this value from your program.

=head2 cipher2

second Crypt::DES Cipher object generated from the key. This is built
automatically. Do not change this value from your program.

=head2 key

Encryption Key this must be ascii packed string as shown in Synopsis.

=head2 iv

Initialization vector, default is a null string.

=head1 METHODS

=head2 encrypt

Encryption Method

=head2 decrypt

Decryption method

=for :stopwords cpan testmatrix url annocpan anno bugtracker rt cpants kwalitee diff irc mailto metadata placeholders metacpan

=head1 SUPPORT

=head2 Bugs / Feature Requests

Please report any bugs or feature requests through github at 
L<https://github.com/shantanubhadoria/perl-crypt-tripledes-cbc/issues>.
You will be notified automatically of any progress on your issue.

=head2 Source Code

This is open source software.  The code repository is available for
public review and contribution under the terms of the license.

L<https://github.com/shantanubhadoria/perl-crypt-tripledes-cbc>

  git clone git://github.com/shantanubhadoria/perl-crypt-tripledes-cbc.git

=head1 AUTHOR

Shantanu Bhadoria <shantanu@cpan.org> L<https://www.shantanubhadoria.com>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2016 by Shantanu Bhadoria.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
