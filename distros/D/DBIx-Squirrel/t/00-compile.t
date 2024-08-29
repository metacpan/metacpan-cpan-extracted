use 5.010_001;
use strict;
use warnings;
use Test::Compile;
 
my @scripts = (
    'examples/transformations/01.pl',
    'examples/transformations/02.pl',
    'examples/transformations/03.pl',
);
my $test = Test::Compile->new;
$test->all_files_ok;
$test->pl_file_compiles($_) for @scripts;
$test->done_testing;
