#!perl -T

=head1 PURPOSE

Test the flatten_object() method.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 8;
use Test::Type;
use TestSubclass::TestTable;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'flatten_object',
);

# Verify inheritance.
can_ok(
	'TestSubclass::TestTable',
	'flatten_object',
);

# Insert an object we'll use for tests here.
my $object_id;
subtest(
	'Test id() after inserting an object.',
	sub
	{
		plan( tests => 3 );

		ok(
			defined(
				my $object = TestSubclass::TestTable->new()
			),
			'Create new object.',
		);

		lives_ok(
			sub
			{
				$object->insert(
					{
						name => 'test_flatten_' . time(),
					}
				)
			},
			'Insert succeeds.',
		);

		isnt(
			$object->id(),
			undef,
			'id() returns a defined value.',
		);

		$object_id = $object->id();
	}
);

# Retrieve object.
ok(
	defined(
		my $object = TestSubclass::TestTable->new(
			{ id => $object_id },
		)
	),
	'Retrieve the object previously inserted.',
);

# List of keys to flatten.
my $flatten_keys =
[
	qw(
		name
		test_id
	)
];

# Flatten.
subtest(
	'Flatten regular fields.',
	sub
	{
		plan( tests => 3 );

		my $flattened_object;
		lives_ok(
			sub
			{
				$flattened_object = $object->flatten_object(
					$flatten_keys
				);
			},
			'Flatten the object.',
		);

		ok_hashref(
			$flattened_object,
			name => 'The flattened object.',
		);

		cmp_deeply(
			[ sort keys %$flattened_object ],
			$flatten_keys,
			'The output of flatten() matches the requested fields.',
		);
	}
);

throws_ok(
	sub
	{
		$object->flatten_object(
			[ 'password' ],
		);
	},
	qr/The fields 'password' is protected and cannot be added to the flattened copy/,
	'Cannot flatten protected fields.',
);

throws_ok(
	sub
	{
		$object->flatten_object(
			[ '_test' ],
		);
	},
	qr/The field '_test' is hidden and cannot be added to the flattened copy/,
	'Cannot flatten private fields.',
);

subtest(
	'Flatten the ID field using the "id" shortcut.',
	sub
	{
		plan( tests => 3 );

		my $flattened_object;
		lives_ok(
			sub
			{
				$flattened_object = $object->flatten_object(
					[ 'id' ],
				);
			},
			'Flatten the object.',
		);

		ok_hashref(
			$flattened_object,
			name => 'The flattened object.',
		);

		cmp_deeply(
			$flattened_object,
			{
				id => $object->id(),
			},
			'The output of flatten() matches the requested fields.',
		);
	}
);
