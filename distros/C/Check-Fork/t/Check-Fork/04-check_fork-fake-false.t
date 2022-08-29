use strict;
use warnings;

use Check::Fork qw(check_fork $ERROR_MESSAGE);
use Test::More 'tests' => 9;
use Test::NoWarnings;

# Test.
my $test_config = {
	'd_fork' => undef,
	'd_pseudofork' => undef,
};
my $test_os = 'linux';
my $ret = check_fork($test_config, $test_os);
is($ret, 0, 'Test not forking on linux.');
is($ERROR_MESSAGE, 'No fork() routine available.', 'Test error message.');

# Test.
$test_config = {
	'ccflags' => '-DPERL_IMPLICIT_SYS',
	'useithreads' => undef,
};
$test_os = 'MSWin32';
$ret = check_fork($test_config, $test_os);
is($ret, 0, 'Test not forking on Windows without itrhreads.');
is($ERROR_MESSAGE, 'MSWin32: No interpreter-based threading implementation.',
	'Test error message on Window');

# Test.
$test_config = {
	'ccflags' => '-DPERL_IMPLICIT_SYS',
	'useithreads' => undef,
};
$test_os = 'NetWare';
$ret = check_fork($test_config, $test_os);
is($ret, 0, 'Test not forking on NetWare without itrhreads.');
is($ERROR_MESSAGE, 'NetWare: No interpreter-based threading implementation.',
	'Test error message on NetWare');

# Test.
$test_config = {
	'ccflags' => '',
	'useithreads' => 'define',
};
$test_os = 'MSWin32';
$ret = check_fork($test_config, $test_os);
is($ret, 0, 'Test not forking on Windows.');
is($ERROR_MESSAGE, 'MSWin32: No PERL_IMPLICIT_SYS ccflags set.',
	'Test error message on Window without PERL_IMPLICIT_SYS ccflags set.');
