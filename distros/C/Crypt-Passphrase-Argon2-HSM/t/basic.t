#!perl

use strict;
use warnings;

use Test::More;

use Crypt::Passphrase;

use Crypt::HSM;

my $path = $ENV{HSM_PROVIDER};

plan skip_all => '' unless -e $path;

my $provider = Crypt::HSM->load($path);
my @slots = $provider->slots(1);
my $session = $provider->open_session($slots[0]);
$session->login('user', $ENV{HSM_PIN}) if $ENV{HSM_PIN};

my $old_key = $session->generate_key('aes-key-gen', { 'value-len' => 32, token => 0, label => 'apepper-1' });
my $key = $session->generate_key('aes-key-gen', { 'value-len' => 32, token => 0, label => 'apepper-2' });

my $passphrase = Crypt::Passphrase->new(
	encoder => {
		module => 'Argon2::HSM',
		session => $session,
		prefix  => 'apepper-',
		active => 2,
		memory_cost => '16M',
		time_cost   => 2,
	},
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

my $old_passphrase = Crypt::Passphrase->new(
	encoder => {
		module => 'Argon2::HSM',
		session => $session,
		prefix  => 'apepper-',
		active => 1,
		memory_cost => '16M',
		time_cost   => 2,
	},
);
my $hash3 = $old_passphrase->hash_password($password);
ok($passphrase->verify_password($password, $hash3), 'Hash encrypted with old pepper still validates');
ok($passphrase->needs_rehash($hash3), 'Hash encrypted with old pepper needs rehash');

done_testing;

