# Simple test to check the speed of Crypt::CAST5_PP

use strict;
use warnings;

use lib "blib/lib";
use Crypt::CAST5_PP;
use Time::HiRes qw( gettimeofday tv_interval );

my ($cast5, $start, $end, $text, $i);
$cast5 = Crypt::CAST5_PP->new();

$cast5->init(pack "H*", "12345678901234567890");
$start = [ gettimeofday() ];
for ($i = 0; $i < 10_000; $i++) {
  $text = pack "n4", $i, $i, $i, $i;
  $cast5->encrypt($text);
}
$end = [ gettimeofday() ];
print "Time for 10k 80-bit encryptions: ", tv_interval($start, $end), " sec\n";

$cast5->init(pack "H*", "0123456789abcdef0123456789abcdef");
$start = [ gettimeofday() ];
for ($i = 0; $i < 10_000; $i++) {
  $text = pack "n4", $i, $i, $i, $i;
  $cast5->encrypt($text);
}
$end = [ gettimeofday() ];
print "Time for 10k 128-bit encryptions: ", tv_interval($start, $end), " sec\n";

# end speedtest.pl
