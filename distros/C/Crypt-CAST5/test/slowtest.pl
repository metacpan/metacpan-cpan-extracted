# The full maintenance test from rfc2144
# This test takes a few minutes to run

# To run, cd to the Crypt-CAST5-x.xx directory and type
#     make
#     perl test/slowtest.pl

use Test::More tests => 4;
use lib "blib/lib";
use lib "blib/arch";
use Crypt::CAST5;
my $cast5 = Crypt::CAST5->new();

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
is($a, "eea9d0a249fd3ba6b3436fb89d6dca92", "encrypt, register 'a'");
is($b, "b2c95eb00c31ad7180ac05b8e83d696e", "encrypt, register 'b'");

$al = pack "H*", "eea9d0a249fd3ba6";
$ar = pack "H*", "b3436fb89d6dca92";
$bl = pack "H*", "b2c95eb00c31ad71";
$br = pack "H*", "80ac05b8e83d696e";

for (my $i = 1; $i <= 1_000_000; $i++) {
  $cast5->init($al.$ar);
  $bl = $cast5->decrypt($bl);
  $br = $cast5->decrypt($br);
  $cast5->init($bl.$br);
  $al = $cast5->decrypt($al);
  $ar = $cast5->decrypt($ar);
}

$a = unpack "H*", $al.$ar;
$b = unpack "H*", $bl.$br;
is($a, "0123456712345678234567893456789a", "decrypt, register 'a'");
is($b, "0123456712345678234567893456789a", "decrypt, register 'b'");

# end slowtest.pl
