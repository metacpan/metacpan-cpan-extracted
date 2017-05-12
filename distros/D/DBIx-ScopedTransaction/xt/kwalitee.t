#!perl

use strict;
use warnings;

use Test::More;


# Load module.
eval
{
	require Test::Kwalitee::Extra;
};
plan( skip_all => 'Test::Kwalitee::Extra required to evaluate code' )
	if $@;

# Run extra tests.
Test::Kwalitee::Extra->import(
	qw(
		:optional
	)
);

# Clean up the additional file Test::Kwalitee::Extra generates.
END
{
	unlink 'Debian_CPANTS.txt'
		if -e 'Debian_CPANTS.txt';
}
