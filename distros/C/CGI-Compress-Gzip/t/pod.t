#!perl
use warnings;
use strict;
use Test::More;

if ((!$ENV{AUTHOR_TEST} && !$ENV{AUTHOR_TEST_CDOLAN}) ||
    $ENV{AUTOMATED_TESTING})
{
   plan skip_all => 'Author test';
}
eval 'use Test::Pod 1.14';
plan skip_all => 'Optional Test::Pod 1.14 not found' if $@;
all_pod_files_ok();
