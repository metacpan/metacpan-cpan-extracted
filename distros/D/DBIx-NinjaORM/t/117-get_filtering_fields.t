#!perl -T

=head1 PURPOSE

Make sure that get_filtering_fields() returns the arrayref of filtering fields
specified in the static class information.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;
use TestSubclass::Accessors;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'get_filtering_fields',
);

# Verify inheritance.
can_ok(
	'TestSubclass::Accessors',
	'get_filtering_fields',
);

# Tests.
my $tests =
[
	{
		name     => 'Test calling get_filtering_fields() on DBIx::NinjaORM',
		ref      => 'DBIx::NinjaORM',
		expected => [],
	},
	{
		name     => 'Test calling get_filtering_fields() on TestSubclass::Accessors',
		ref      => 'TestSubclass::Accessors',
		expected => [ 'test' ],
	},
	{
		name     => 'Test calling get_filtering_fields() on an object',
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

			my $filtering_fields;
			lives_ok(
				sub
				{
					$filtering_fields = $test->{'ref'}->get_filtering_fields();
				},
				'Retrieve the list cache time.',
			);

			is_deeply(
				$filtering_fields,
				$test->{'expected'},
				'get_filtering_fields() returns the value set up in static_class_info().',
			);
		}
	);
}
