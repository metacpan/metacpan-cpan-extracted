#!perl

use strict;
use warnings;

use Test::More;

use Crypt::Passwd::XS 'crypt';
use Crypt::Passphrase::Linux;

my $passphrase = Crypt::Passphrase::Linux->new(
	rounds => 100_000,
	type   => 'sha512',
);

my $password = 'password';
my $salt = "\0" x 16;

my $hash1 = $passphrase->hash_password($password);
ok($passphrase->verify_password($password, $hash1), 'Self-generated password validates');
ok(!$passphrase->needs_rehash($hash1), 'Self-generated password doesn\'t need to be regenerated');

my $hash2 = Crypt::Passwd::XS::crypt($password, '$6$rounds=100000$AAAAAAAAAAAAAAAAAAAAAA');
ok($passphrase->verify_password($password, $hash2));
ok(!$passphrase->needs_rehash($hash2));

my $hash3 = Crypt::Passwd::XS::crypt($password, '$5$rounds=20000$AAAAAAAAAAAAAA');
ok($passphrase->verify_password($password, $hash3));
ok($passphrase->needs_rehash($hash3));

my $hash4 = '$5$rounds=80000$wnsT7Yr92oJoP28r$cKhJImk5mfuSKV9b3mumNzlbstFUplKtQXXMo4G6Ep5';
ok($passphrase->verify_password($password, $hash4));
ok($passphrase->needs_rehash($hash4));

done_testing;

