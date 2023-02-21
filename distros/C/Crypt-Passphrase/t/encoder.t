#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;

use Crypt::Passphrase;

my $passphrase = Crypt::Passphrase->new(encoder => 'Reversed');

my $password = 'password';
my $salt = "\0" x 16;

my $hash1 = $passphrase->hash_password($password);
is($hash1, '$reversed$drowssap', 'Password is reversed');
ok($passphrase->verify_password($password, $hash1), 'Self-generated password validates');
ok(!$passphrase->needs_rehash($hash1), 'Self-generated password doesn\'t need to be regenerated');

done_testing;
