use strict;
use warnings;
use Test::More;

use Crypt::Sodium::XS::Util "sodium_random_bytes";
use Crypt::Sodium::XS::OO::auth;
use FindBin '$Bin';
use lib "$Bin/lib";
use Test::MemVault;

unless (mlock_seems_available()) {
  diag(mlock_warning());
  disable_mlock();
}

my $msg = "How do you do?";

for my $alg (Crypt::Sodium::XS::OO::auth->primitives) {
  my $m = Crypt::Sodium::XS::OO::auth->new(primitive => $alg);

  ok($m->$_ > 0, "$_ > 0 ($alg)") for qw(BYTES KEYBYTES);

  # probably overkill...
    for my $key_len (0 .. 192) {
      next if $key_len % 4;
      next if $m->primitive eq 'default' and $key_len != $m->KEYBYTES;

      my $key = $key_len ? sodium_random_bytes($key_len) : "";
      my $hasher = $m->init($key);
      $hasher->update($msg);
      my $hash = $hasher->final;
      ok($hash, "got hash ($alg:$key_len)");
      ok($m->verify($hash, $msg, $key), "verify works ($alg:$key_len)");
    }

  for (1 .. 2) {
    my ($key, $mac);

    $key = $m->keygen;
    ok($key, "key generated ($alg)");
    is($key->length, $m->KEYBYTES, "key correct length ($alg)");

    $mac = $m->auth($msg, $key);
    ok($mac, "mac generated ($alg)");

    ok($m->verify($mac, $msg, $key), "message verified with mac and key ($alg)");

  }

}

done_testing();
