# $Id: 70-meta-yaml.t 49 2014-05-02 11:30:14Z adam $

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
