package Crypt::XTEA::LE;

# ABSTRACT: Implementation of the eXtended Tiny Encryption Algorithm

use strict;
use warnings;
use utf8;

use Carp;
use List::Util qw(all);
use Scalar::Util::Numeric qw(isint);

our $VERSION = '0.0107'; # VERSION

require XSLoader;
XSLoader::load('Crypt::XTEA::LE', $VERSION);


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
	my %opts = (little_endian => 0, @_);
    my $xtea_key;
    croak( 'key is required' ) if not defined $key;
    if ( my $ref_of_key = ref( $key ) ) {
        croak( sprintf( 'key must be a %d-byte-long STRING or a reference of ARRAY', $KEY_SIZE ) ) if not $ref_of_key eq 'ARRAY';
        croak( sprintf( 'key must has %d elements if key is a reference of ARRAY', $ELEMENTS_IN_KEY ) ) if scalar( @{ $key } ) != $ELEMENTS_IN_KEY;
        croak( 'each element of key must be a 32bit Integer if key is a reference of ARRAY' ) if not all { isint( $_ ) != 0 } @{ $key };
        $xtea_key = $key;
    } else {
        croak( sprintf( 'key must be a %d-byte-long STRING or a reference of ARRAY', $KEY_SIZE ) ) if length $key != $KEY_SIZE;
        $xtea_key = key_setup($key, $opts{little_endian});
    }
    croak( 'rounds must be a positive NUMBER' ) if isint( $rounds ) != 1;
    my $self = {
        key => $xtea_key,
        rounds => $rounds,
		endianness => $opts{little_endian} ? 'V*' : 'N*',
    };
    bless $self, ref($class) || $class;
}


sub encrypt {
    my $self = shift;
    my $plain_text = shift;
    croak( sprintf( 'plain_text block size must be %d bytes', $BLOCK_SIZE) ) if length($plain_text) != $BLOCK_SIZE;
    my @block = unpack $self->{endianness}, $plain_text;
    my $cipher_text_ref = $self->encrypt_block( \@block );
    return pack( $self->{endianness}, @{$cipher_text_ref} );
}


sub decrypt {
    my $self = shift;
    my $cipher_text = shift;
    croak( sprintf( 'cipher_text size must be %d bytes', $BLOCK_SIZE) ) if length($cipher_text) != $BLOCK_SIZE;
    my @block = unpack $self->{endianness}, $cipher_text;
    my $plain_text_ref = $self->decrypt_block( \@block );
    return pack( $self->{endianness}, @{$plain_text_ref} );
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
	my $endianness = (shift) ? 'V*' : 'N*';
    croak( sprintf( 'key must be %s bytes long', $KEY_SIZE ) ) if length( $key_str ) != $KEY_SIZE;
    my @xtea_key = unpack "$endianness", $key_str;
    return \@xtea_key;
}


1;

__END__

=pod

=encoding UTF-8

=head1 NAME

Crypt::XTEA::LE - Implementation of the eXtended Tiny Encryption Algorithm with little-endian support

=head1 VERSION

version 0.0107

=head1 SYNOPSIS

   use Crypt::XTEA:LE;
   use Crypt::CBC;

   my $xtea = Crypt::XTEA:LE->new( $key, 32, little_endian => 1 );
   my $cbc = Crypt::CBC->new( -cipher => $xtea );

   my $text = 'The quick brown fox jumps over the lazy dog.';
   my $cipher_text = $cbc->encrypt( $text );

   my $plain_text = $cbc->decrypt( $cipher_text );

=head1 DESCRIPTION

In cryptography, XTEA (eXtended TEA) is a block cipher designed to correct weaknesses in TEA.
The cipher's designers were David Wheeler and Roger Needham of the Cambridge Computer Laboratory,
and the algorithm was presented in an unpublished technical report in 1997 (Needham and Wheeler, 1997).
It is not subject to any patents.

Like TEA, XTEA is a 64-bit block Feistel cipher with a 128-bit key and a suggested 64 Feistel rounds (i.e 32 cycles).
Crypt::XTEA::LE, uses the recommended value of 32 by default.

This module implements XTEA encryption. It supports the Crypt::CBC interface, with the following functions.

=head1 METHODS

=head2 keysize

Returns the maximum XTEA key size, 16 bytes.

=head2 blocksize

Returns the XTEA::LE block size, which is 8 bytes. This function exists so that Crypt::XTEA:LE can work with Crypt::CBC.

=head2 new

    my $xtea = Crypt::XTEA::LE->new( $key, $rounds, little_endian => 0 );

This creates a new Crypt::XTEA::LE object with the specified key.
The optional rounds parameter specifies the number of rounds of encryption to perform, and defaults to 32.
If the key is provided as a scalar string, it is split to a series of 4x big-endian 32-bit integers. If little-endian order is required instead, the optional little_endian key can be set to 1.

=head2 encrypt

    $cipher_text = $xtea->encrypt($plain_text);

Encrypts blocksize() bytes of $plain_text and returns the corresponding ciphertext.
By default, the block is interpreted as 2x big-endian 32-bit integers. if little_endian => 1 was specified during new(), the block will be split into two little-endian integers instead.

=head2 decrypt

    $plain_text = $xtea->decrypt($cipher_text);

Decrypts blocksize() bytes of $cipher_text and returns the corresponding plaintext.
By default, the block is interpreted as 2x big-endian 32-bit integers. if little_endian => 1 was specified during new(), the block will be split into two little-endian integers instead.

=head1 SEE ALSO

Based on L<Crypt::XTEA>

L<Crypt::CBC>

L<Crypt::XTEA_PP>

=head1 AUTHOR

Kars Wang <jahiy@cpan.org>
Ahmad Fatoum <athreef@cpan.org>

=head1 COPYRIGHT AND LICENSE

This software is copyright (c) 2015 by Kars Wang.

This is free software; you can redistribute it and/or modify it under
the same terms as the Perl 5 programming language system itself.

=cut
