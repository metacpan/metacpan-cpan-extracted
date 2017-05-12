
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(:utils);

use Devel::Peek;

my $crypto_auth = Crypt::NaCl::Sodium->auth;
my $crypto_hash = Crypt::NaCl::Sodium->hash;
my $msg = "How do you do?";

ok($crypto_auth->$_ > 0, "$_ > 0")
    for qw( KEYBYTES HMACSHA256_KEYBYTES HMACSHA512_KEYBYTES
    HMACSHA512256_KEYBYTES BYTES HMACSHA256_BYTES HMACSHA512_BYTES
    HMACSHA512256_BYTES );


for my $key_len ( 0 .. 192 ) {
    my $key = $key_len ? random_bytes($key_len) : '';

    my $hasher256 = $crypto_auth->hmacsha256_init($key);
    $hasher256->update( $msg );
    my $hash256 = $hasher256->final();
    ok($hash256, "got hmacsha256 for key len: $key_len");
    ok($crypto_auth->hmacsha256_verify($hash256, $msg, $key), "...and hmacsha256_verify works");

    my $hasher512 = $crypto_auth->hmacsha512_init($key);
    $hasher512->update( $msg );
    my $hash512 = $hasher512->final();
    ok($hash512, "got hmacsha512 for key len: $key_len");
    ok($crypto_auth->hmacsha512_verify($hash512, $msg, $key), "...and hmacsha512_verify works");

    my $hasher512256 = $crypto_auth->hmacsha512256_init($key);
    $hasher512256->update( $msg );
    my $hash512256 = $hasher512256->final();
    ok($hash512256, "got hmacsha512256 for key len: $key_len");
    ok($crypto_auth->hmacsha512256_verify($hash512256, $msg, $key), "...and hmacsha512256_verify works");
}

for ( 1 .. 2 ) {
    my ($key, $key_hex, $mac, $mac_hex);

    $key = $crypto_auth->keygen();
    ok($key, "key generated");
    $key_hex = bin2hex($key);

    $mac = $crypto_auth->mac( $msg, $key );
    $mac_hex = bin2hex($mac);
    ok($mac, "mac generated");

    ok( $crypto_auth->verify( $mac, $msg, $key ), "message verified with mac and key");

    my $key256 = $crypto_auth->hmacsha256_keygen();
    my $hmacsha256 = $crypto_auth->hmacsha256($msg, $key256 );
    my $hasher256_1 = $crypto_auth->hmacsha256_init($key256);
    my $key256x5 = $key256 x 5;
    my $hasher256_2 = $crypto_auth->hmacsha256_init($key256x5);
    for my $c ( split(//, $msg) ) {
        $hasher256_1->update($c);
        $hasher256_2->update($c);
    }
    my $hash256_1 = $hasher256_1->final();
    my $hash256_2 = $hasher256_2->final();
    ok( $crypto_auth->hmacsha256_verify( $hash256_1, $msg, $key256 ),
        "Message 256/1 verified with: ". bin2hex($hash256_1)
    );
    is($hash256_1, $hmacsha256, "...and matched combined mode");

    ok( $crypto_auth->hmacsha256_verify( $hash256_2, $msg, $key256x5 ),
        "Message 256/2 verified with: ". bin2hex($key256x5)
    );

    my $key512 = $crypto_auth->hmacsha512_keygen();
    my $hmacsha512 = $crypto_auth->hmacsha512($msg, $key512 );
    my $hasher512_1 = $crypto_auth->hmacsha512_init($key512);
    my $key512x5 = $key512 x 5;
    my $hasher512_2 = $crypto_auth->hmacsha512_init($key512x5);
    for my $c ( split(//, $msg) ) {
        $hasher512_1->update($c);
        $hasher512_2->update($c);
    }
    my $hash512_1 = $hasher512_1->final();
    my $hash512_2 = $hasher512_2->final();
    ok( $crypto_auth->hmacsha512_verify( $hash512_1, $msg, $key512 ),
        "Message 512/1 verified with: ". bin2hex($hash512_1)
    );
    is($hash512_1, $hmacsha512, "...and matched combined mode");

    ok( $crypto_auth->hmacsha512_verify( $hash512_2, $msg, $key512x5 ),
        "Message 512/2 verified with: ". bin2hex($key512x5)
    );

    my $key512256 = $crypto_auth->hmacsha512256_keygen();
    my $hmacsha512256 = $crypto_auth->hmacsha512256($msg, $key512256 );
    my $hasher512256_0 = $crypto_auth->hmacsha512256_init($key);
    my $hasher512256_1 = $crypto_auth->hmacsha512256_init($key512256);
    my $key512256x5 = $key512256 x 5;
    my $hasher512256_2 = $crypto_auth->hmacsha512256_init($key512256x5);
    for my $c ( split(//, $msg) ) {
        $hasher512256_0->update($c);
        $hasher512256_1->update($c);
        $hasher512256_2->update($c);
    }
    my $hash512256_0 = $hasher512256_0->final();
    my $hash512256_1 = $hasher512256_1->final();
    my $hash512256_2 = $hasher512256_2->final();

    ok( $crypto_auth->hmacsha512256_verify( $hash512256_0, $msg, $key ),
        "Message 512256/0 verified with: ". bin2hex($hash512256_0)
    );

    ok( $crypto_auth->hmacsha512256_verify( $hash512256_1, $msg, $key512256 ),
        "Message 512256/1 verified with: ". bin2hex($hash512256_1)
    );
    is(bin2hex($hash512256_1), bin2hex($hmacsha512256), "...and matched combined mode");

    ok( $crypto_auth->hmacsha512256_verify( $hash512256_2, $msg, $key512256x5 ),
        "Message 512256/2 verified with: ". bin2hex($key512256x5)
    );
}

done_testing();

