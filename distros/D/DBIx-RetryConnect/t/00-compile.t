use strict;
use warnings;

use Test::Compile v1.1.0;

my $test = Test::Compile->new();
$test->all_files_ok('lib', 'blib');

$test->done_testing();

