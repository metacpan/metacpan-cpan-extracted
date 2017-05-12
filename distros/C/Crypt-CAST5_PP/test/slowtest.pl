# The full maintenance test from rfc2144
# This test takes a long time to complete

use Test::More tests => 2;
use lib "blib/lib";
use Crypt::CAST5_PP;
my $cast5 = Crypt::CAST5_PP->new();

my $al = pack "H*", "0123456712345678";
my $ar = pack "H*", "234567893456789a";
my $bl = $al;
my $br = $ar;

for (my $i = 1; $i <= 1_000_000; $i++) {
  $cast5->init($bl.$br);
  $al = $cast5->encrypt($al);
  $ar = $cast5->encrypt($ar);
  $cast5->init($al.$ar);
  $bl = $cast5->encrypt($bl);
  $br = $cast5->encrypt($br);
}

my $a = unpack "H*", $al.$ar;
my $b = unpack "H*", $bl.$br;
is($a, "eea9d0a249fd3ba6b3436fb89d6dca92", "register 'a'");
is($b, "b2c95eb00c31ad7180ac05b8e83d696e", "register 'b'");

# end slowtest.pl
