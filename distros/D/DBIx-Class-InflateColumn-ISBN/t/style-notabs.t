#!perl -T
use strict;
use warnings;

use Test::More;

if (not $ENV{TEST_AUTHOR}) {
    plan skip_all => 'set TEST_AUTHOR to enable this test';
}
else {
    eval 'use Test::NoTabs 0.03';
    if ($@) {
        plan skip_all => 'Test::NoTabs 0.03 not installed';
    }
    else {
        plan tests => 1;
    }
}

all_perl_files_ok('lib');
