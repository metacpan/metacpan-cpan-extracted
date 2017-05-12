#!/usr/bin/env perl

use strict;
use warnings;

use Crypt::Rijndael::PP;
use Crypt::CBC;

my $key   = 'A' x 32;
my $input = 'B' x 16;

test_cbc();

print "\n";

test_pp();

sub test_cbc {
    my $cipher = Crypt::CBC->new(
        -key    => $key,
        -cipher => 'Rijndael::PP',
    );

    my $cipher_text = $cipher->encrypt( $input );
    my $plain_text  = $cipher->decrypt( $cipher_text );

    print "Input       : " . $input . "\n";
    print "Cipher Text : " . unpack( 'H*', $cipher_text ) . "\n";
    print "Plain Text  : " . $plain_text . "\n";
}

sub test_pp {
    my $cipher = Crypt::Rijndael::PP->new(
        $key, Crypt::Rijndael::PP::MODE_CBC()
    );

    my $cipher_text = $cipher->encrypt( $input );
    my $plain_text  = $cipher->decrypt( $cipher_text );

    print "Input       : " . $input . "\n";
    print "Cipher Text : " . unpack( 'H*', $cipher_text ) . "\n";
    print "Plain Text  : " . $plain_text . "\n";
}
