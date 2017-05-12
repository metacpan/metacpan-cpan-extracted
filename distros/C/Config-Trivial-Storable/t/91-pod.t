#	$Id: 91-pod.t 49 2014-05-02 11:30:14Z adam $

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

my $pc = Pod::Coverage->new(package => 'Config::Trivial::Storable');
ok($pc->coverage == 1);
