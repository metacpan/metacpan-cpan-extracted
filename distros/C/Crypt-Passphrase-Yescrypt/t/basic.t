#!perl

use strict;
use warnings;

use Test::More;

use Crypt::Yescrypt qw/yescrypt/;
use Crypt::Passphrase;

my $passphrase = Crypt::Passphrase->new(
	encoder => {
		module      => 'Yescrypt',
		block_count => 12,
		block_size  => 32,
		parallel    =>  1,
		salt_size   => 16,
	},
);

my $password = 'password';
my $salt = "\0" x 16;

my $hash1 = $passphrase->hash_password($password);
ok($passphrase->verify_password($password, $hash1), 'Self-generated password validates');
ok(!$passphrase->needs_rehash($hash1), 'Self-generated password doesn\'t need to be regenerated');

my $hash2 = yescrypt($password, $salt, 0xb6, 12, 32, 1);
ok($passphrase->verify_password($password, $hash2));
ok(!$passphrase->needs_rehash($hash2));

my $hash3 = yescrypt($password, $salt, 0xb6, 12, 16, 1);
ok($passphrase->verify_password($password, $hash3));
ok($passphrase->needs_rehash($hash3));

my $hash4 = '$y$j9T$SALT$HIA0o5.HmkE9HhZ4H8X1r0aRYrqdcv0IJEZ2PLpqpz6';
ok($passphrase->verify_password('PASSWORD', $hash4));
ok(!$passphrase->needs_rehash($hash4));

done_testing;
