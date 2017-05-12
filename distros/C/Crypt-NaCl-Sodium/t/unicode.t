
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );

my $crypto_hash = Crypt::NaCl::Sodium->hash();

my $word = "ążś";

use Devel::Peek;

{
    ## SHA-256
    ########

    my $sha256 = $crypto_hash->sha256($word);
    is($sha256->to_hex,
        "a74d188384ac9ed9dd68e6f39b8d765baf0c4c2eb5e6f0314f52c98cc88e70e7",
        "sha256 - single-part");

    # using multi-part API
    my $stream = $crypto_hash->sha256_init();

    $stream->update( $word );

    # calculate the final checksum
    my $checksum = $stream->final();
    is($checksum->to_hex,
        "a74d188384ac9ed9dd68e6f39b8d765baf0c4c2eb5e6f0314f52c98cc88e70e7",
        "sha256 - multi-part");
}

{
    ## SHA-512
    ########

    my $sha512 = $crypto_hash->sha512($word);
    is($sha512->to_hex,
        "87e6879973a050b0569454c2d31f705363f68eada10b92a38e135013a0e90454197e2e52c444cd63ccda331c6ce145dec151cb92642e6064125b5c6e61afe8eb",
        "sha512 - single-part");

    # using multi-part API
    my $stream = $crypto_hash->sha512_init();

    $stream->update( $word );

    # calculate the final checksum
    my $checksum = $stream->final();
    is($checksum->to_hex,
        "87e6879973a050b0569454c2d31f705363f68eada10b92a38e135013a0e90454197e2e52c444cd63ccda331c6ce145dec151cb92642e6064125b5c6e61afe8eb",
        "sha512 - multi-part");
}

done_testing();

