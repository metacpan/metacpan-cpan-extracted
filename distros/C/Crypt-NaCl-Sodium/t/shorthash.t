
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(bin2hex);

my $crypto_shorthash = Crypt::NaCl::Sodium->shorthash;
my @adatas = (
    "Parcel was dispatched",
    "",
);

ok($crypto_shorthash->$_ > 0, "$_ > 0") for qw( BYTES KEYBYTES );

for my $msg ( @adatas ) {
    my ($key, $key_hex, $mac);

    $key = $crypto_shorthash->keygen();
    ok($key, "key generated");

    $mac = $crypto_shorthash->mac( $msg, $key );
    ok($mac, "mac calculated");
}

done_testing();
