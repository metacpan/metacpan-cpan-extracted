# Simple test to check the speed of Crypt::CAST5_PP

# To run, cd to the Crypt-CAST5-x.xx directory and type
#     make
#     perl test/speedtest.pl

use strict;
use warnings;

use lib "blib/lib";
use lib "blib/arch";
use Crypt::CAST5;
use Time::HiRes qw( gettimeofday tv_interval );

my ($cast5, $start, $end, $text, $i);
$cast5 = Crypt::CAST5->new();

$cast5->init(pack "H*", "12345678901234567890");
$start = [ gettimeofday() ];
for ($i = 0; $i < 100_000; $i++) {
  $text = pack "n4", $i, $i, $i, $i;
  $cast5->encrypt($text);
}
$end = [ gettimeofday() ];
print "Time for 100k 80-bit encryptions: ", tv_interval($start, $end), " sec\n";

$cast5->init(pack "H*", "0123456789abcdef0123456789abcdef");
$start = [ gettimeofday() ];
for ($i = 0; $i < 100_000; $i++) {
  $text = pack "n4", $i, $i, $i, $i;
  $cast5->encrypt($text);
}
$end = [ gettimeofday() ];
print "Time for 100k 128-bit encryptions: ", tv_interval($start, $end), " sec\n";

# end speedtest.pl
