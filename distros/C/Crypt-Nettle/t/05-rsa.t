# -*- cperl -*-
# Before `make install' is performed this script should be runnable with
# `make test'. After `make install' it should work as `perl 05-rsa.t'

#########################

use strict;
use warnings;
use Test;
use ExtUtils::testlib;
use Crypt::Nettle::RSA;
use Crypt::Nettle::Yarrow;
use bytes;

#########################



my $asn1_key = '
-----BEGIN RSA PRIVATE KEY-----
MIICXQIBAAKBgQC9y+7NmnxzVHmv73D0peIhI/oq6RQKrHcQc8dbLwRAJoHmMh5H
F+jytFJciYEPijpyabgR9SopC6uUrdcddOjD4ie66P9Habn2T6Wrews3Vogz/Vax
9O3Dk0wRcy5rmrYvSLv0/SoiptLs2wdZERWVBAGwsEKTGMpCLtCN7YIR9wIDAQAB
AoGAJo1F9H1sygBet13rk8YeKJ0mM5EkgQaHKNBbrinesykfOaL0g3xX1PTLxgAo
Nv/c32CaAwvJhIzaTVkCWPlmTgoOkICzx8RrI9Q5CEqko1/M1u175ce7z0ABi6Ex
iRksLQGauCaxh5NcaHoRIdiTrV4KMPKNYwBiKEK0QRabgAECQQDh+iIfUKfyWIcH
vGCZhSfSa02xh63h21dbjHvKfb0mVlOClkQtuSdA11ST5uu+EqGLtm5F0khr16AT
TfdxHpLxAkEA1wM9atSdJ6HkN1s0qAtUWpIAQF6lPEWsTFk0/arx8ONulf+oKvKN
xA9d/91twMBgDWEgBFEbpDuyoR2Xgf4jZwJAWzgUhB2T3gEcaOQC/pXAsHD+SNaj
O1PGXL9FzUSakRox1boAxZBDJyqFCrshmHV+3p4Cv46WC2pcRM6pPvF/kQJBAIM5
iPxwctHDboOSeJqu/3afcOPYX8RfSX73Wu4OrMa2J8IIXFyJ2Jf2QQpt3BQt1PGV
e3LnBZXAkY7ffp5purUCQQCCRj7XZtUvOxGVQHZZQhpaL5A3wPbqAo/z4vZae7av
Q62j791X6LM0jNGjwd/9Hxzbw97fNQprCMbNf8xwGFNq
-----END RSA PRIVATE KEY-----
';


# params for secret key (from PEM block above):
my $d ='0x268d45f47d6cca005eb75deb93c61e289d2633912481068728d05bae29deb3291f39a2f4837c57d4f4cbc6002836ffdcdf609a030bc9848cda4d590258f9664e0a0e9080b3c7c46b23d439084aa4a35fccd6ed7be5c7bbcf40018ba13189192c2d019ab826b187935c687a1121d893ad5e0a30f28d6300622842b441169b8001';
my $p = '0xe1fa221f50a7f2588707bc60998527d26b4db187ade1db575b8c7bca7dbd2656538296442db92740d75493e6ebbe12a18bb66e45d2486bd7a0134df7711e92f1';
my $q = '0xd7033d6ad49d27a1e4375b34a80b545a9200405ea53c45ac4c5934fdaaf1f0e36e95ffa82af28dc40f5dffdd6dc0c0600d612004511ba43bb2a11d9781fe2367';

#params for public key (from PEM block above):
my $n = '0xbdcbeecd9a7c735479afef70f4a5e22123fa2ae9140aac771073c75b2f04402681e6321e4717e8f2b4525c89810f8a3a7269b811f52a290bab94add71d74e8c3e227bae8ff4769b9f64fa5ab7b0b37568833fd56b1f4edc3934c11732e6b9ab62f48bbf4fd2a22a6d2ecdb07591115950401b0b0429318ca422ed08ded8211f7';
my $e = '0x10001';

