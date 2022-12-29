#!perl

use strict;
use warnings;

use Test::More;

plan skip_all => "Author only" unless $ENV{AUTHOR_TESTING};

use Crypt::Passphrase;
use Crypt::Argon2 qw/argon2id_pass argon2i_pass/;
use Crypt::Bcrypt qw/bcrypt/;
use MIME::Base64 qw/encode_base64 decode_base64/;

sub base64_encoded {
	my ($password, $hash) = @_;
	return $password eq decode_base64($hash);
}

my $passphrase = Crypt::Passphrase->new(
	encoder    => {
		module      => 'Argon2',
		memory_cost => '16M',
		time_cost   => 2,
		parallel    => 1,
		output_size => 16,
		salt_size   => 16,
	},
	validators => [ 'Bcrypt', \&base64_encoded ],
);

my $password = 'password';
my $salt = "\0" x 16;

my $hash1 = $passphrase->hash_password($password);
ok($passphrase->verify_password($password, $hash1), 'Self-generated password validates');
ok(!$passphrase->needs_rehash($hash1), 'Self-generated password doesn\'t need to be regenerated');

my $hash2 = argon2id_pass($password, $salt, 2, '16M', 1, 16);
ok($passphrase->verify_password($password, $hash2), 'Can verify password with equivalent parameters');
ok(!$passphrase->needs_rehash($hash2), 'Password with equivalent parameters doesn\'t need rehash');

my $hash3 = argon2i_pass($password, $salt, 2, '16M', 1, 16);
ok($passphrase->verify_password($password, $hash3), 'Can verify password with argon2i');
ok($passphrase->needs_rehash($hash3), 'argon2i hash needs rehash');

my $hash4 = argon2id_pass($password, $salt, 2, '8M', 1, 16);
ok($passphrase->verify_password($password, $hash4), 'Can verify reduced memory cost hash');
ok($passphrase->needs_rehash($hash4), 'Reduced memory cost hash needs rehash');

my $hash5 = bcrypt($password, '2b', 10, $salt);
ok($passphrase->verify_password($password, $hash5), 'Can verify bcrypt hash');
ok($passphrase->needs_rehash($hash5), 'bcrypt hash needs rehash');

my $hash6 = encode_base64($password);
ok($passphrase->verify_password($password, $hash6), 'Can verify backup "hash"');
ok($passphrase->needs_rehash($hash6), 'Backup hash needs rehash');

my $hash7 = '$1$3azHgidD$SrJPt7B.9rekpmwJwtON31';
ok(!$passphrase->verify_password($password, $hash7), 'Can\'t verify md5 crypt');

ok(!$passphrase->verify_password($password, '*'), '* fails to verify');

done_testing;


