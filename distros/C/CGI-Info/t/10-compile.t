#!perl -w

use strict;
use warnings;

use lib 'lib';

use Test::Compile;
my $test = Test::Compile->new();
$test->all_files_ok();
$test->done_testing();
