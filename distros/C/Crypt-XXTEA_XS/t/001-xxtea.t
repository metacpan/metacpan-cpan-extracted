use strict;
use warnings;
use utf8;

use Test::More;

use_ok( 'Crypt::XXTEA_XS' );

my @tests = (
    {
        key        => '1234567890123456',
        plain      => '12345678',
        cipher_hex => 'c4127c772ac136fb',
    },
    {
        key        => '6543210987654321',
        plain      => '87654321',
        cipher_hex => 'cd1e045493c5449f',
    }
);

for my $test ( @tests ) {
    my $xtea = new_ok( 'Crypt::XXTEA_XS' => [ $test->{key} ] );
    my $cipher_hex = unpack 'H*', $xtea->encrypt($test->{plain});
    is( $cipher_hex, $test->{cipher_hex}, 'encryption test' );
    my $plain = $xtea->decrypt( pack( 'H*', $cipher_hex ) );
    is( $plain, $test->{plain}, 'decryption test' );
}

done_testing;
