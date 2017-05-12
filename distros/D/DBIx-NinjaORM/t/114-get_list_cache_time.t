#!perl -T

=head1 PURPOSE

Make sure that get_list_cache_time() returns the list cache time specified in
the static class information.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;
use Test::Type;
use Test::Warn;
use TestSubclass::Accessors;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'get_list_cache_time',
);

# Verify inheritance.
can_ok(
	'TestSubclass::Accessors',
	'get_list_cache_time',
);

# Tests.
my $tests =
[
	{
		name     => 'Test calling get_list_cache_time() on DBIx::NinjaORM',
		ref      => 'DBIx::NinjaORM',
		expected => undef,
	},
	{
		name     => 'Test calling get_list_cache_time() on TestSubclass::Accessors',
		ref      => 'TestSubclass::Accessors',
		expected => 20,
	},
	{
		name     => 'Test calling get_list_cache_time() on an object',
		ref      => bless( {}, 'TestSubclass::Accessors' ),
		expected => 20,
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

			my $list_cache_time;
			warning_like(
				sub
				{
					$list_cache_time = $test->{'ref'}->get_list_cache_time();
				},
				{ carped => qr/has been deprecated/ },
				'The method is deprecated.',
			);

			is(
				$list_cache_time,
				$test->{'expected'},
				'get_list_cache_time() returns the value set up in static_class_info().',
			);
		}
	);
}
