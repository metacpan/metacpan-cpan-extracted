use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::Util "sodium_increment";
use Crypt::Sodium::XS::MemVault;
use Crypt::Sodium::XS::OO::kx;
use Crypt::Sodium::XS::secretbox ":default";
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

for my $alg (Crypt::Sodium::XS::OO::kx->primitives) {
  my $m = Crypt::Sodium::XS::OO::kx->new(primitive => $alg);

  ok($m->$_ > 0, "$_ > 0 ($alg)")
    for qw(PUBLICKEYBYTES SECRETKEYBYTES SEEDBYTES SESSIONKEYBYTES);

  my $seed1 = "A" x $m->SEEDBYTES;
  my $seed2 = Crypt::Sodium::XS::MemVault->new("B" x $m->SEEDBYTES);
  for my $seed ("", $seed1, $seed2) {
    my $seed_str = ref($seed) ? "seed vault" : $seed ? "seed" : "no seed";

    my ($cpk, $csk) = $m->keypair($seed ? $seed : ());
    my ($spk, $ssk) = $m->keypair;

    ok($cpk, "public key generated ($seed_str)");
    ok($csk, "secret key generated ($seed_str)");

    my ($crx, $ctx) = $m->client_session_keys($cpk, $csk, $spk);

    ok($crx, "client recv key generated ($seed_str)");
    ok($ctx, "client xmit key generated ($seed_str)");

    my ($srx, $stx) = $m->server_session_keys($spk, $ssk, $cpk);

    ok($srx, "server recv key generated ($seed_str)");
    ok($stx, "server xmit key generated ($seed_str)");

    ok(!$crx->compare($stx), "client recv key == server xmit key ($seed_str)");
    ok($crx->compare($srx), "client recv key != server recv key ($seed_str)");
    ok(!$ctx->compare($srx), "client xmit key == server recv key ($seed_str)");
    ok($ctx->compare($stx), "client xmit key != server xmit key ($seed_str)");

    my $nonce = secretbox_nonce;
    my $ct = secretbox_encrypt("foobar", $nonce, $ctx);
    ok($ct, "encrypted with client xmit key ($seed_str)");
    my $pt = secretbox_decrypt($ct, $nonce, $srx);
    ok($pt, "decrypted with server recv key ($seed_str)");
    $pt->unlock;
    is($pt, "foobar", "...and got the correct plaintext ($seed_str)");
    $nonce = sodium_increment($nonce);
    $ct = secretbox_encrypt("barfoo", $nonce, $stx);
    ok($ct, "encrypted with server xmit key ($seed_str)");
    $pt = secretbox_decrypt($ct, $nonce, $crx);
    ok($pt, "decrypted with client recv key ($seed_str)");
    $pt->unlock;
    is($pt, "barfoo", "...and got the correct plaintext ($seed_str)");

  }

}

done_testing();
