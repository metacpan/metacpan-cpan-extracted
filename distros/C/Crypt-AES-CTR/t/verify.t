#!perl -T
use 5.006;
use strict;
use warnings FATAL => 'all';
use Test::More;

plan tests => 5;


use_ok( 'Crypt::AES::CTR' );



my $string = 'test string';
my $pass = 'pass';
my $enc = Crypt::AES::CTR::encrypt($string, $pass, 256);

cmp_ok(length($enc), '>', 0, 'Encryption test');

my $dec = Crypt::AES::CTR::decrypt($enc, $pass, 256);

is( $dec, $string, 'Decryption match' );


my $c = Crypt::AES::CTR->new(key=>$pass, nbits=>256);
my $enc2 = $c->encrypt($string);
cmp_ok(length($enc2), '>', 0, 'OO Encryption test');

my $dec2 = $c->decrypt($enc2);

is( $dec2, $string, 'OO Decryption match' );
