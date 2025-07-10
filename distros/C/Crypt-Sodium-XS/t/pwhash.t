use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::OO::pwhash;

#FIXME: no pwhash_str testing?

my @passwords = (
  "Red horse butter on the jam",
  "One Ring to rule them all, One Ring to find them,"
    . " One Ring to bring them all and in the darkness bind them",
);

for my $alg (Crypt::Sodium::XS::OO::pwhash->primitives) {
  my $m = Crypt::Sodium::XS::OO::pwhash->new(primitive => $alg);

  ok($m->$_ > 0, "$_ > 0 ($alg)")
    for qw(
      BYTES_MAX PASSWD_MAX
      SALTBYTES STRBYTES
      OPSLIMIT_INTERACTIVE MEMLIMIT_INTERACTIVE
      OPSLIMIT_MAX MEMLIMIT_MAX
      OPSLIMIT_MIN MEMLIMIT_MIN
      OPSLIMIT_SENSITIVE MEMLIMIT_SENSITIVE
    );
  if ($alg eq 'scryptsalsa208sha256') { # no MODERATE
    for my $limit (qw(OPSLIMIT_MODERATE MEMLIMIT_MODERATE)) {
      eval { $m->$limit };
      like($@, qr/This primitive does not support/, "no $limit for $alg");
    }
  }
  else{
    ok($m->$_ > 0, "$_ > 0 ($alg)") for
      qw(OPSLIMIT_MODERATE MEMLIMIT_MODERATE);
  }
  ok($m->STRPREFIX, "STRPREFIX available ($alg)");
  ok($m->PRIMITIVE, "PRIMITIVE available ($alg)") if $alg eq 'default';

  for my $password (@passwords) {
    my $salt = $m->salt;
    ok($salt, "salt generated ($alg)");

    my $pass_len = length($password);
    for my $hash_len ($pass_len, 2*$pass_len) {
      my $hash = $m->pwhash($password, $salt, $hash_len);
      ok(length($hash) == $hash_len, "got hash of $hash_len bytes for password ($alg)");
    }

    my $str = $m->str($password);
    ok($str, "password storage ok, with default ops, default mem ($alg)");
    ok($m->verify($str, $password), "...and verified ($alg)");

    SKIP: for my $opslimit (
      $m->OPSLIMIT_INTERACTIVE,
      ($alg eq 'scryptsalsa208sha256' ? () : $m->OPSLIMIT_MODERATE),
      $m->OPSLIMIT_SENSITIVE,
    ) {
      for my $memlimit (
        $m->MEMLIMIT_INTERACTIVE,
        ($alg eq 'scryptsalsa208sha256' ? () : $m->MEMLIMIT_MODERATE),
        $m->MEMLIMIT_SENSITIVE,
      ) {
        if (!$ENV{TEST_HIGHMEM}
            && ($opslimit > $m->OPSLIMIT_INTERACTIVE
                || $memlimit > $m->MEMLIMIT_INTERACTIVE)) {
          skip "TEST_HIGHMEM not set", 2;
        }
        my $str = $m->str($password, $opslimit, $memlimit);
        ok($str, "password storage ok, with ops=$opslimit, mem=$memlimit ($alg)");
        ok($m->verify($str, $password), "...and verified ($alg)");
      }
    }
  }
}

done_testing();
