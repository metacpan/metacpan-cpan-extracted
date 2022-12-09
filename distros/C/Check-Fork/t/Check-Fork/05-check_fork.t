use strict;
use warnings;

use Check::Fork qw(check_fork $ERROR_MESSAGE);
use Config;
use Test::More 'tests' => 2;
use Test::NoWarnings;

# Test.
my $ret = check_fork;
if ($Config{'d_fork'}) {
	is($ret, 1, 'Test for successful forking (d_fork).');
	diag('Test for successful forking (d_fork).');
} elsif ($Config{'d_pseudofork'}) {
	is($ret, 1, 'Test for successful forking (d_pseudofork).');
	diag('Test for successful forking (d_pseudofork).');
} else {
	ok(1, 'TODO: Support for other real example.');
	diag('TODO: Support for other real example.');
}
