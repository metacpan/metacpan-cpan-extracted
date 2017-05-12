BEGIN { $| = 1; print "1..100\n"; }

use Crypt::Spritz;

my $n = 0;

my $c1 = new Crypt::Spritz;

for (1..3) {
   for (
      [ABC     => "779a8e01f9e9cbc0", "028fa2b48b934a18", "eb4765b22caa38ab", "a25b6e57fb35481b", "75ea088baadc803e"],
      [spam    => "f0609a1df143cebf", "acbba0813f300d3a", "433a025805dbb3b1", "e1eed00911069b9d", "782cf66ae9d1fdea"],
      [arcfour => "1afa8b5ee337dbc7", "ff8cf268094c87b9", "c72e6cfc08b27d4a", "cac713dfba93cd79", "413397b795a75abf"],
   ) {
      my ($a, $r, $h, $m, $ec, $em) = @$_;

      $c1->absorb ($a);
      my $s = unpack "H*", $c1->squeeze (0.5 * length $r);
      print $s eq $r ? "" : "not ", "ok ", ++$n, " # AS1 $a => $s (= $r)\n";

      $c1->init;

      my $c2 = $c1->clone;
      $c2->absorb ($_) for split //, $a;
      my $s = unpack "H*", join "", map $c2->squeeze (1), 1 .. 0.5 * length $r;
      print $s eq $r ? "" : "not ", "ok ", ++$n, " # AS2 $a => $s (= $r)\n";

      my $rng = new Crypt::Spritz::PRNG $a;
      $rng = unpack "H*", $rng->get (0.5 * length $r);
      print $rng eq $r ? "" : "not ", "ok ", ++$n, " # R $a => $rng (= $r)\n";

      my $h1 = new Crypt::Spritz::Hash;
      $h1->add ($a);
      $h1 = unpack "H*", substr $h1->finish (32), 0, 0.5 * length $h;
      print $h eq $h1 ? "" : "not ", "ok ", ++$n, " # H $a => $h1 (= $h)\n";

      my $mac1 = new Crypt::Spritz::MAC $a;
      $mac1->add ("schmorp");
      $mac1 = unpack "H*", substr $mac1->finish (13), -8;
      print $m eq $mac1 ? "" : "not ", "ok ", ++$n, " # M $a => $mac1 (= $m)\n";

      my $ci = new Crypt::Spritz::Cipher $a;
      my $ci1 = $ci->encrypt ($m);
      my $ci = new Crypt::Spritz::Cipher $a;
      $ci1 = $ci->decrypt ($ci1);
      print $m eq $ci1 ? "" : "not ", "ok ", ++$n, " # CI1 $a => $ci1 (= $m)\n";

      my $cx1 = new Crypt::Spritz::Cipher::XOR $a;
      $cx1 = unpack "H*", $cx1->crypt ("12345678") ^ "12345678";
      print $r eq $cx1 ? "" : "not ", "ok ", ++$n, " # CX1 $a => $cx1 (= $r)\n";

      my $cx2 = "98765432";
      Crypt::Spritz::Cipher::XOR->new ($a)->crypt_inplace ($cx2);
      $cx2 = unpack "H*", $cx2 ^ "98765432";
      print $r eq $cx2 ? "" : "not ", "ok ", ++$n, " # CX2 $a => $cx2 (= $r)\n";

      my $ae = new Crypt::Spritz::AEAD $a; $ae->nonce (45); $ae->associated_data (67);
      my $ar1 = $ae->encrypt ($m);
      my $ae = new Crypt::Spritz::AEAD $a; $ae->nonce (45); $ae->associated_data (67);
      $ar1 = $ae->decrypt ($ar1);
      print $m eq $ar1 ? "" : "not ", "ok ", ++$n, " # AR1 $a => $ar1 (= $m)\n";

      my $ae = new Crypt::Spritz::AEAD::XOR $a;
      $ae->nonce (12);
      $ae->associated_data (34);
      my $ar = unpack "H*", $ae->crypt ("A2345678") ^ "A2345678";
      print $ec eq $ar ? "" : "not ", "ok ", ++$n, " # AE1 $a => $ar (= $ec)\n";
      $ae = unpack "H*", $ae->finish (8);
      print $em eq $ae ? "" : "not ", "ok ", ++$n, " # AE2 $a => $ae (= $em)\n";
   }
}

print "ok 100\n";

