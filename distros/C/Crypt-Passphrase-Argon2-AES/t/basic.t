#!perl

use strict;
use warnings;

use Test::More;

use Crypt::Passphrase;

my $passphrase = Crypt::Passphrase->new(
	encoder => {
		module => 'Argon2::AES',
		peppers => {
			1 => scalar('A' x 16),
			2 => scalar('B' x 16),
		},
		memory_cost => '16M',
		time_cost   => 2,
	},
	validators => [ 'Argon2' ],
);

my $password = 'password';
my $salt = "\0" x 16;

my $hash1 = $passphrase->hash_password($password);
ok($passphrase->verify_password($password, $hash1), 'Self-generated password validates');
ok(!$passphrase->needs_rehash($hash1), 'Self-generated password doesn\'t need to be regenerated');

ok($hash1 =~ / \A \$ argon2id-encrypted-aes-cbc \$ /x, 'Hash header looks like what we expect');

my $hash2 = '$argon2id$v=19$m=16384,t=2,p=1$AAAAAAAAAAAAAAAAAAAAAA$AcpOEUs9E88hQnLWQYw/ow';
ok($passphrase->verify_password($password, $hash2), 'Unencrypted hash validates');
ok($passphrase->needs_rehash($hash2), 'Unencrypted hash needs rehash');

my $hash3 = '$argon2id-encrypted-aes-cbc$v=19$m=16384,t=2,p=1,keyid=1$tOZt95qn9CHuFQzrx8346Q$VnInu6mq2fz8hqkMluox0Q';
ok($passphrase->verify_password($password, $hash3), 'Hash encrypted with old pepper still validates');
ok($passphrase->needs_rehash($hash3), 'Hash encrypted with old pepper needs rehash');

my $hash4 = '$argon2id-encrypted-aes-cbc$v=1,id=1$v=19$m=16384,t=2,p=1$tOZt95qn9CHuFQzrx8346Q$VnInu6mq2';
ok(!$passphrase->verify_password($password, $hash4), 'Incomplete hash doesn\'t validate');

done_testing;
