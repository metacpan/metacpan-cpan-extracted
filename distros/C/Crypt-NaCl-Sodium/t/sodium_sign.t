
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(:utils);


my $crypto_sign = Crypt::NaCl::Sodium->sign();

my $keypair_seed = join('', map { chr($_) }
        0x42, 0x11, 0x51, 0xa4, 0x59, 0xfa, 0xea, 0xde, 0x3d, 0x24, 0x71,
        0x15, 0xf9, 0x4a, 0xed, 0xae, 0x42, 0x31, 0x81, 0x24, 0x09, 0x5a,
        0xfa, 0xbe, 0x4d, 0x14, 0x51, 0xa5, 0x59, 0xfa, 0xed, 0xee
);

my @l = (
        0xed, 0xd3, 0xf5, 0x5c, 0x1a, 0x63, 0x12, 0x58,
        0xd6, 0x9c, 0xf7, 0xa2, 0xde, 0xf9, 0xde, 0x14,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00,
        0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x00, 0x10
);

ok($crypto_sign->$_ > 0, "$_ > 0") for qw( BYTES PUBLICKEYBYTES SECRETKEYBYTES SEEDBYTES );

my @tests = getTestData();
my $i = 0;
my ($mac, $pk_bin, $msg_bin); # last test used later
for ($i = 0; $i < scalar @tests; $i++) {
    my $test = $tests[$i];
    my $t = $i + 1;

    my $sk_bin = hex2bin($test->{sk});
    $pk_bin = hex2bin($test->{pk});
    my $sig_bin = hex2bin($test->{sig});
    my $skpk = substr($sk_bin, 0, $crypto_sign->SEEDBYTES) . substr($pk_bin, 0, $crypto_sign->PUBLICKEYBYTES);
    my $msg = $test->{msg};
    $msg_bin = hex2bin($msg);

    my $sealed = $crypto_sign->seal( $msg_bin, $skpk );
    ok($sealed, "message $t sealed");
    my $s_sealed = "$sealed";

    is(bin2hex(substr($s_sealed, 0, $crypto_sign->BYTES)), $test->{sig}, "signature $t correct");

    my $opened = $crypto_sign->open( $sealed, $pk_bin );
    is(bin2hex($opened), $test->{msg}, "message $t opened");

    my $mod_sealed = substr($s_sealed, 0, 32) . add_l(substr($s_sealed, 32));
    isnt(bin2hex($sealed), bin2hex($mod_sealed), "modified sealed message");

    my $mod_opened = $crypto_sign->open( $mod_sealed, $pk_bin );
    is(bin2hex($mod_opened), $test->{msg}, "message $t is malleable");

    my $c = ord(substr($mod_sealed, $i + $crypto_sign->BYTES - 1, 1));
    $c = ($c + 1) & 0xFF;
    substr($mod_sealed, $i + $crypto_sign->BYTES - 1, 1, chr($c));

    eval {
        my $mod_opened = $crypto_sign->open( $mod_sealed, $pk_bin );
    };
    like($@, qr/Message forged/, "message $t was forged");

    $mac = $crypto_sign->mac( $msg_bin, $skpk );
    ok($mac, "detached signature $t");
    ok(length($mac) != 0 && length($mac) <= $crypto_sign->BYTES, "...and $t of correct length");
    is(bin2hex($mac), $test->{sig}, "correct signature $t");

    ok($crypto_sign->verify( $mac , $msg_bin, $pk_bin ), "...and verified $t" );
}

my $s_mac = "$mac"; # from byteslocker
for (my $j = 1; $j < 8; $j++) {
    my $c = ord(substr($s_mac, 63, 1));
    $c ^= ( $j << 5);
    substr($s_mac, 63, 1, chr($c & 0xFF));

    ok( ! $crypto_sign->verify( $s_mac , $msg_bin, $pk_bin ), "detached signature verification $j failed");

    $c ^= ( $j << 5);
    substr($s_mac, 63, 1, chr($c & 0xFF));
}

ok( ! $crypto_sign->verify( $s_mac , $msg_bin, "\0" x $crypto_sign->PUBLICKEYBYTES),
    "detached signature verification have failed");

my ($pkey, $skey) = $crypto_sign->keypair();
ok($pkey, "pkey generated");
ok($skey, "skey generated");

($pkey, $skey) = $crypto_sign->keypair($keypair_seed);
ok($pkey, "pkey generated from seed");
ok($skey, "skey generated from seed");

my $extract_seed = $crypto_sign->extract_seed($skey);
ok($extract_seed, "extracted seed from generated secret key");
is(bin2hex($extract_seed), bin2hex($keypair_seed), "...and is correct");

my $extract_pkey = $crypto_sign->public_key($skey);
ok($extract_pkey, "extracted pkey from generated secret key");
is(bin2hex($extract_pkey), bin2hex($pkey), "...and is correct");

is(bin2hex($pkey),
    "b5076a8474a832daee4dd5b4040983b6623b5f344aca57d4d6ee4baf3f259e6e", "correct pkey");
is(bin2hex($skey),
    "421151a459faeade3d247115f94aedae42318124095afabe4d1451a559faedeeb5076a8474a832daee4dd5b4040983b6623b5f344aca57d4d6ee4baf3f259e6e", "correct skey");

done_testing();


sub add_l {
    my $S = shift;

    my $c = 0;
    my $i;
    my $s;

    for ($i = 0; $i < 32; $i++) {
        $s = ord(substr($S, $i, 1)) + $l[$i] + $c;
        substr($S, $i, 1, chr($s & 0xFF));
        $c = (($s >> 8) & 1) & 0xFF;
    }

    return $S;
}

sub getTestData {
    open(TEST, "t/sodium_sign.dat") or die "Cannot open test data file: $!";
    my @tests;
    while (my $line = <TEST>) {
        my ($sk, $pk, $sig, $msg)
        = $line =~ /\[\[([^\]]+)\]\[([^\]]+)\]\[([^\]]+)\]"([^"]*)"\]/;

        push @tests, {
            sk => $sk,
            pk => $pk,
            sig => $sig,
            msg => $msg,
        };
    }

    return @tests;
}

