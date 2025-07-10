use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::Util "sodium_random_bytes";
use Crypt::Sodium::XS::generichash "generichash";
use Crypt::Sodium::XS::OO::sign;
use Crypt::Sodium::XS::scalarmult "scalarmult_base";
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

my $msg = "How do you do?";

for my $alg (Crypt::Sodium::XS::OO::sign->primitives) {
  my $m = Crypt::Sodium::XS::OO::sign->new(primitive => $alg);

  ok($m->$_ > 0, "$_ > 0 ($alg)")
    for qw/BYTES MESSAGEBYTES_MAX PUBLICKEYBYTES SECRETKEYBYTES SEEDBYTES/;

  for (1 .. 2) {
    my $seed = sodium_random_bytes($m->SEEDBYTES);

    for (1 .. 2) {
      my ($pk, $sk) = $m->keypair($seed);
      ok($pk, "pk generated from seed ($alg)");
      ok($sk, "sk generated from seed ($alg)");
      my $pk2 = $m->sk_to_pk($sk);
      ok($pk2, "pk generated from sk ($alg)");
      is(unpack("H*", $pk), unpack("H*", $pk2), "pk matches ($alg)");
      $pk2 = $m->sk_to_pk($sk->clone->unlock.'');
      ok($pk2, "pk generated from sk string ($alg)");
      is(unpack("H*", $pk), unpack("H*", $pk2), "pk matches ($alg)");
      my $seed2 = $m->sk_to_seed($sk);
      ok($seed2, "seed extracted from sk ($alg)");
      is($seed2->to_hex->unlock, unpack("H*", $seed), "seed matches ($alg)");
      $seed2 = $m->sk_to_seed($sk->clone->unlock.'');
      ok($seed2, "seed extracted from sk string ($alg)");
      is($seed2->to_hex->unlock, unpack("H*", $seed), "seed matches ($alg)");
    }

    my ($pk, $sk) = $m->keypair;
    ok($pk, "pk generated with random seed ($alg)");
    ok($sk, "sk generated with random seed ($alg)");

    my $signed = $m->sign($msg, $sk);
    ok($signed, "signed msg ($alg)");

    my $msg_mv = Crypt::Sodium::XS::MemVault->new($msg);
    my $signed_mv = $m->sign($msg_mv, $sk);
    ok($signed_mv, "signed MemVault msg ($alg)");
    isa_ok($signed_mv, "Crypt::Sodium::XS::MemVault");
    ok($signed_mv->is_locked, "signing locked MemVault returns locked");

    my $opened = $m->open($signed, $pk);
    ok($opened, "opened signed msg ($alg)");
    is($opened, $msg, "opened msg matches original ($alg)");

    my $opened_mv = $m->open($signed_mv, $pk);
    ok($opened_mv, "opened MemVault signed msg ($alg)");
    isa_ok($opened_mv, "Crypt::Sodium::XS::MemVault");
    ok($opened_mv->is_locked, "opening locked MemVault returns locked");
    is($opened_mv->unlock, $msg, "opened MemVault msg matches original ($alg)");

    # detached mode
    my $sig = $m->detached($msg, $sk);
    ok($sig, "signature calculated for msg using sk ($alg)");

    ok($m->verify($msg, $sig, $pk),
       "signed message verified using sig ($alg)");
    ok(!$m->verify("Some other message.", $sig, $pk),
       "wrong message fails to verify using sig ($alg)");
    ok(!$m->verify($msg, "X" x $m->BYTES, $pk),
       "invalid signature fails to verify ($alg)");

    # multi-part
    my $mp = $m->init;
    ok($mp, "created signing multi-part state ($alg)");
    my $mp2 = $m->init;
    my $mp3 = $mp2->clone;
    
    for my $c (split(//, $msg)) {
      $mp->update($c);
      $mp2->update($c);
      $mp3->update($c);
    }

    $sig = $mp->final_sign($sk);
    ok($sig, "creating signature from multi-part ($alg)");
    my $sig2 = $mp2->final_sign($sk);
    is(unpack("H*", $sig2), unpack("H*", $sig), "two multi-part, same sig ($alg)");
    my $sig3 = $mp3->final_sign($sk);
    is(unpack("H*", $sig3), unpack("H*", $sig), "cloned multi-part, same sig ($alg)");

    $mp = $m->init;
    $mp2 = $m->init;
    for my $c (split(//, $msg)) {
      $mp->update($c);
      $mp2->update($c);
    }

    ok($mp->final_verify($sig2, $pk), "multi-part verification works ($alg)");
    ok($mp2->final_verify($sig, $pk), "multi-part2 verification works ($alg)");

  }

  # convert
  my $seed = pack("H*", "421151a459faeade3d247115f94aedae"
                      . "42318124095afabe4d1451a559faedee");
  my ($pk, $sk) = $m->keypair($seed);
  my $pk_curve = $m->pk_to_curve25519($pk);
  my $sk_curve = $m->sk_to_curve25519($sk);
  my ($pk_curve2, $sk_curve2) = $m->to_curve25519($pk, $sk);

  is(unpack("H*", $pk_curve),
     "f1814f0e8ff1043d8a44d25babff3cedcae6c22c3edaa48f857ae70de2baae50",
     "correct pk to curve25519 ($alg)");
  is($sk_curve->to_hex->unlock,
     "8052030376d47112be7f73ed7a019293dd12ad910b654455798b4667d73de166",
     "correct sk to curve25519 ($alg)");
  is(unpack("H*", $pk_curve2), unpack("H*", $pk_curve),
     "correct pk to curve25519 combined ($alg)");
  is($sk_curve2->to_hex->unlock, $sk_curve->to_hex->unlock,
     "correct sk to curve25519 combined ($alg)");

  for (1 .. 500) {
    my ($pk, $sk) = $m->keypair;
    my ($pk_curve, $sk_curve) = $m->to_curve25519($pk, $sk);
    my $sk_base = scalarmult_base($sk_curve);
    is(unpack("H*", $pk_curve), unpack("H*", $sk_base),
       "correct ed25519 to curve25519 ($alg)");
  }
}

done_testing();
