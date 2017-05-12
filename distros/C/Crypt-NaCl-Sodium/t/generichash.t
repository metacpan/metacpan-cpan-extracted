
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(bin2hex);

my $crypto_generichash = Crypt::NaCl::Sodium->generichash;

my $msg = join('', 'a' .. 'z');

for my $bytes ( $crypto_generichash->BYTES_MIN .. $crypto_generichash->BYTES_MAX ) {
    next unless $bytes % 4 == 0;
    for my $fbytes ( $crypto_generichash->BYTES_MIN .. $crypto_generichash->BYTES_MAX ) {
        next unless $fbytes % 4 == 0;

        my $mac = $crypto_generichash->mac($msg, bytes => $fbytes );

        # without key
        my $hasher1 = $crypto_generichash->init( bytes => $bytes );
        ok($hasher1, "hasher1 without key with $bytes bytes initialized");
        my $hasher2 = $crypto_generichash->init( bytes => $bytes );
        ok($hasher2, "hasher2 without key with $bytes bytes initialized");
        for my $c ( split(//, $msg) ) {
            $hasher1->update($c);
            $hasher2->update($c);
        }
        my $hash1 = $hasher1->final( bytes => $fbytes );
        ok($hash1, "hasher1 produced final mac");

        if ( $bytes == $fbytes ) {
            is($hash1->to_hex, $mac->to_hex,
                "...and stream API produced the same final mac when initial bytes match the final bytes $fbytes");
        } else {
            isnt($hash1->to_hex, $mac->to_hex,
                "...and stream API produced different final mac when initial bytes $bytes do not match the final bytes $fbytes");
        }
        is(length($hash1), $fbytes, "...and of correct length of $fbytes bytes");
        my $hash2 = $hasher2->final( bytes => $fbytes );
        ok($hash2, "hasher2 produced final mac");
        is(length($hash2), $fbytes, "...and of correct length of $fbytes bytes");

        is(bin2hex($hash1), bin2hex($hash2), "...and both match");

    }

    # with key
    for my $keybytes ( $crypto_generichash->KEYBYTES_MIN ..  $crypto_generichash->KEYBYTES_MAX ) {
        next unless $keybytes % 4 == 0;

        my $key = $crypto_generichash->keygen( $keybytes );
        ok($key, "key generated");
        is(length($key), $keybytes, "...and of correct length of $keybytes bytes");

        for my $fbytes ( $crypto_generichash->BYTES_MIN .. $crypto_generichash->BYTES_MAX ) {
            next unless $fbytes % 4 == 0;

            my $hasher1 = $crypto_generichash->init( bytes => $bytes, key => $key );
            ok($hasher1, "hasher1 with key with $bytes bytes initialized");
            my $hasher2 = $crypto_generichash->init( bytes => $bytes, key => $key );
            ok($hasher2, "hasher2 with key with $bytes bytes initialized");

            my $mac = $crypto_generichash->mac($msg, bytes => $fbytes, key => $key );

            for my $c ( split(//, $msg) ) {
                $hasher1->update($c);
                $hasher2->update($c);
            }
            my $hash1 = $hasher1->final( bytes => $fbytes );
            ok($hash1, "hasher1 produced final mac");
            is(length($hash1), $fbytes, "...and of correct length of $fbytes bytes");

            if ( $bytes == $fbytes ) {
                is($hash1->to_hex, $mac->to_hex,
                    "...and stream API produced the same final mac when initial bytes match the final bytes $fbytes");
            } else {
                isnt($hash1->to_hex, $mac->to_hex,
                    "...and stream API produced different final mac when initial bytes $bytes do not match the final bytes $fbytes");
            }

            my $hash2 = $hasher2->final( bytes => $fbytes );
            ok($hash2, "hasher2 produced final mac");
            is(length($hash2), $fbytes, "...and of correct length of $fbytes bytes");
            is(bin2hex($hash1), bin2hex($hash2), "...and both match");
        }
    }
}

done_testing();

