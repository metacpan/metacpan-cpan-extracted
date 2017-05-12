use strict;
use warnings;
use lib 'lib';

use Benchmark;
use DPKG::Log;
use Data::Dumper;
use Test::More;

BEGIN {
    unless ($ENV{'RELEASE_TESTING'}) {
        Test::More::plan(skip_all => 'these tests are for testing by the author');
    } else {
        Test::More::plan(tests => 2);
    }
}
my ($t1, $t2, $td);
my $dpkg_log = DPKG::Log->new(filename =>'test_data/dpkg.log');
$t1 = Benchmark->new();
$dpkg_log->parse;
$t2 = Benchmark->new();
$td = timediff($t2, $t1);
my ($r) = @$td;
my $time_expect = 1;
ok($r <= $time_expect, "Parsing a small log file takes <= $time_expect wallclock second(s)");

$dpkg_log = DPKG::Log->new(filename =>'test_data/big.log');
$t1 = Benchmark->new();
$dpkg_log->parse;
$t2 = Benchmark->new();
$td = timediff($t2, $t1);
($r) = @$td;
$time_expect = 20;
ok($r <= $time_expect, "Parsing a big log file takes <= $time_expect wallclock second(s)")
    or diag "Parsing took $time_expect\n";


