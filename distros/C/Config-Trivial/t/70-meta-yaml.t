# $Id: 70-meta-yaml.t 51 2014-05-21 19:14:11Z adam $

use strict;
use Test;

my $run_tests;

BEGIN {
    $run_tests = eval { require YAML; };
    plan tests => 1
};

if (! $run_tests) {
    skip "YAML not installed, skipping test.";
    exit;
}

ok(YAML::LoadFile('./META.yml'));
