#!perl

use strict;
use warnings;

use Test::More;

use Crypt::Passphrase;
use Crypt::Passphrase::MD5::Hex;

my $validator = Crypt::Passphrase::MD5::Hex->new;

ok($validator->accepts_hash('098f6bcd4621d373cade4e832627b4f6'));
ok($validator->verify_password('test', '098f6bcd4621d373cade4e832627b4f6'));

my $passphrase = Crypt::Passphrase->new(encoder => $validator); # naughty
ok $passphrase->verify_password('test', '098f6bcd4621d373cade4e832627b4f6');
ok !$passphrase->verify_password('test', '098f6bcd4621d373');

my $passphrase2 = Crypt::Passphrase->new(encoder => 'SHA1::Hex');
ok $passphrase2->verify_password('test', 'a94a8fe5ccb19ba61c4c0873d391e987982fbbd3');
ok !$passphrase2->verify_password('test', 'a94a8fe5ccb19ba');

done_testing;
