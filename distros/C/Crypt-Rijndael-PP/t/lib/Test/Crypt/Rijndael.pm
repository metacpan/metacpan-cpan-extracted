package Test::Crypt::Rijndael;

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MooseX::Params::Validate;

use Crypt::Rijndael::PP;

use Exporter 'import';
our @EXPORT_OK = qw( test_rijndael_pp_encryption_and_decryption );

sub test_rijndael_pp_encryption_and_decryption {
    my ( %args ) = validated_hash(
        \@_,
        key   => { isa => 'ArrayRef' },
        mode  => { isa => 'Str' },
        iv    => { isa => 'Str', optional => 1 },
        plain_text  => { isa => 'ArrayRef' },
        cipher_text => { isa => 'ArrayRef' },
    );

    my $cipher_text = test_rijndael_pp_encryption( %args );
    my $plain_text  = test_rijndael_pp_decryption( %args );
    return;
}

sub test_rijndael_pp_encryption {
    my ( %args ) = validated_hash(
        \@_,
        key   => { isa => 'ArrayRef' },
        mode  => { isa => 'Str' },
        iv    => { isa => 'Str', optional => 1 },
        plain_text  => { isa => 'ArrayRef' },
        cipher_text => { isa => 'ArrayRef' },
    );

    my $cipher_text;
    subtest 'Encrypt With Crypt::Rijndal::PP' => sub {
        my $packed_key = pack( "C*", @{ $args{key} } );
        my $packed_plain_text  = pack( "C*", @{ $args{plain_text} } );
        my $packed_cipher_text = pack( "C*", @{ $args{cipher_text} } );

        my $mode = eval 'Crypt::Rijndael::PP::' . $args{mode}; ## no critic (ProhibitStringyEval)

        my $cipher;
        lives_ok {
            $cipher = Crypt::Rijndael::PP->new(
                $packed_key, $mode
            );

            if( $args{iv} ) {
                $cipher->set_iv( $args{iv} );
            }
        } 'Lives through construction of Cipher';

        lives_ok {
            $cipher_text = $cipher->encrypt( $packed_plain_text );
        } 'Lives through encryption';

        cmp_ok( unpack( "H*", $cipher_text ), 'eq',
            unpack( "H*", $packed_cipher_text ), "Correct Cipher Text" );
    };

    return $cipher_text;
}

sub test_rijndael_pp_decryption {
    my ( %args ) = validated_hash(
        \@_,
        key   => { isa => 'ArrayRef' },
        mode  => { isa => 'Str' },
        iv    => { isa => 'Str', optional => 1 },
        plain_text  => { isa => 'ArrayRef' },
        cipher_text => { isa => 'ArrayRef' },
    );

    my $plain_text;
    subtest 'Decrypt With Crypt::Rijndal::PP' => sub {
        my $packed_key = pack( "C*", @{ $args{key} } );
        my $packed_plain_text  = pack( "C*", @{ $args{plain_text} } );
        my $packed_cipher_text = pack( "C*", @{ $args{cipher_text} } );

        my $mode = eval 'Crypt::Rijndael::PP::' . $args{mode}; ## no critic (ProhibitStringyEval)

        my $cipher;
        lives_ok {
            $cipher = Crypt::Rijndael::PP->new(
                $packed_key, $mode
            );

            if( $args{iv} ) {
                $cipher->set_iv( $args{iv} );
            }
        } 'Lives through construction of Cipher';

        lives_ok {
            $plain_text = $cipher->decrypt( $packed_cipher_text );
        } 'Lives through decryption';

        cmp_ok( unpack( "H*", $plain_text ), 'eq',
            unpack( "H*", $packed_plain_text ), "Correct Plain Text" );
    };

    return $plain_text;
}
1;
