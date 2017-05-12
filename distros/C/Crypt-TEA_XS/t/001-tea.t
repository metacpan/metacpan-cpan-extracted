use strict;
use warnings;
use utf8;

use Test::More;

use_ok( 'Crypt::TEA_XS' );

my @tests = (
    {
        key        => '1234567890123456',
        plain      => '12345678',
        cipher_hex => '53bf1033105f53e5',
    },
    {
        key        => '6543210987654321',
        plain      => '87654321',
        cipher_hex => '54ef46a8e94d68a4',
    }
);

for my $test ( @tests ) {
    my $tea = new_ok( 'Crypt::TEA_XS' => [ $test->{key} ] );
    my $cipher_hex = unpack 'H*', $tea->encrypt($test->{plain});
    is( $cipher_hex, $test->{cipher_hex}, 'encryption test' );
    my $plain = $tea->decrypt( pack( 'H*', $cipher_hex ) );
    is( $plain, $test->{plain}, 'decryption test' );
}

done_testing;
