#!perl -T

=head1 PURPOSE

Make sure that get_primary_key_name() returns the name of the primary key
specified in the static class information.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;
use Test::Type;
use Test::Warn;
use TestSubclass::Accessors;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'get_primary_key_name',
);

# Verify inheritance.
can_ok(
	'TestSubclass::Accessors',
	'get_primary_key_name',
);

# Tests.
my $tests =
[
	{
		name => 'Test calling get_primary_key_name() on the class',
		ref  => 'TestSubclass::Accessors',
	},
	{
		name => 'Test calling get_primary_key_name() on an object',
		ref  => bless( {}, 'TestSubclass::Accessors' ),
	},
];

# Run tests.
foreach my $test ( @$tests )
{
	subtest(
		$test->{'name'},
		sub
		{
			plan( tests => 2 );

			my $primary_key_name;
			warning_like(
				sub
				{
					$primary_key_name = $test->{'ref'}->get_primary_key_name();
				},
				{ carped => qr/has been deprecated/ },
				'The method is deprecated.',
			);

			is(
				$primary_key_name,
				'TEST_PRIMARY_KEY_NAME',
				'get_primary_key_name() returns the value set up in static_class_info().',
			);
		}
	);
}
