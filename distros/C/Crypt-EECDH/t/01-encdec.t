#!perl
# -*-cperl-*-
#
# 01-encdec.t - Test EECDH encryption and decryption
# Copyright (c) 2017 Ashish Gulhati <crypt-ecdsa at hash.neo.tc>

use Test::More tests => 10;

use Crypt::EECDH;

my $eecdh = new Crypt::EECDH;


for (1..2) {
  ok (my ($pub_signkey, $sec_signkey) = $eecdh->signkeygen(),                  "Generate server's " . $eecdh->sigscheme . ' keys');
  ok (my ($pubkey, $seckey, $signature) =
      $eecdh->keygen( PrivateKey => $sec_signkey, PublicKey => $pub_signkey ), "Generate signed server key");
  ok (my ($pubkey2, $seckey2) = $eecdh->keygen(),                              "Generate unsigned client key");

  ok (my ($encrypted) =
      $eecdh->encrypt( PublicKey => $pubkey, Message => "Testing",
		       SigningKey => $pub_signkey, Signature => $signature),   "Encrypt message");
  ok (($eecdh->decrypt( Ciphertext => $encrypted, Key => $seckey ))[0]
      eq 'Testing',                                                            "Decrypt message");

  $eecdh->sigscheme('Ed25519');
}

exit;
