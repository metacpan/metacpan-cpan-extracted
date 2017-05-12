#!perl -T

=head1 PURPOSE

Test the C<update()> method on C<DBIx::NinjaORM> objects.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 9;
use Test::Type;
use TestSubclass::NoPK;
use TestSubclass::NoTableName;
use TestSubclass::TestTable;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'update',
);

# Verify inheritance.
can_ok(
	'TestSubclass::TestTable',
	'update',
);

# We set the creation time for the test record 10 seconds in the past to be
# able to make sure that calls to update() leave the 'created' field
# unaffected.
my $created_time = time() - 10;

# Insert a test object.
my $object;
subtest(
	'Create test object and insert the corresponding test row.',
	sub
	{
		ok(
			$object = TestSubclass::TestTable->new(),
			'Create new object.',
		);

		lives_ok(
			sub
			{
				$object->insert(
					{
						name => 'test_update_' . $created_time,
					},
					overwrite_created => $created_time,
				);
			},
			'Insert succeeds.',
		);
	}
);

subtest(
	'The first argument must be a hashref.',
	sub
	{
		plan( tests => 2 );

		# Copy the test object, to leave the original intact and prevent
		# bleeding between tests.
		ok(
			defined(
				my $object_copy = Storable::dclone( $object )
			),
			'Copy the test object.',
		);

		dies_ok(
			sub
			{
				$object_copy->update(
					name => 'value',
				);
			},
			'Update fails.',
		);
	}
);

subtest(
	'The table name must be defined in static_class_info().',
	sub
	{
		plan( tests => 3 );

		# Copy the test object, to leave the original intact and prevent
		# bleeding between tests.
		ok(
			defined(
				my $object_copy = Storable::dclone( $object )
			),
			'Copy the test object.',
		);

		# Re-bless the object with the class that has no table name
		# defined.
		ok(
			bless(
				$object_copy,
				'TestSubclass::NoTableName',
			),
			'Re-bless the object with a class that has no table name defined.',
		);

		dies_ok(
			sub
			{
				$object_copy->update(
					{
						name => 'value',
					}
				)
			},
			'Update fails.',
		);
	}
);

subtest(
	'The primary key name must be defined in static_class_info().',
	sub
	{
		plan( tests => 3 );

		# Copy the test object, to leave the original intact and prevent
		# bleeding between tests.
		ok(
			defined(
				my $object_copy = Storable::dclone( $object )
			),
			'Copy the test object.',
		);

		# Re-bless the object with the class that has no primary key
		# name defined.
		ok(
			bless(
				$object_copy,
				'TestSubclass::NoPK',
			),
			'Re-bless the object with a class that has no primary key name defined.',
		);

		dies_ok(
			sub
			{
				$object_copy->update(
					{
						name => 'value',
					}
				);
			},
			'Update fails.',
		);
	}
);

lives_ok(
	sub
	{
		$object->update(
			{
				name => 'test_update_' . time(),
			}
		);
	},
	'Update succeeds',
);

is(
	$object->{'created'},
	$created_time,
	"The 'created' field was not affected.",
) || diag( explain( $object ) );

ok(
	( time() - $object->{'modified'} ) < 2,
	"The 'modified' field was set in the last two seconds.",
) || diag( explain( $object ) );
