#!perl -T

=head1 PURPOSE

Test the id() method, which is a shortcut to get the value of the primary key
for a given object.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;
use TestSubclass::TestTable;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'id',
);

# Verify inheritance.
can_ok(
	'TestSubclass::TestTable',
	'id',
);

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
						name => 'test_id_' . time(),
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

subtest(
	'Test id() after retrieve_list().',
	sub
	{
		plan( tests => 3 );

		ok(
			defined(
				my $objects = TestSubclass::TestTable->retrieve_list(
					{
						id => $object_id,
					}
				)
			),
			'Retrieve the object previously inserted.',
		);

		is(
			scalar( @$objects ),
			1,
			'Found object.',
		);

		is(
			$objects->[0]->id(),
			$object_id,
			'id() on the retrieved object matches the ID used to retrieve it.',
		);
	}
);
