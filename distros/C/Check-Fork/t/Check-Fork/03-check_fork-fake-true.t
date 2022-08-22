use strict;
use warnings;

use Check::Fork qw(check_fork);
use Test::More 'tests' => 5;
use Test::NoWarnings;

# Test.
my $test_config = {
	'd_fork' => 'define',
};
my $test_os = 'linux';
my $ret = check_fork($test_config, $test_os);
is($ret, 1, "Test 'd_fork' variable on linux.");

# Test.
$test_config = {
	'd_pseudofork' => 'define',
};
$ret = check_fork($test_config, $test_os);
is($ret, 1, "Test 'd_pseudofork' variable on linux.");

# Test.
$test_config = {
	'ccflags' => '-DPERL_IMPLICIT_SYS',
	'useithreads' => 'define',
};
$test_os = 'MSWin32';
$ret = check_fork($test_config, $test_os);
is($ret, 1, 'Test threading on Windows.');

# Test.
$test_config = {
	'ccflags' => '-DPERL_IMPLICIT_SYS',
	'useithreads' => 'define',
};
$test_os = 'NetWare';
$ret = check_fork($test_config, $test_os);
is($ret, 1, 'Test threading on NetWare.');
