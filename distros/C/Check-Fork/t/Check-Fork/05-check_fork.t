use strict;
use warnings;

use Check::Fork qw(check_fork $ERROR_MESSAGE);
use Config;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $ret = check_fork;
if ($Config{'d_fork'}) {
	is_with_diag($ret, 1, 'Test for successful forking (d_fork).');
} elsif ($Config{'d_pseudofork'}) {
	is_with_diag($ret, 1, 'Test for successful forking (d_pseudofork).');
} else {
	is_with_diag($ret, 1, 'TODO: Support for other real example.');
}

sub is_with_diag {
	my ($ret, $expected, $message) = @_;

	is($ret, $expected, $message);
	diag($message);

	return;
}
