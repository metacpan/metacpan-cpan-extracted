#	$Id: 91-pod.t 51 2014-05-21 19:14:11Z adam $

use strict;
use Test;

my $run_tests;

BEGIN {
    $run_tests = eval { require Pod::Coverage; };
    plan tests => 1
};

if (! $run_tests) {
    skip "Pod::Coverage not installed, skipping test.";
    exit;
}

my $pc = Pod::Coverage->new(package => 'Config::Trivial');
ok($pc->coverage == 1);
