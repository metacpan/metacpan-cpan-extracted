#!perl

use strict;
use warnings;

use Test::More;

if ( ! $ENV{TEST_AUTHOR} ) {
    my $msg = 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
    plan( skip_all => $msg );
}

eval "use Test::Prereq::Build";
plan skip_all => "Test::Prereq::Build required to test dependencies" if $@;
prereq_ok();
