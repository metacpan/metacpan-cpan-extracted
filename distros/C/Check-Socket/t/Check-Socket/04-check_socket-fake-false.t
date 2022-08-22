use strict;
use warnings;

use Check::Socket qw(check_socket $ERROR_MESSAGE);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $test_config = {};
my $test_os = 'qnx';
my $test_env = {};
my $ret = check_socket($test_config, $test_os, $test_env);
is($ret, 0, 'Tests the impossibility of socket communication on QNX.');
is($ERROR_MESSAGE, 'qnx: UNIX domain sockets not implemented.', 'Test error message.');

# Test.
$test_config = {};
$test_os = 'nto';
$test_env = {};
$ret = check_socket($test_config, $test_os, $test_env);
is($ret, 0, 'Tests the impossibility of socket communication on NTO.');
is($ERROR_MESSAGE, 'nto: UNIX domain sockets not implemented.', 'Test error message.');

# Test.
$test_config = {};
$test_os = 'vos';
$test_env = {};
$ret = check_socket($test_config, $test_os, $test_env);
is($ret, 0, 'Tests the impossibility of socket communication on VOS.');
is($ERROR_MESSAGE, 'vos: UNIX domain sockets not implemented.', 'Test error message.');

# Test.
$test_config = {};
$test_os = 'MSWin32';
$test_env = {
	'CONTINUOUS_INTEGRATION' => 1,
};
$ret = check_socket($test_config, $test_os, $test_env);
is($ret, 0, 'Tests the impossibility of socket communication on Windows in CI mode.');
is($ERROR_MESSAGE, 'MSWin32: Skip sockets on CI.', 'Test error message.');
