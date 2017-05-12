#!perl -T

=head1 PURPOSE

Test inserting rows via the objects.

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
	'insert',
);

# Verify inheritance.
can_ok(
	'TestSubclass::TestTable',
	'insert',
);

subtest(
	'The first argument must be a hashref.',
	sub
	{
		ok(
			my $object = TestSubclass::TestTable->new(),
			'Create new object.',
		);

		dies_ok(
			sub
			{
				$object->insert(
					field => 'value',
				);
			},
			'The first argument must be a hashref.',
		);
	}
);

subtest(
	'The table name must be defined in static_class_info().',
	sub
	{
		ok(
			my $object = TestSubclass::NoTableName->new(),
			'Create new object.',
		);

		dies_ok(
			sub
			{
				$object->insert(
					{
						field => 'value',
					}
				);
			},
			'Insert fails.',
		);
	}
);

subtest(
	'The primary key name must be defined in static_class_info().',
	sub
	{
		ok(
			my $object = TestSubclass::NoPK->new(),
			'Create new object.',
		);

		dies_ok(
			sub
			{
				$object->insert(
					{
						field => 'value',
					}
				);
			},
			'Insert fails.',
		);
	}
);

my $object;
subtest(
	'Insert with correct information.',
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
						name => 'test_insert_' . time(),
					}
				);
			},
			'Insert succeeds.',
		);
	}
);

ok(
	$object->{'created'} > 0,
	"The 'created' field was auto-populated.",
) || diag( explain( $object ) );

ok(
	$object->{'modified'} > 0,
	"The 'modified' field was auto-populated.",
) || diag( explain( $object ) );

isnt(
	$object->id(),
	undef,
	'The auto-increment field was populated.',
);
