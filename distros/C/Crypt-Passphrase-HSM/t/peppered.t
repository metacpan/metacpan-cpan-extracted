#!perl

use strict;
use warnings;

use lib 't/lib';

use Test::More;

plan skip_all => 'No HSM provider defined' unless defined $ENV{HSM_PROVIDER};

use Crypt::Passphrase;

use Crypt::HSM;

my $path = $ENV{HSM_PROVIDER} // '';

plan skip_all => '' unless -e $path;

my $provider = Crypt::HSM->load($path);
my @slots = $provider->slots(1);
my $session = $slots[0]->open_session;
$session->login('user', $ENV{HSM_PIN}) if $ENV{HSM_PIN};

my $key = $session->generate_key('generic-secret-key-gen', { 'value-len' => 64, token => 0, sign => 1, label => 'apepper-1' });

my $passphrase = Crypt::Passphrase->new(encoder => {
	module  => 'Pepper::HSM',
	session => $session,
	prefix  => 'apepper-',
	active  => '1',
	inner   => 'Reversed',
});

my $password = 'password';

my $hash1 = $passphrase->hash_password($password);
ok($passphrase->verify_password($password, $hash1), 'Peppered password validates');
ok(!$passphrase->needs_rehash($hash1), 'Peppered password doesn\'t need to be regenerated');

my $hash2 = $hash1 =~ s/id=1/id=2/r;
ok(!$passphrase->verify_password($password, $hash2), 'Wrong pepper leads to failure') or diag $hash2;

done_testing;
