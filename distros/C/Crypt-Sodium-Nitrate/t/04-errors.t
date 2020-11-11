#!perl
use strict;
use warnings;

use Test::More;
use Test::Exception;

use Crypt::Sodium::Nitrate;

my $k = "K" x Crypt::Sodium::Nitrate::KEYBYTES();
my $n = "N" x Crypt::Sodium::Nitrate::NONCEBYTES();

my $bad_arity = qr/\Qencrypt() must be passed a message, a nonce, and a key\E|Usage: Crypt::Sodium::Nitrate::encrypt/;

throws_ok { Crypt::Sodium::Nitrate::encrypt() } $bad_arity, "no args";
throws_ok { Crypt::Sodium::Nitrate::encrypt("") } $bad_arity, "1 arg";
throws_ok { Crypt::Sodium::Nitrate::encrypt("", "") } $bad_arity, "2 args";

throws_ok { Crypt::Sodium::Nitrate::encrypt("", "", "", "") } $bad_arity, "4 args";
my @args = ("" x 66);
throws_ok { Crypt::Sodium::Nitrate::encrypt(@args) } $bad_arity, "array of args";

throws_ok { Crypt::Sodium::Nitrate::encrypt("", "bad noncexxx", $k) } qr/Invalid nonce/;
throws_ok { Crypt::Sodium::Nitrate::encrypt("", $n, "bad key") } qr/Invalid key/;

throws_ok { Crypt::Sodium::Nitrate::decrypt("", $n, $k) } qr/Invalid ciphertext/;

done_testing;
