
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(bin2hex);

my $crypto_hash = Crypt::NaCl::Sodium->hash;

my @adatas = (
    "Parcel was dispatched",
    "Hello World!",
);

ok( $crypto_hash->$_ > 0, "$_ > 0") for qw( SHA256_BYTES SHA512_BYTES );

for my $msg ( @adatas ) {
    my ($mac);

    $mac = $crypto_hash->sha256( $msg );
    ok($mac, "sha256 mac for msg");

    $mac = $crypto_hash->sha512( $msg );
    ok($mac, "sha512 mac for msg");

    my $m256 = $crypto_hash->sha256_init();
    ok($m256, "m256 initialized");
    my $m512 = $crypto_hash->sha512_init();
    ok($m512, "m512 initialized");
    for my $c ( split(//, $msg) ) {
        $m256->update($c);
        $m512->update($c);
    }
    my $h256 = $m256->final();
    ok($h256, "m256 produced final hash");
    my $h512 = $m512->final();
    ok($h512, "m512 produced final hash");

    ok(length($h256) < length($h512), "...and sha256 produces hash shorter then sha512");
}

done_testing();
