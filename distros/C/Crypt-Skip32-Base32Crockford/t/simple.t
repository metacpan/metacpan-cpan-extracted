#!perl
use strict;
use warnings;
use Test::More tests => 4;
use_ok 'Crypt::Skip32::Base32Crockford';

my $key        = pack( 'H20', "112233445566778899AA" );     # Always 10 bytes!
my $cipher     = Crypt::Skip32::Base32Crockford->new($key);
my $number     = 3493209676;
my $plaintext  = pack( "N", $number );
my $ciphertext = $cipher->encrypt($plaintext);
my $cipherhex  = unpack( "H8", $ciphertext );
is( $cipherhex, '6da27100' );

is( $cipher->encrypt_number_b32_crockford($number),   '1PT4W80' );
is( $cipher->decrypt_number_b32_crockford('1PT4W80'), $number );
