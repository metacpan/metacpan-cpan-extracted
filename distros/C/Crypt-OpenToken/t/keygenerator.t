#!/usr/bin/perl

use strict;
use warnings;
use if $ENV{AUTOMATED_TESTING}, 'Test::DiagINC'; use MIME::Base64;
use Test2::V0;

use Crypt::OpenToken::KeyGenerator;

###############################################################################
# TEST: generating key from password
#
# Using data collected from the PHP implementation, verify that our Perl
# implementation generates the same results.
generate_key: {
    # test data, as produced by the PingId PHP Integration Kit for OpenToken
    my $keysize  = 16;
    my $password_base64 = 'a66C9MvM8eY4qJKyCXKW+19PWDeuc3th';
    my $expected_base64 = 'K85t+EVxhbr7r9qNCRFTQA==';

    my $password  = decode_base64($password_base64);
    my $generated = Crypt::OpenToken::KeyGenerator::generate(
        $password, $keysize,
    );
    my $generated_base64 = encode_base64($generated, '');
    is $generated_base64, $expected_base64,
        'Generated key matches other implementations';
}

###############################################################################
done_testing();
