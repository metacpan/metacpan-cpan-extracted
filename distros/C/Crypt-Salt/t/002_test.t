# -*- perl -*-

# t/001_load.t - check module loading and create testing directory

use Test::More tests => 1000;

use Crypt::Salt;

for(1..500) { ok salt() =~ m/^[a-zA-Z0-9\.\/]{2,2}$/, "default call" }

for(1..500) {
  my $want_length = int(rand(10))+1;
  my $salt_return = salt($want_length);
  if ($salt_return =~ m/^[a-zA-Z0-9\.\/]{$want_length}$/) {
    ok(1);
  } else {
    warn "Salt returned '$salt_return', which is not $want_length characters of salt.\n";
    ok(0, "specific length call");
  }
}
  
