
use strict;
use warnings;
use Test::More;


use Crypt::NaCl::Sodium qw(bin2hex);

my $crypto_pwhash = Crypt::NaCl::Sodium->pwhash;
my @passwords = (
    "Red horse butter on the jam",
    "One Ring to rule them all, One Ring to find them, One Ring to bring them all and in the darkness bind them",
);

ok($crypto_pwhash->$_ > 0, "$_ > 0")
    for qw( SALTBYTES STRBYTES OPSLIMIT_INTERACTIVE MEMLIMIT_INTERACTIVE OPSLIMIT_SENSITIVE MEMLIMIT_SENSITIVE );

for my $password ( @passwords ) {
    my ($key, $key_hex, $mac);

    my $salt = $crypto_pwhash->salt();
    ok($salt, "salt generated");

    my $pass_len = length($password);
    for my $key_len ( int($pass_len/2), $pass_len, 2*$pass_len ) {

        my $key = $crypto_pwhash->key( $password, $salt, bytes => $key_len );
        ok($key, "got key of $key_len bytes for password");
    }

    for my $opslimit ( $crypto_pwhash->OPSLIMIT_INTERACTIVE ..  $crypto_pwhash->OPSLIMIT_INTERACTIVE + 2 ) {
        for my $memlimit ( $crypto_pwhash->MEMLIMIT_INTERACTIVE ..  $crypto_pwhash->MEMLIMIT_INTERACTIVE + 2 ) {
            my $str = $crypto_pwhash->str( $password, opslimit => $opslimit, memlimit => $memlimit );
            ok($str, "password storage ok, with opslimit=$opslimit, memlimit=$memlimit");
            ok($crypto_pwhash->verify( $str, $password ), "...and verified");
        }
    }
}

done_testing();

