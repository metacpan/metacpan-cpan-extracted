#!perl -T

=head1 PURPOSE

Make sure that get_readonly_fields() returns the arrayref of read-only fields
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
	'get_readonly_fields',
);

# Verify inheritance.
can_ok(
	'TestSubclass::Accessors',
	'get_readonly_fields',
);

# Tests.
my $tests =
[
	{
		name     => 'Test calling get_readonly_fields() on DBIx::NinjaORM',
		ref      => 'DBIx::NinjaORM',
		expected => [],
	},
	{
		name     => 'Test calling get_readonly_fields() on TestSubclass::Accessors',
		ref      => 'TestSubclass::Accessors',
		expected => [ 'test' ],
	},
	{
		name     => 'Test calling get_readonly_fields() on an object',
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

			my $readonly_fields;
			warning_like(
				sub
				{
					$readonly_fields = $test->{'ref'}->get_readonly_fields();
				},
				{ carped => qr/has been deprecated/ },
				'The method is deprecated.',
			);

			is_deeply(
				$readonly_fields,
				$test->{'expected'},
				'get_readonly_fields() returns the value set up in static_class_info().',
			);
		}
	);
}
