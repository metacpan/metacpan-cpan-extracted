#!perl

use strict;
use warnings;

use Test::More;

use Crypt::Passphrase::PBKDF2;

my $passphrase = Crypt::Passphrase::PBKDF2->new(
	type       => 'sha256',
	iterations => 8000,
);

my $password = 'password';
my $salt = "\0" x 16;

my $hash1 = $passphrase->hash_password($password);
ok($passphrase->verify_password($password, $hash1), 'Self-generated password validates');
ok(!$passphrase->needs_rehash($hash1), 'Self-generated password doesn\'t need to be regenerated');

my $hash2 = '$pbkdf2-sha256$6400$0ZrzXitFSGltTQnBWOsdAw$Y11AchqV4b0sUisdZd0Xr97KWoymNE0LNNrnEgY4H9M';
ok($passphrase->verify_password($password, $hash2), 'Externally created password verifies');
ok($passphrase->needs_rehash($hash2), 'Externally created password doesn\'t need rehash');

my $hash3 = '$pbkdf2-sha256$6400$.6UI/S.nXIk8jcbdHx3Fhg$98jZicV16ODfEsEZeYPGHU3kbrUrvUEXOPimVSQDD44';
ok($passphrase->verify_password($password, $hash3), 'Externally created password with reduced rounds verifies');
ok($passphrase->needs_rehash($hash3), 'Password with reduced salt does need rehash');

done_testing;
