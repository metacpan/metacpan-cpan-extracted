#!perl -T

=head1 PURPOSE

Make sure that get_info() returns the values from StaticClassInfo.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 3;
use TestSubclass::Accessors;


# Make sure that get_info() is supported by DBIx::NinjaORM.
can_ok(
	'DBIx::NinjaORM',
	'get_info',
);

my $contexts =
[
	# We need to support calls on the class.
	{
		name => 'Test calls to get_info() on the class.',
		ref  => 'TestSubclass::Accessors',
	},
	# We need to support calls on the object.
	{
		name => 'Test calling get_info() on an object',
		ref  => bless( {}, 'TestSubclass::Accessors' ),
	},
];

# Run tests in each context.
foreach my $context ( @$contexts )
{
	subtest(
		$context->{'name'},
		sub
		{
			my $caller = $context->{'ref'};

			plan( tests => 2 );

			# Make sure the call is supported.
			can_ok(
				$caller,
				'get_info',
			);

			# Make sure the primary key name is correct.
			is(
				$caller->get_info('primary_key_name'),
				'TEST_PRIMARY_KEY_NAME',
				'The primary key name is correct.',
			);
		}
	);
}