# params for the "generated" RSA key based on the known state of the yarrow process:
my $yarrow_generated_params =
  {
   'e' => '0x10001',
   'n' => '0xcb544842909d0f2f687ebf17b841129bbdc0dd1de19c80d964f1592116b765dbe3bc08707fff97971efcf128fd7f72bc4fd4b301e0107dc1d59d6b06a638f08150785135d864987901042e2757c57efed3083dd2ffa5d71b11a92c2a2e36d52baf959a2771272d717bb931f8add10b4de5006b0253a13140361de4dc80ea2d47',
   'd' => '0xad2aa7ac014bb1ee1759b2d7b9b5b9ea67ee04a3794cf7b3ae339a4c02f3c8cd4024192feee338309d54a0f2df0a9725e7fb6745169614f46b4079311d89ead14172850b946787b3dd5be661815e040d62e1d606862bbd2c887d8f8c0e564b80039e6a0b3d829207b122685176f52f44d897e19a3445ec74a9cdd173014e3cc1',
   'p' => '0xd30c49e73398809a3180b4451948db3621e54c7ad826b6eaeb511bb04526cf559033ec66dabbab91c83afc8b42d7500f7a1a9d00ace527f34ae0e4257eedad27',
   'q' => '0xf6a31d9ed689c7ac14018da08c0c538583394b28393ed5846e0373714fa3cd9cd972aff36b094e5fdf54c1f8523a59c88e8ce81e12013fc36f59137ab90dd2e1',
   'a' => '0xac5c05e337651dea4ff16fc85afd0062764e4126b66eefc66dc640d9b5b01b76229df53c8ef8e406dc43284b479c76bb1d1aad0c8727637833b7f53b962cdfd3',
   'b' => '0xb7b1173f9513fb261ba4688259ac588c8906a4066a54751c73ff97fc9dcf273599f2c43f6cc9fa9887328e614f84ec17e6abe5b977b97c6f27c05534c31d1ba1',
   'c' => '0x6c1a0a84053474a80e577ccb129a68aa37ce71e37108728b74f73ecd2362f5b826cfe82f4940c9ad97605c30e631b4a91b990d48fed820e6e8401e55b856d12e',
  };

my $digest_algos = [ 'md5', 'sha1', 'sha256', 'sha512' ];
my $bad_algos = [ 'md2', 'md4', 'sha224', 'sha384' ];

my $test_data = [ '', 'abc123', 'go nettle go!', 'this is test data', 'XMzqir9uXGj4dMyFd+0lLw', 'monkeybusiness' ];


plan tests => (8 +
               scalar(keys(%{$yarrow_generated_params})) +
               (10*scalar(@{$digest_algos})*scalar(@{$test_data})) +
               scalar(@{$bad_algos}));

my $pubkey = Crypt::Nettle::RSA->new_public_key($n, $e);
my $privkey = Crypt::Nettle::RSA->new_private_key($d, $p, $q);

ok(defined($pubkey));
ok(defined($privkey));

ok($n eq $pubkey->key_params()->{'n'});
ok($e eq $pubkey->key_params()->{'e'});

ok($n eq $privkey->key_params()->{'n'});
ok($e eq $privkey->key_params()->{'e'});
ok($p eq $privkey->key_params()->{'p'});
ok($q eq $privkey->key_params()->{'q'});


# use a static seed to get replicable results for testing.
# obviously, do not do anything this stupid in production.
my $seed = 'x' x 32;
my $y = Crypt::Nettle::Yarrow->new();
$y->seed($seed);
my $key = Crypt::Nettle::RSA->generate_keypair($y, 1024);
my $params = $key->key_params();

for my $param (keys(%{$yarrow_generated_params})) {
  ok($yarrow_generated_params->{$param} eq $params->{$param});
};

use Data::Dumper;

for my $data (@${test_data}) {
  for my $algo (@{$digest_algos}) {
    for my $keypair (['generated', $key], ['stored', $privkey]) {
      my ($keylabel, $curkey) = @{$keypair};
      my $sig = $curkey->rsa_sign($algo, $data);
      ok(defined($sig));
      my $ret = $curkey->rsa_verify($algo, $data, $sig);
      ok(defined($ret));
      warn Dumper({key => $keylabel, algo => $algo, sig => unpack('H*', $sig), data => $data})
        if($ret != 1);
      ok($ret == 1);
      my $badsig = $sig ^ "\01"; # flip one bit
      $ret = $curkey->rsa_verify($algo, $data, $badsig);
      ok(defined($ret));
      ok($ret == 0);
    }
  }
}

for my $algo (@{$bad_algos}) {
  my $sig = $key->rsa_sign($algo, 'abc123');
  ok(!defined($sig));
}
