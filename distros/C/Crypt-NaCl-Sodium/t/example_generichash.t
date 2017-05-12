
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw( :utils );

my $crypto_generichash = Crypt::NaCl::Sodium->generichash();

# generate secret key
my $key = '1' x $crypto_generichash->KEYBYTES;

# list of files for which we are computing the checksums
my @files = qw( t/sodium_sign.dat );

for my $file ( @files ) {
    # file name checksum
    my $filename_hash = $crypto_generichash->mac($file, key => $key, bytes => 32 );
    is($filename_hash->to_hex,
        "a1e27f1abbed2d8bcbe93be1d7a996208c6b75214c78368ecd81229ccf64115f", "single-part");

    # using multi-part API
    my $stream = $crypto_generichash->init( key => $key, bytes => 64 );

    open(my $fh, $file);
    while ( sysread($fh, my $buf, 4096) ) {
        # add the chunk of data
        $stream->update( $buf );
    }
    close($fh);

    # calculate the final checksum
    my $checksum = $stream->final();
    is($checksum->to_hex,
        "2c271acd442d13cd54f60946b085375d1689b1f0fce414c195dffe887d8dc4510d412f762a99d1308803f5a6e4addccd16a558070bb5f988555c833fcab5d343",
        "multi-part");
}

done_testing();

