#!perl

use strict;
use warnings;
use Test::More;

unless ($ENV{RELEASE_TESTING}) {
    plan(skip_all => "these tests are for release candidate testing");
}

eval "use Test::Kwalitee 'kwalitee_ok'";
plan skip_all => 'Test::Kwalitee required to test kwalitee' if $@;

kwalitee_ok();
done_testing;
