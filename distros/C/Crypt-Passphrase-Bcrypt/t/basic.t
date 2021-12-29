#!perl

use strict;
use warnings;

use Test::More;

use Crypt::Bcrypt qw/bcrypt/;
use Crypt::Passphrase::Bcrypt;

my $passphrase = Crypt::Passphrase::Bcrypt->new(
	cost => 14,
);

my $password = 'password';
my $salt = "\0" x 16;

my $hash1 = $passphrase->hash_password($password);
ok($passphrase->verify_password($password, $hash1), 'Self-generated password validates');
ok(!$passphrase->needs_rehash($hash1), 'Self-generated password doesn\'t need to be regenerated');

my $hash2 = bcrypt($password, '2b', 14, $salt);
ok($passphrase->verify_password($password, $hash2), 'Manually created password verifies');
ok(!$passphrase->needs_rehash($hash2), 'Manually created password doesn\'t need rehash');

my $hash3 = bcrypt($password, '2b', 13, $salt);
ok($passphrase->verify_password($password, $hash3), 'Manually created password with reduced rounds verifies');
ok($passphrase->needs_rehash($hash3), 'Password with reduced rounds does need rehash');

done_testing;
