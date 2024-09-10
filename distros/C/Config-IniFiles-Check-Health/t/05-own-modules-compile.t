#!perl
use strict;
use warnings;
use Test::Compile;

# Tests wether my own perl-modules at least compile
my $test = Test::Compile->new();
my @dirs;
push @dirs, 'lib';
$test->all_files_ok(@dirs);
$test->done_testing();
