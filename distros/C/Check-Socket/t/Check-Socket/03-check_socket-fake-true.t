use strict;
use warnings;

use Check::Socket qw(check_socket);
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $test_config = {};
my $test_os = 'linux';
my $test_env = {};
my $ret = check_socket($test_config, $test_os, $test_env);
is($ret, 1, 'Tests the successful socket communication on Linux.');
