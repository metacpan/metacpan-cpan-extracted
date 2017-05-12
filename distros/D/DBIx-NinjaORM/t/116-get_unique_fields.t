#!perl -T

=head1 PURPOSE

Make sure that get_unique_fields() returns the arrayref of unique fields
specified in the static class information.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::Deep;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;
use Test::Warn;
use TestSubclass::Accessors;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'get_unique_fields',
);

# Verify inheritance.
can_ok(
	'TestSubclass::Accessors',
	'get_unique_fields',
);

# Tests.
my $tests =
[
	{
		name     => 'Test calling get_unique_fields() on DBIx::NinjaORM',
		ref      => 'DBIx::NinjaORM',
		expected => [],
	},
	{
		name     => 'Test calling get_unique_fields() on TestSubclass::Accessors',
		ref      => 'TestSubclass::Accessors',
		expected => [ 'test' ],
	},
	{
		name     => 'Test calling get_unique_fields() on an object',
		ref      => bless( {}, 'TestSubclass::Accessors' ),
		expected => [ 'test' ],
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

			my $unique_fields;
			warning_like(
				sub
				{
					$unique_fields = $test->{'ref'}->get_unique_fields();
				},
				{ carped => qr/has been deprecated/ },
				'The method is deprecated.',
			);

			is_deeply(
				$unique_fields,
				$test->{'expected'},
				'get_unique_fields() returns the value set up in static_class_info().',
			);
		}
	);
}
