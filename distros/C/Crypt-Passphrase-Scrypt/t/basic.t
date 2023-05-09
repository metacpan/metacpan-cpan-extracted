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

my $passphrase2 = Crypt::Passphrase::Scrypt->new(cost => 15, block_size => 32, salt_size => 22);
my $hash4 = '$7$DU..../....2Q9obwLhin8qvQl6sisAO/$57x.voCZ7KkOfnXM7iv7973ues4B2.dMPicRyKJIfX2';
ok($passphrase2->verify_password('password', $hash4), '$7$ hash verifies');
ok($passphrase2->needs_rehash($hash4), '$7$ hash need not rehash');

my $hash5 = $passphrase->recode_hash($hash4);
isnt($hash5, $hash4, 'recode has updated the hash');
ok($passphrase2->verify_password('password', $hash5), 'Recoded hash verifies');
ok(!$passphrase2->needs_rehash($hash5), 'Recoded hash does need rehash');

done_testing;
