#!perl

use strict;
use warnings;

use Test::More;

use Crypt::Argon2 qw/argon2id_pass argon2i_pass/;
use Crypt::Passphrase::Argon2;

my $passphrase = Crypt::Passphrase::Argon2->new(
	memory_cost => '16M',
	time_cost   => 2,
	parallel    => 1,
	output_size => 16,
	salt_size   => 16,
);

my $password = 'password';
my $salt = "\0" x 16;

my $hash1 = $passphrase->hash_password($password);
ok($passphrase->verify_password($password, $hash1), 'Self-generated password validates');
ok(!$passphrase->needs_rehash($hash1), 'Self-generated password doesn\'t need to be regenerated');

my $hash2 = argon2id_pass($password, $salt, 2, '16M', 1, 16);
ok($passphrase->verify_password($password, $hash2));
ok(!$passphrase->needs_rehash($hash2));

my $hash3 = argon2i_pass($password, $salt, 2, '16M', 1, 16);
ok($passphrase->verify_password($password, $hash3));
ok($passphrase->needs_rehash($hash3));

my $hash4 = argon2id_pass($password, $salt, 2, '8M', 1, 16);
ok($passphrase->verify_password($password, $hash4));
ok($passphrase->needs_rehash($hash4));

my $passphrase2 = Crypt::Passphrase::Argon2->new(profile => 'interactive');
my $passphrase3 = Crypt::Passphrase::Argon2->new(profile => 'sensitive');
my $hash5 = $passphrase2->hash_password($password);
ok($passphrase3->verify_password($password, $hash5));
ok($passphrase3->needs_rehash($hash5));

done_testing;
