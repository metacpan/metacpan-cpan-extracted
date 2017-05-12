#!perl -T

=head1 PURPOSE

Test removing rows via the objects.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 7;
use Test::Type;
use TestSubclass::NoPK;
use TestSubclass::NoTableName;
use TestSubclass::TestTable;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'remove',
);

# Verify inheritance.
can_ok(
	'TestSubclass::TestTable',
	'remove',
);

# Test that remove() requires a table name.
subtest(
	'The table name must be defined in static_class_info().',
	sub
	{
		ok(
			my $object = TestSubclass::NoTableName->new(),
			'Create new object.',
		);

		throws_ok(
			sub
			{
				$object->remove();
			},
			qr/The table name for class 'TestSubclass::NoTableName' is not defined/,
			'remove() fails.',
		);
	}
);

# Test that remove() requires a primary key name.
subtest(
	'The primary key name must be defined in static_class_info().',
	sub
	{
		ok(
			my $object = TestSubclass::NoPK->new(),
			'Create new object.',
		);

		throws_ok(
			sub
			{
				$object->remove();
			},
			qr/Missing primary key name for class 'TestSubclass::NoPK', cannot delete safely/,
			'Insert fails.',
		);
	}
);

# Test that remove() requires a primary key value.
subtest(
	'The primary key value must be defined.',
	sub
	{
		ok(
			defined(
				my $object = TestSubclass::TestTable->new()
			),
			'Create new object.',
		);

		throws_ok(
			sub
			{
				$object->remove();
			},
			qr/The object of class 'TestSubclass::TestTable' does not have a primary key value, cannot delete/,
			'remove() fails.',
		);
	}
);

# Insert a test object.
my $object;
subtest(
	'Insert test object.',
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
						name => 'test_remove_' . time(),
					}
				);
			},
			'Insert succeeds.',
		);
	}
);

# This object has a table name, primary key name and primary key value set
# properly. We should be able to delete it without issues.
lives_ok(
	sub
	{
		$object->remove();
	},
	'Remove object.',
);
