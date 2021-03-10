#!perl

use strict;
use warnings;

use Test::More;

use Crypt::ScryptKDF;
use Crypt::Passphrase::Scrypt;

my $passphrase = Crypt::Passphrase::Scrypt->new;

my $password = 'password';
my $salt = "\0" x 16;

my $hash1 = $passphrase->hash_password($password);
ok($passphrase->verify_password($password, $hash1), 'Self-generated password validates');
ok(!$passphrase->needs_rehash($hash1), 'Self-generated password doesn\'t need to be regenerated');

my $hash2 = Crypt::Passphrase::Scrypt->new(cost => 15)->hash_password($password);
ok($passphrase->verify_password($password, $hash2), 'Manually created password with reduced rounds verifies');
ok($passphrase->needs_rehash($hash2), 'Password with reduced rounds does need rehash');

my $hash3 = '$scrypt$ln=16,r=8,p=1$aM15713r3Xsvxbi31lqr1Q$nFNh2CVHVjNldFVKDHDlm4CbdRSCdEBsjjJxD+iCs5E';
ok($passphrase->verify_password($password, $hash3), 'Manually created password with reduced rounds verifies');
ok(!$passphrase->needs_rehash($hash3), 'Premade password does not need rehash');

done_testing;
