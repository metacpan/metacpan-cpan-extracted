package Crypt::TEA_XS;

# ABSTRACT: Implementation of the Tiny Encryption Algorithm

use strict;
use warnings;
use utf8;

use Carp;
use List::Util qw(all);
use Scalar::Util::Numeric qw(isint);

our $VERSION = '0.01'; # VERSION

require XSLoader;
XSLoader::load('Crypt::TEA_XS', $VERSION);



my $ROUNDS = 32;
my $KEY_SIZE = 16;
my $ELEMENTS_IN_KEY = $KEY_SIZE / 4;
my $BLOCK_SIZE = 8;
my $ELEMENTS_IN_BLOCK = $BLOCK_SIZE / 4;


use constant keysize => $KEY_SIZE;


use constant blocksize => $BLOCK_SIZE;


sub new {
    my $class = shift;
    my $key = shift;
    my $rounds = shift // $ROUNDS;
    my $tea_key;

    croak( 'key is required' ) if not defined $key;

    if ( my $ref_of_key = ref( $key ) ) {

        croak( sprintf( 'key must be a %d-byte-long STRING or a reference of ARRAY', $KEY_SIZE ) ) if not $ref_of_key eq 'ARRAY';
        croak( sprintf( 'key must has %d elements if key is a reference of ARRAY', $ELEMENTS_IN_KEY ) ) if scalar( @{ $key } ) != $ELEMENTS_IN_KEY;
        croak( 'each element of key must be a 32bit Integer if key is a reference of ARRAY' ) if not all { isint( $_ ) != 0 } @{ $key };

        $tea_key = $key;

    } else {

        croak( sprintf( 'key must be a %d-byte-long STRING or a reference of ARRAY', $KEY_SIZE ) ) if length $key != $KEY_SIZE;

        $tea_key = key_setup($key);

    }

    croak( 'rounds must be a positive NUMBER' ) if isint( $rounds ) != 1;

    my $self = {
        key => $tea_key,
        rounds => $rounds,
    };
    bless $self, ref($class) || $class;
}


sub encrypt {
    my $self = shift;
    my $plain_text = shift;
    croak( sprintf( 'plain_text size must be %d bytes', $BLOCK_SIZE) ) if length($plain_text) != $BLOCK_SIZE;
    my @block = unpack 'N*', $plain_text;
    my $cipher_text_ref = $self->encrypt_block( \@block );
    return pack( 'N*', @{$cipher_text_ref} );
}


sub decrypt {
    my $self = shift;
    my $cipher_text = shift;
    croak( sprintf( 'cipher_text size must be %d bytes', $BLOCK_SIZE) ) if length($cipher_text) != $BLOCK_SIZE;
    my @block = unpack 'N*', $cipher_text;
    my $plain_text_ref = $self->decrypt_block( \@block );
    return pack( 'N*', @{$plain_text_ref} );
}

sub encrypt_block {
    my $self = shift;
    my $block_ref = shift;
    my $key_ref = $self->{key};

    croak( sprintf( 'block must has %d elements', $ELEMENTS_IN_BLOCK ) ) if scalar( @{ $block_ref } ) != $ELEMENTS_IN_BLOCK;
    croak( sprintf( 'key must has %d elements', $ELEMENTS_IN_KEY ) ) if scalar( @{ $key_ref } ) != $ELEMENTS_IN_KEY;

    return $self->encrypt_block_in_c( $block_ref );
}

sub decrypt_block {
    my $self = shift;
    my $block_ref = shift;
    my $key_ref = $self->{key};

    croak( sprintf( 'block must has %d elements', $ELEMENTS_IN_BLOCK ) ) if scalar( @{ $block_ref } ) != $ELEMENTS_IN_BLOCK;
    croak( sprintf( 'key must has %d elements', $ELEMENTS_IN_KEY ) ) if scalar( @{ $key_ref } ) != $ELEMENTS_IN_KEY;

    return $self->decrypt_block_in_c( $block_ref );
}

sub key_setup {
    my $key_str = shift;
    croak( sprintf( 'key must be %s bytes long', $KEY_SIZE ) ) if length( $key_str ) != $KEY_SIZE;
    my @xtea_key = unpack 'N*', $key_str;
    return \@xtea_key;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::TEA_XS - Implementation of the Tiny Encryption Algorithm

=head1 VERSION

version 0.01

=head1 SYNOPSIS

   use Crypt::TEA_XS;
   use Crypt::CBC;

   my $tea = Crypt::TEA_XS->new( $key );
   my $cbc = Crypt::CBC->new( -cipher => $tea );

   my $text = 'The quick brown fox jumps over the lazy dog.';
   my $cipher_text = $cbc->encrypt( $text );

   my $plain_text = $cbc->decrypt( $cipher_text );

=head1 DESCRIPTION

TEA is a 64-bit symmetric block cipher with a 128-bit key and a variable number of rounds (32 is recommended).
It has a low setup time, and depends on a large number of rounds for security, rather than a complex algorithm.
It was developed by David J. Wheeler and Roger M. Needham,
and is described at L<http://www.ftp.cl.cam.ac.uk/ftp/papers/djw-rmn/djw-rmn-tea.html>

This module implements TEA encryption. It supports the Crypt::CBC interface, with the following functions.

=head1 METHODS

=head2 keysize

Returns the maximum TEA key size, 16 bytes.

=head2 blocksize

Returns the TEA block size, which is 8 bytes. This function exists so that Crypt::TEA_XS can work with Crypt::CBC.

=head2 new

    my $tea = Crypt::TEA_XS->new( $key, $rounds );

This creates a new Crypt::TEA_XS object with the specified key.
The optional rounds parameter specifies the number of rounds of encryption to perform, and defaults to 32.

=head2 encrypt

    $cipher_text = $tea->encrypt($plain_text);

Encrypts blocksize() bytes of $plain_text and returns the corresponding ciphertext.

=head2 decrypt

    $plain_text = $tea->decrypt($cipher_text);

Decrypts blocksize() bytes of $cipher_text and returns the corresponding plaintext.

=head1 SEE ALSO

L<http://www.vader.brad.ac.uk/tea/tea.shtml>

L<Crypt::CBC>

L<Crypt::TEA_PP>

=head1 AUTHOR

Kars Wang <jahiy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kars Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
