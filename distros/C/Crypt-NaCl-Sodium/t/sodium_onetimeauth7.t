
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(:utils);

my $crypto_onetimeauth = Crypt::NaCl::Sodium->onetimeauth();

my $LENGTH = 10_000;

for (my $clen = 0; $clen < $LENGTH; ++$clen) {
    my $key = $crypto_onetimeauth->keygen();
    my $rmsg = $clen ? random_bytes($clen) : '';
    my $s_rmsg = "$rmsg"; # from byteslocker

    my $mac = $crypto_onetimeauth->mac( $rmsg, $key );
    my $s_hash = "$mac"; # from byteslocker

    ok($crypto_onetimeauth->verify($mac, $rmsg, $key),
        "random message $clen verified");

    if ( $clen > 0 ) {
        my $rand_pos = random_number($clen);
        my $c = ord(substr($s_rmsg, $rand_pos, 1));
        $c += 1 + random_number(255);
        substr($s_rmsg, $rand_pos, 1, chr($c & 0xFF));

        ok(! $crypto_onetimeauth->verify($s_hash, $s_rmsg, $key),
            "modified random message $clen fails verification");

        $rand_pos = random_number($crypto_onetimeauth->BYTES);
        $c = ord(substr($s_hash, $rand_pos, 1));
        $c += 1 + random_number(255);
        substr($s_hash, $rand_pos, 1, chr($c & 0xFF));

        ok(! $crypto_onetimeauth->verify($s_hash, $s_rmsg, $key),
            "modified mac for $clen fails verification");
    }
}

done_testing();
