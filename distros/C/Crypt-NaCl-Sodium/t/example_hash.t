
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );

my $crypto_hash = Crypt::NaCl::Sodium->hash();

# list of files for which we are computing the checksums
my @files = qw( t/sodium_sign.dat );

## SHA-256
########

for my $file ( @files ) {
    # file name checksum
    my $filename_hash = $crypto_hash->sha256($file);
    is($filename_hash->to_hex,
        "ad19ccecc8d9ca8d23b8ae8fff8a4d11309451475c9b3ca4d6941d3740b87353",
        "single-part");

    # using multi-part API
    my $stream = $crypto_hash->sha256_init();

    open(my $fh, $file) or die;
    while ( sysread($fh, my $buf, 4096) ) {
        # add the chunk of data
        $stream->update( $buf );
    }
    close($fh);

    # calculate the final checksum
    my $checksum = $stream->final();
    is($checksum->to_hex,
        "e56ce76f677a376aca6fecdf804bafd8195405f099603815de3c12f079e5e3c7",
        "multi-part");
}

## SHA-512
########

for my $file ( @files ) {
    # file name checksum
    my $filename_hash = $crypto_hash->sha512($file);
    is($filename_hash->to_hex,
        "3cc651b3b064eb798a72f7238e74ab30752cc9b6706e283372a5e388c2a6b27f30cb396df2ddfb282f4be917f56b9a9506f2f24f87b4fbd8189f1cafbc3fc46e",
        "single-part");

    # using multi-part API
    my $stream = $crypto_hash->sha512_init();

    open(my $fh, $file) or die;
    while ( sysread($fh, my $buf, 4096) ) {
        # add the chunk of data
        $stream->update( $buf );
    }
    close($fh);

    # calculate the final checksum
    my $checksum = $stream->final();
    is($checksum->to_hex,
        "a922ad26904d9e34f1dd686c49c95c94e1b37b11f44bd974bf4e131f5d6a280d37b4c55aa64f57fd60625925058ddacf82efb225452c4829bfd3478cb3c498bf",
        "multi-part");
}

done_testing();

