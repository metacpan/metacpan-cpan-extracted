#!/usr/bin/env perl

use strict;
use warnings;

use Test::More;
use Test::Exception;
use MooseX::Params::Validate;
use String::Random qw( random_string );

use Crypt::Rijndael::PP;

use Readonly;
Readonly my $TEST_VALUES => {
    128 => {
        text => random_string("nnccncncnncncncn"),
        key  => random_string("ccnncncnccncncnc"),
    },
    192 => {
        text => random_string("nnccncncnncncncn"),
        key  => random_string("ccnncncnccncncncnccncncn"),
    },
    256 => {
        text => random_string("nnccncncnncncncn"),
        key  => random_string("ccnncncnccncncncccnncncnccncncnc"),
    },
};

subtest "Full Cycle on Block - 128 Bit Key" => sub {
    test_full_cycle( $TEST_VALUES->{128} );
};

subtest "Full Cycle on Block - 192 Bit Key" => sub {
    test_full_cycle( $TEST_VALUES->{192} );
};

subtest "Full Cycle on Block - 256 Bit Key" => sub {
    test_full_cycle( $TEST_VALUES->{256} );
};

done_testing;

sub test_full_cycle {
    my ( $case ) = pos_validated_list( \@_, { isa => 'HashRef' } );

    my $initial_text = $case->{text};

    my $cipher_text;
    lives_ok {
        $cipher_text = Crypt::Rijndael::PP->encrypt_block(
            $initial_text, $case->{key}
        );
    } "Lives through Encryption";

    my $plain_text;
    lives_ok {
        $plain_text = Crypt::Rijndael::PP->decrypt_block(
            $cipher_text, $case->{key}
        );
    } "Lives through Decryption";

    cmp_ok( $initial_text, 'eq', $plain_text, "Initial Text Matches Decrypted Text" );

    return;
}
