#!perl

use strict;
use Test::More;
use Test::Strict;

$Test::Strict::DEVEL_COVER_OPTIONS = '-coverage,statement,branch,condition,path,subroutine,time,+ignore,"/Test/Strict\b"';

if ($ENV{TEST_AUTHOR}) {
    all_cover_ok 99;
} else {
    plan skip_all => 'Author test. Set $ENV{TEST_AUTHOR} to a true value to run.';
}
