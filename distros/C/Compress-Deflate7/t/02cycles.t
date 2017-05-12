use strict;
use warnings;

use Test::More tests => 151;
BEGIN { use_ok('Compress::Deflate7') };

use Compress::Zlib;

sub inflate_helper {
  my ($deflated) = @_;
  my ($i, $status) = inflateInit;
  ok(!$status);
  my ($out, $status2) = $i->inflate($deflated);
  ok(!$status);
  return $out;
}

for (1 .. 50) {
  my $algo = int(rand(2));
  my $pass = 1 + int(rand(15));
  my $fast = 3 + int(rand(256));
  my $cycl = 1 + int(rand(258));
  my $rand = join "", map { chr(int(rand(128))) } 0 .. int(rand(66000));
  my $defl = Compress::Deflate7::zlib7($rand,
    Algorithm => $algo,
    Pass => $pass,
    FastBytes => $fast,
    Cycles => $cycl);
  is($rand, inflate_helper($defl));
}
