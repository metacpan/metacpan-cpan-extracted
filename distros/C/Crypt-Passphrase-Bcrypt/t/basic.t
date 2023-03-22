#!perl

use strict;
use warnings;

use Test::More;

use Crypt::Bcrypt qw/bcrypt/;
use Crypt::Passphrase;

my $passphrase = Crypt::Passphrase->new(
	encoder => {
		module => 'Bcrypt',
		cost   => 14,
	},
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

my $hashed = Crypt::Passphrase->new(
	encoder => {
		module => 'Bcrypt',
		cost   => 14,
		hash   => 'sha256',
	},
);

my $hash4 = $hashed->hash_password($password);
like($hash4, qr/ ^ \$ bcrypt-sha256 \$ v=2,t=(2\w),r=(\d{2}) \$ /x, 'Prehashed bcrypt hash');
ok($hashed->verify_password($password, $hash4), 'Hashed password validates');
ok(!$hashed->needs_rehash($hash4), 'Hashed password doesn\'t need to be regenerated');
ok($hashed->needs_rehash($hash1), 'Unprehashed hash needs rehashing');

ok($hashed->verify_password('password', '$bcrypt-sha256$v=2,t=2b,r=12$n79VH.0Q2TMWmt3Oqt9uku$Kq4Noyk3094Y2QlB8NdRT8SvGiI4ft2'));
ok($hashed->verify_password('password', '$bcrypt-sha256$v=2,t=2b,r=13$AmytCA45b12VeVg0YdDT3.$IZTbbJKgJlD5IJoCWhuDUqYjnJwNPlO'));

done_testing;
