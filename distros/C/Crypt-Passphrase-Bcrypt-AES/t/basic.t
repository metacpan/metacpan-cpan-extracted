#!perl

use strict;
use warnings;

use Test::More;

use Crypt::Passphrase;

my $passphrase = Crypt::Passphrase->new(
	encoder => {
		module => 'Bcrypt::AES',
		peppers => {
			1 => scalar('A' x 16),
			2 => scalar('B' x 16),
		},
		cost => 10,
	},
);

my $password = 'password';
my $salt = "\0" x 16;

my $hash1 = $passphrase->hash_password($password);
note $hash1;
ok($passphrase->verify_password($password, $hash1), 'Self-generated password validates');
ok(!$passphrase->needs_rehash($hash1), 'Self-generated password doesn\'t need to be regenerated');

ok($hash1 =~ / \A \$ bcrypt-sha384-encrypted-aes-ctr \$ /x, 'Hash header looks like what we expect');

my $hash2 = '$bcrypt-sha384$v=2,t=2b,r=10$E6LVVM2h6KRR.ta6fbQQM.$qtoWhmxRz30KmVpBBQB6ek2R.99VygC';
ok($passphrase->verify_password($password, $hash2), 'Unencrypted hash validates');
ok($passphrase->needs_rehash($hash2), 'Unencrypted hash needs rehash');

my $hash3 = '$bcrypt-sha384-encrypted-aes-ctr$t=2b,r=10,keyid=1$prVV03JXs1QD2DFojMXsSA$B452t7HawkUC1xO0oG7J42BVHlMaoJA';
ok($passphrase->verify_password($password, $hash3), 'Hash encrypted with old pepper still validates');
ok($passphrase->needs_rehash($hash3), 'Hash encrypted with old pepper needs rehash');
my $hash3b = $passphrase->recode_hash($hash3);
isnt($hash3b, $hash3, 'Recoded hash has changed');
ok(!$passphrase->needs_rehash($hash3b), 'Recoded hash doesn\'t need rehash');

my $hash4 = '$argon2id-encrypted-aes-cbc$v=1,id=1$v=19$m=16384,t=2,p=1$tOZt95qn9CHuFQzrx8346Q$VnInu6mq2';
ok(!$passphrase->verify_password($password, $hash4), 'Incomplete hash doesn\'t validate');

done_testing;
