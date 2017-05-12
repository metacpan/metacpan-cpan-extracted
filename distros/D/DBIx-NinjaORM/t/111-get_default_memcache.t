#!perl -T

=head1 PURPOSE

Make sure that get_memcache() returns the memcache object specified in the
static class information.

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
	'get_memcache',
);

# Verify inheritance.
can_ok(
	'TestSubclass::Accessors',
	'get_memcache',
);

# Tests.
my $tests =
[
	# We need to support $class->get_memcache() calls.
	{
		name => 'Test calling get_memcache() on the class',
		ref  => 'TestSubclass::Accessors',
	},
	# We need to support $object->get_memcache() calls.
	{
		name => 'Test calling get_memcache() on an object',
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

			my $memcache;
			warning_like(
				sub
				{
					$memcache = $test->{'ref'}->get_memcache();
				},
				{ carped => qr/has been deprecated/ },
				'The method is deprecated.',
			);

			is(
				$memcache,
				'TESTMEMCACHE',
				'get_memcache() returns the value set up in static_class_info().',
			);
		}
	);
}
