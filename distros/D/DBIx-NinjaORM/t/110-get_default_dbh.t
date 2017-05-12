#!perl -T

=head1 PURPOSE

Make sure that get_default_dbh() returns the database handle
specified in the static class information.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;
use Test::Warn;
use TestSubclass::Accessors;


# Make sure that get_default_dbh() is supported by DBIx::NinjaORM.
can_ok(
	'DBIx::NinjaORM',
	'get_default_dbh',
);

# Verify inheritance.
can_ok(
	'TestSubclass::Accessors',
	'get_default_dbh',
);

my $tests =
[
	# We need to support $class->get_default_dbh() calls.
	{
		name => 'Test calling get_default_dbh() on the class',
		ref  => 'TestSubclass::Accessors',
	},
	# We need to support $object->get_default_dbh() calls.
	{
		name => 'Test calling get_default_dbh() on an object',
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

			my $default_dbh;
			warning_like(
				sub
				{
					$default_dbh = $test->{'ref'}->get_default_dbh();
				},
				{ carped => qr/has been deprecated/ },
				'The method is deprecated.',
			);

			is(
				$default_dbh,
				'TESTDBH',
				'get_default_dbh() returns the value set up in static_class_info().',
			);
		}
	);
}
