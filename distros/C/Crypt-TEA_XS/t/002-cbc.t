use strict;
use warnings;
use utf8;

use Test::More;

eval { require Crypt::CBC; };

plan skip_all => 'Crypt::CBC not installed' if $@;

use_ok( 'Crypt::TEA_XS' );

my @tests = (
    {
        key           => 'qwertyuiopasdfgh',
        plain         => 'The quick brown fox jumps over the lazy dog.',
        cipher_length => 64,
    },
    {
        key           => 'asdfghjklzxcvbnm',
        plain         => 'Freedom is the freedom to say that two plus two make four.',
        cipher_length => 80,
    }
);

for my $test (@tests) {
    my $tea = new_ok( 'Crypt::TEA_XS' => [ $test->{key} ] );
    my $cbc = new_ok( 'Crypt::CBC' => [ -cipher => $tea ] );

    my $cipher = $cbc->encrypt($test->{plain});
    is( length( $cipher ), $test->{cipher_length}, 'cbc encryption test' );
    my $plain = $cbc->decrypt( $cipher );
    is( $plain, $test->{plain}, 'cbc decryption test' );
}

done_testing;
