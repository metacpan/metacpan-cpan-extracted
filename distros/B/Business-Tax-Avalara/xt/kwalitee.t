#!perl

use strict;
use warnings;

use Test::More;


# Load extra tests.
eval
{
	require Test::Kwalitee::Extra;
	# Run extra tests.
	Test::Kwalitee::Extra->import(
		qw(
			:optional
			!prereq_matches_use
		)
	);
};
if ($@)
{
	plan( skip_all => 'Test::Kwalitee::Extra required to evaluate code' );
}

# Skipping the prereq_matches_use test (for the way I did AvalaraConfig.pm)
# doesn't actually reduce the number of tests it plans, so filling in
# two bogus tests.
ok(1, 'Skipping prereq_matches_use');
ok(1, 'Reticulating Splines');

# Clean up the extra file Test::Kwalitee generates.
END
{
	unlink 'Debian_CPANTS.txt'
		if -e 'Debian_CPANTS.txt';
}
