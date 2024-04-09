#!perl

use strict;
use warnings;

use Test::More;

use Crypt::Eksblowfish::Bcrypt qw/bcrypt en_base64/;
use Crypt::Passphrase::Bcrypt;

my $passphrase = Crypt::Passphrase::Bcrypt->new;

my $password = 'password';
my $salt = "\0" x 16;

my $hash2 = bcrypt($password, '$2a$14$' . en_base64($salt));
ok($passphrase->accepts_hash($hash2), 'Accepts a bcrypt hash');
ok($passphrase->verify_password($password, $hash2), 'Manually created password verifies');

done_testing;
