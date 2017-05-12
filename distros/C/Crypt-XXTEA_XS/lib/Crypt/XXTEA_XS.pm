package Crypt::XXTEA_XS;

# ABSTRACT: Implementation of Corrected Block Tiny Encryption Algorithm

use strict;
use warnings;
use utf8;

use Carp;
use List::Util qw(all);
use Scalar::Util::Numeric qw(isint);

our $VERSION = '0.0101'; # VERSION

require XSLoader;
XSLoader::load('Crypt::XXTEA_XS', $VERSION);


my $FACTOR = 4;
my $KEY_SIZE = 16;
my $ELEMENTS_IN_KEY = $KEY_SIZE / $FACTOR;
my $MIN_BLOCK_SIZE = 8;
my $MIN_ELEMENTS_IN_BLOCK = $MIN_BLOCK_SIZE / $FACTOR;


use constant keysize => $KEY_SIZE;


use constant blocksize => $MIN_BLOCK_SIZE;


sub new {
    my $class = shift;
    my $key = shift;
    my $xxtea_key;
    croak( 'key is required' ) if not defined $key;
    if ( my $ref_of_key = ref( $key ) ) {
        croak( sprintf( 'key must be a %d-byte-long STRING or a reference of ARRAY', $KEY_SIZE ) ) if not $ref_of_key eq 'ARRAY';
        croak( sprintf( 'key must has %d elements if key is a reference of ARRAY', $ELEMENTS_IN_KEY ) ) if scalar( @{ $key } ) != $ELEMENTS_IN_KEY;
        croak( 'each element of key must be a 32bit Integer if key is a reference of ARRAY' ) if not all { isint( $_ ) != 0 } @{ $key };
        $xxtea_key = $key;
    } else {
        croak( sprintf( 'key must be a %d-byte-long STRING or a reference of ARRAY', $KEY_SIZE ) ) if length $key != $KEY_SIZE;
        $xxtea_key = key_setup($key);
    }
    my $self = {
        key => $xxtea_key,
    };
    bless $self, ref($class) || $class;
}


sub encrypt {
    my $self = shift;
    my $plain_text = shift;

    croak( sprintf( 'plain_text size must be at least %d bytes', $MIN_BLOCK_SIZE) ) if length($plain_text) < $MIN_BLOCK_SIZE;
    croak( sprintf( 'plain_text size must be a multiple of %d bytes', $FACTOR) ) if length($plain_text) % $FACTOR != 0;

    my @block = unpack 'N*', $plain_text;
    my $cipher_text_ref = $self->encrypt_block( \@block );
    return pack( 'N*', @{$cipher_text_ref} );
}


sub decrypt {
    my $self = shift;
    my $cipher_text = shift;

    croak( sprintf( 'cipher_text size must be at least %d bytes', $MIN_BLOCK_SIZE) ) if length($cipher_text) < $MIN_BLOCK_SIZE;
    croak( sprintf( 'cipher_text size must be a multiple of %d bytes', $FACTOR) ) if length($cipher_text) % $FACTOR != 0;

    my @block = unpack 'N*', $cipher_text;
    my $plain_text_ref = $self->decrypt_block( \@block );
    return pack( 'N*', @{$plain_text_ref} );
}

sub encrypt_block {
    my $self = shift;
    my $block_ref = shift;
    my $key_ref = $self->{key};

    croak( sprintf( 'block must has at least %d elements', $MIN_ELEMENTS_IN_BLOCK ) ) if scalar( @{ $block_ref } ) < $MIN_ELEMENTS_IN_BLOCK;
    croak( sprintf( 'key must has %d elements', $ELEMENTS_IN_KEY ) ) if scalar( @{ $key_ref } ) != $ELEMENTS_IN_KEY;

    return $self->encrypt_block_in_c( $block_ref );
}

sub decrypt_block {
    my $self = shift;
    my $block_ref = shift;
    my $key_ref = $self->{key};

    croak( sprintf( 'block must has at least %d elements', $MIN_ELEMENTS_IN_BLOCK ) ) if scalar( @{ $block_ref } ) < $MIN_ELEMENTS_IN_BLOCK;
    croak( sprintf( 'key must has %d elements', $ELEMENTS_IN_KEY ) ) if scalar( @{ $key_ref } ) != $ELEMENTS_IN_KEY;

    return $self->decrypt_block_in_c( $block_ref );
}

sub key_setup {
    my $key_str = shift;
    croak( sprintf( 'key must be %s bytes long', $KEY_SIZE ) ) if length( $key_str ) != $KEY_SIZE;
    my @xxtea_key = unpack 'N*', $key_str;
    return \@xxtea_key;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::XXTEA_XS - Implementation of Corrected Block Tiny Encryption Algorithm

=head1 VERSION

version 0.0101

=head1 SYNOPSIS

   use Crypt::XXTEA_XS;
   use Crypt::CBC;

   my $xxtea = Crypt::XXTEA_XS->new( $key );
   my $cbc = Crypt::CBC->new( -cipher => $xxtea );

   my $text = 'The quick brown fox jumps over the lazy dog.';
   my $cipher_text = $cbc->encrypt( $text );

   my $plain_text = $cbc->decrypt( $cipher_text );

=head1 DESCRIPTION

In cryptography, Corrected Block TEA (often referred to as XXTEA) is a block cipher designed to correct weaknesses in the original Block TEA.
The cipher's designers were Roger Needham and David Wheeler of the Cambridge Computer Laboratory,
and the algorithm was presented in an unpublished technical report in October 1998 (Wheeler and Needham, 1998).
It is not subject to any patents.

Formally speaking, XXTEA is a consistent incomplete source-heavy heterogeneous UFN (unbalanced Feistel network) block cipher.
XXTEA operates on variable-length blocks that are some arbitrary multiple of 32 bits in size (minimum 64 bits).
The number of full cycles depends on the block size, but there are at least six (rising to 32 for small block sizes).

This module implements XXTEA encryption. It supports the Crypt::CBC interface, with the following functions.

=head1 METHODS

=head2 keysize

Returns the maximum XXTEA key size, 16 bytes.

=head2 blocksize

Returns the XXTEA block size, which is 8 bytes. This function exists so that Crypt::XXTEA_XS can work with Crypt::CBC.

=head2 new

    my $xxtea = Crypt::XXTEA_XS->new( $key );

This creates a new Crypt::XXTEA_XS object with the specified key.

=head2 encrypt

    $cipher_text = $xxtea->encrypt($plain_text);

Encrypts blocksize() bytes of $plain_text and returns the corresponding ciphertext.

=head2 decrypt

    $plain_text = $xxtea->decrypt($cipher_text);

Decrypts blocksize() bytes of $cipher_text and returns the corresponding plaintext.

=head1 SEE ALSO

L<Crypt::CBC>

L<Crypt::XXTEA_PP>

=head1 AUTHOR

Kars Wang <jahiy@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kars Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
