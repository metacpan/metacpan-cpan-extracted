
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(bin2hex);

my $crypto_onetimeauth = Crypt::NaCl::Sodium->onetimeauth;
my $msg = "Signed by me";

my $key = $crypto_onetimeauth->keygen();
ok($key, "key generated");

my $mac = $crypto_onetimeauth->mac( $msg, $key );
ok($mac, "got mac for msg");

ok( $crypto_onetimeauth->verify( $mac, $msg, $key ), "msg verified");

my $hasher_1 = $crypto_onetimeauth->init($key);
ok($hasher_1, "hasher_1 initialized");
my $hasher_2 = $crypto_onetimeauth->init($key);
ok($hasher_2, "hasher_2 initialized");
for my $c ( split(//, $msg) ) {
    $hasher_1->update($c);
    $hasher_2->update($c);
}
my $hash_1 = $hasher_1->final();
ok($hash_1, "hasher_1 produced final mac");
my $hash_2 = $hasher_2->final();
ok($hash_2, "hasher_2 produced final mac");
is(bin2hex($hash_1), bin2hex($hash_2), "...and both match");

ok( $crypto_onetimeauth->verify( $hash_1, $msg, $key ), "Message /1 verified");
ok( $crypto_onetimeauth->verify( $hash_2, $msg, $key ), "Message /2 verified");

done_testing();

