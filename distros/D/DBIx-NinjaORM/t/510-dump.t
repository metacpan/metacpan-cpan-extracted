#!perl -T

=head1 PURPOSE

Test the dump() method.

=cut

use strict;
use warnings;

use lib 't/lib';

use DBIx::NinjaORM;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 6;
use Test::Type;
use TestSubclass::TestTable;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'dump',
);

# Verify inheritance.
can_ok(
	'TestSubclass::TestTable',
	'dump',
);

# Insert an object we'll use for tests here.
my $object_id;
subtest(
	'Insert a new object.',
	sub
	{
		plan( tests => 2 );

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
						name => 'test_dump_' . time(),
					}
				)
			},
			'Insert succeeds.',
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

# Dump the object using the default dumper.
subtest(
	'Test default dumper.',
	sub
	{
		plan( tests => 2 );

		my $output;
		lives_ok(
			sub
			{
				$output = $object->dump();
			},
			'Dump the object.',
		);

		# Make sure the output isn't empty.
		like(
			$output,
			qr/account_id/,
			"The output includes the object's account ID.",
		) || diag( $output );
	}
);

# Dump the object using a custom dumper.
subtest(
	'Test custom dumper.',
	sub
	{
		plan( tests => 3 );

		ok(
			local $DBIx::NinjaORM::Utils::DUMPER = sub
			{
				my ( $ref ) = @_;
				return $ref->id();
			},
			'Set up custom dumper.',
		);

		my $output;
		lives_ok(
			sub
			{
				$output = $object->dump();
			},
			'Dump the object.',
		);

		# Verify output.
		is(
			$output,
			$object->id(),
			'dump() used the custom dumper.',
		);
	}
);
