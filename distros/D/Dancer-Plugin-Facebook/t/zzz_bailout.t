#!/usr/bin/perl
use strict;
use warnings;
use Test::More;
if ($ENV{FORCE_FAIL}) {
    BAIL_OUT ("Don't want our test results deleted out from under us");
} else {
    plan skip_all => "Use ./acceptance -n to preserve build dir";
}

done_testing;
