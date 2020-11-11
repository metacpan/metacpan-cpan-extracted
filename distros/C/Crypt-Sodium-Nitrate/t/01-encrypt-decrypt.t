#!perl
use strict;
use warnings;

use Crypt::Sodium::Nitrate;

use Test::More;

sub main {
    ok(Crypt::Sodium::Nitrate::MACBYTES, "MACBYTES works");
    my @nacbytes;
    $nacbytes[0] = Crypt::Sodium::Nitrate::MACBYTES();
    $nacbytes[1] = Crypt::Sodium::Nitrate::MACBYTES;
    $nacbytes[2] = &Crypt::Sodium::Nitrate::MACBYTES;
    $nacbytes[3] = (\&Crypt::Sodium::Nitrate::MACBYTES)->();

    is_deeply(
        \@nacbytes,
        [ (Crypt::Sodium::Nitrate::MACBYTES) x 4 ],
        "Various ways of accessing the constants work"
    );

    my $keylen   = Crypt::Sodium::Nitrate::KEYBYTES();
    my $noncelen = Crypt::Sodium::Nitrate::NONCEBYTES();

    my $key   = "X" x $keylen;
    my $nonce = "N" x $noncelen;

    my $encrypt = Crypt::Sodium::Nitrate::encrypt(
        "plaintext",
        $nonce,
        $key
    );

    ok($encrypt, "Can encrypt");

    my $encrypt_again = Crypt::Sodium::Nitrate::encrypt(
        "plaintext",
        $nonce,
        $key,
    );

    is($encrypt, $encrypt_again, "re-encrypting using the same nonce gives the same cipher text");

    my $decrypted = Crypt::Sodium::Nitrate::decrypt(
        $encrypt,
        $nonce,
        $key
    );

    is($decrypted, "plaintext", "can decrypt what we previously encrypted");
}

main();

done_testing;

