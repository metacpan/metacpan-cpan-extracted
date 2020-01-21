use 5.012;
use warnings;
use Test::More;
use lib 't/lib';
use TestAllZones;

TestAllZones::go();

done_testing();
