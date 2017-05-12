use strict;
use warnings;
use utf8;

use Test::More;

use_ok( 'Crypt::XTEA' );

my @tests = (
    {
        key        => '1234567890123456',
        plain      => '12345678',
        cipher_hex => 'b6eb8a48d20da116',
        little     => 0,
    },
    {
        key        => '6543210987654321',
        plain      => '87654321',
        cipher_hex => 'a3a1662a20ca50e0',
        little     => 1,
    }
);

for my $test ( @tests ) {
    my $xtea = new_ok( 'Crypt::XTEA' => [ $test->{key}, 32, little_endian => $test->{little} ] );
    my $xtea_be = new_ok( 'Crypt::XTEA' => [ $test->{key}] );

    my $cipher_hex = unpack 'H*', $xtea->encrypt($test->{plain});
    my $cipher_hex_be = unpack 'H*', $xtea_be->encrypt($test->{plain});

    ok (($cipher_hex eq $cipher_hex_be ) != $test->{little}, "testing encryption with optional argument");

    my $plain = $xtea->decrypt( pack( 'H*', $cipher_hex ) );
    my $plain_be = $xtea_be->decrypt( pack( 'H*', $cipher_hex_be ) );

    ok (($cipher_hex eq $cipher_hex_be ) != $test->{little}, "testing decryption optional argument");
}

for my $test ( @tests ) {
    my $xtea = new_ok( 'Crypt::XTEA' => [ $test->{key}, 32, little_endian => $test->{little} ] );
    my $cipher_hex = unpack 'H*', $xtea->encrypt($test->{plain});
    is( $cipher_hex, $test->{cipher_hex}, 'little_endian encryption test' );
    my $plain = $xtea->decrypt( pack( 'H*', $cipher_hex ) );
    is( $plain, $test->{plain}, 'little_endian decryption test' );
}

done_testing;
