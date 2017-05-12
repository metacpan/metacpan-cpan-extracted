#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MooseX::Params::Validate;

use FindBin;
use lib "$FindBin::Bin/../../../t/lib/";
use Test::Crypt::Rijndael::Constant qw(
    $INPUT_BLOCKS
    $KEY_256_BIT
);


use Crypt::CBC;
use Crypt::Rijndael;
use Crypt::Rijndael::PP;

use Readonly;

Readonly my $DEFAULT_IV  => 'a' x 16;
Readonly my $CIPHER_TEXT => {
    1 => [ 0xc8, 0x30, 0x5a, 0xff, 0xaa, 0xef, 0x80, 0x30, 0x11, 0xe8, 0xab, 0x78, 0xb3, 0x29, 0xa3, 0x8d,
           0xb8, 0xfd, 0x32, 0xe2, 0x80, 0x34, 0xc6, 0xd7, 0x15, 0xb2, 0x52, 0x42, 0xb5, 0x3a, 0xae, 0x8f ],
    2 => [ 0xc8, 0x30, 0x5a, 0xff, 0xaa, 0xef, 0x80, 0x30, 0x11, 0xe8, 0xab, 0x78, 0xb3, 0x29, 0xa3, 0x8d,
           0x5d, 0x7c, 0x5b, 0xe0, 0x3c, 0xea, 0x60, 0xc1, 0x42, 0x5c, 0x6d, 0x5c, 0x9c, 0x76, 0x55, 0xec,
           0xef, 0xf1, 0x58, 0x22, 0x25, 0x5a, 0x75, 0x71, 0xdf, 0x90, 0xf9, 0x6a, 0x35, 0xb4, 0xe8, 0x32 ],
    3 => [ 0xc8, 0x30, 0x5a, 0xff, 0xaa, 0xef, 0x80, 0x30, 0x11, 0xe8, 0xab, 0x78, 0xb3, 0x29, 0xa3, 0x8d,
           0x5d, 0x7c, 0x5b, 0xe0, 0x3c, 0xea, 0x60, 0xc1, 0x42, 0x5c, 0x6d, 0x5c, 0x9c, 0x76, 0x55, 0xec,
           0x0d, 0xee, 0xd7, 0x56, 0xd6, 0x36, 0x7b, 0xc8, 0xe2, 0x4c, 0x29, 0xce, 0xd8, 0x84, 0x2d, 0x32,
           0x04, 0xc5, 0xf9, 0xdf, 0x88, 0x43, 0xed, 0xa5, 0xb3, 0x77, 0xb2, 0x7b, 0x0d, 0x7e, 0x43, 0x79 ],
};

subtest "Encryption with 256 Bit Key" => sub {
    for my $num_blocks ( 1, 2, 3 ) {
        subtest $num_blocks . " blocks" => sub {
            test_cbc_encryption_and_decryption(
                cipher => 'Rijndael',
                key    => $KEY_256_BIT,
                iv     => $DEFAULT_IV,
                plain_text  => $INPUT_BLOCKS->{$num_blocks},
                cipher_text => $CIPHER_TEXT->{$num_blocks},
            );

            test_cbc_encryption_and_decryption(
                cipher => 'Rijndael::PP',
                key    => $KEY_256_BIT,
                iv     => $DEFAULT_IV,
                plain_text  => $INPUT_BLOCKS->{$num_blocks},
                cipher_text => $CIPHER_TEXT->{$num_blocks},
            );
        };
    }
};

done_testing;

sub test_cbc_encryption_and_decryption {
    my ( %args ) = validated_hash(
        \@_,
        cipher => { isa => 'Str' },
        key    => { isa => 'ArrayRef' },
        iv     => { isa => 'Str' },
        plain_text  => { isa => 'ArrayRef' },
        cipher_text => { isa => 'ArrayRef' },
    );

    my $cipher_text = test_cbc_encryption( %args );
    my $plain_text  = test_cbc_decryption( %args );

    return;
}

sub test_cbc_encryption {
    my ( %args ) = validated_hash(
        \@_,
        cipher => { isa => 'Str' },
        key    => { isa => 'ArrayRef' },
        iv     => { isa => 'Str' },
        plain_text  => { isa => 'ArrayRef' },
        cipher_text => { isa => 'ArrayRef' },
    );

    my $packed_key  = pack( "C*", @{ $args{key} } );
    my $packed_plain_text  = pack( "C*", @{ $args{plain_text} } );
    my $packed_cipher_text = pack( "C*", @{ $args{cipher_text} } );

    subtest 'Encrypt with Crypt::CBC - ' . $args{cipher} => sub {
        my $cipher;
        lives_ok {
            $cipher = Crypt::CBC->new(
                -key    => $packed_key,
                -cipher => $args{cipher},
                -iv     => $args{iv},
                -header => 'none',
                -literal_key => 1,
            );

        } "Lives through Crypt::CBC Object Creation";

        my $cipher_text;
        lives_ok {
            $cipher_text = $cipher->encrypt( $packed_plain_text );
        } "Lives through encryption";

        cmp_ok( unpack( "H*", $cipher_text ), 'eq',
            unpack( "H*", $packed_cipher_text ), "Correct Cipher Text" );
    };

    return;
}

sub test_cbc_decryption {
    my ( %args ) = validated_hash(
        \@_,
        cipher => { isa => 'Str' },
        key    => { isa => 'ArrayRef' },
        iv     => { isa => 'Str' },
        plain_text  => { isa => 'ArrayRef' },
        cipher_text => { isa => 'ArrayRef' },
    );

    my $packed_key  = pack( "C*", @{ $args{key} } );
    my $packed_plain_text  = pack( "C*", @{ $args{plain_text} } );
    my $packed_cipher_text = pack( "C*", @{ $args{cipher_text} } );

    subtest 'Decrypt with Crypt::CBC - ' . $args{cipher} => sub {
        my $cipher;
        lives_ok {
            $cipher = Crypt::CBC->new(
                -key    => $packed_key,
                -cipher => $args{cipher},
                -iv     => $args{iv},
                -header => 'none',
                -literal_key => 1,
            );

        } "Lives through Crypt::CBC Object Creation";

        my $plain_text;
        lives_ok {
            $plain_text = $cipher->decrypt( $packed_cipher_text );
        } "Lives through decryption";

        cmp_ok( unpack( "H*", $plain_text ), 'eq',
            unpack( "H*", $packed_plain_text ), "Correct Plain Text" );
    };

    return;
}

=cut
sub test_encryption {
    my ( $case ) = pos_validated_list( \@_, { isa => 'HashRef' } );

    my $packed_input       = pack( "C*", @{ $case->{input} } );
    my $packed_cipher_key  = pack( "C*", @{ $case->{key} } );
    my $packed_expected_cipher_text = pack( "C*", @{ $case->{cipher_text} } );

    my $cipher;
    lives_ok {

        $cipher = Crypt::CBC->new(
            -key    => $packed_cipher_key,
            -cipher => 'Rijndael::PP',
            -iv     => $DEFAULT_IV,
            -header => 'none',
        );
    } "Lives through Crypt::CBC Object Creation";

    my $cipher_text;
    lives_ok {
        $cipher_text = $cipher->encrypt( $packed_input );
    } "Lives through encryption";

    cmp_ok( unpack( "H*", $cipher_text ), 'eq',
        unpack( "H*", $packed_expected_cipher_text ), "Correct Cipher Text" );

    return;
}
=cut
