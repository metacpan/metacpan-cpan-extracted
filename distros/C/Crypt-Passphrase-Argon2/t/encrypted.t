#!perl

use strict;
use warnings;

use Test::More;

use lib 't/lib';
use Crypt::Passphrase::Argon2::Rot;
use Crypt::Argon2 qw/argon2id_pass/;

my $passphrase = Crypt::Passphrase::Argon2::Rot->new(
	profile => 'interactive',
	active  => 12,
);

my $password = 'password';
my $salt = "\0" x 16;

my $hash1 = $passphrase->hash_password($password);
ok($passphrase->verify_password($password, $hash1), 'Self-generated password validates');
ok(!$passphrase->needs_rehash($hash1), 'Self-generated password doesn\'t need to be regenerated');

my $passphrase2 = Crypt::Passphrase::Argon2::Rot->new(
	profile => 'interactive',
	active  => 42,
);
ok($passphrase2->verify_password($password, $hash1), 'Other-generated password validates');
ok($passphrase2->needs_rehash($hash1), 'Other-generated password does need to be regenerated');

my $hash2 = $passphrase2->recrypt_hash($hash1);
ok($passphrase2->verify_password($password, $hash2), 'Recrypted password validates');
ok(!$passphrase2->needs_rehash($hash2), 'Recrypted password doesn\'t need to be regenerated') or diag $hash2;

my $hash3 = argon2id_pass($password, $salt, 2, '64M', 1, 32);
ok($passphrase2->verify_password($password, $hash3), 'Raw password validates');
ok($passphrase2->needs_rehash($hash3), 'Raw password does need to be regenerated');

my $hash4 = $passphrase2->recrypt_hash($hash3);
ok($passphrase2->verify_password($password, $hash4), 'Recrypted raw password validates');
ok(!$passphrase2->needs_rehash($hash4), 'Recrypted raw password doesn\'t need to be regenerated');

done_testing;
