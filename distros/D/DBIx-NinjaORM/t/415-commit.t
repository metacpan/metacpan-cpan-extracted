#!perl -T

=head1 PURPOSE

Test commit().

=cut

use strict;
use warnings;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;
use Test::Type;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'commit',
);

# Verify inheritance.
can_ok(
	'DBIx::NinjaORM::Test',
	'commit',
);

# Test inserting a row via commit().
subtest(
	'Test inserting a row via commit().',
	sub
	{
		plan( tests => 5 );

		ok(
			defined(
				my $object = DBIx::NinjaORM::Test->new(),
			),
			'Create object.',
		);

		lives_ok(
			sub
			{
				$object->set(
					{
						field => 'value',
					}
				);
			},
			'Set data on the object.',
		);

		my $output;
		lives_ok(
			sub
			{
				$output = $object->commit();
			},
			'Commit.',
		);

		is(
			$output->{'action'},
			'insert',
			'commit() called insert().',
		);

		is_deeply(
			$output->{'data'},
			{
				field => 'value',
			},
			'Called insert() with the correct data.',
		);
	}
);

# Test updating a row via commit().
subtest(
	'Test updating a row via commit().',
	sub
	{
		plan( tests => 6 );

		ok(
			defined(
				my $object = DBIx::NinjaORM::Test->new(),
			),
			'Create object.',
		);

		lives_ok(
			sub
			{
				$object->set(
					{
						field => 'value',
					}
				);
			},
			'Set data on the object.',
		);

		ok(
			$object->{'test_id'} = 1,
			'Override primary key value.',
		);

		my $output;
		lives_ok(
			sub
			{
				$output = $object->commit();
			},
			'Commit.',
		);

		is(
			$output->{'action'},
			'update',
			'commit() called update().',
		);

		is_deeply(
			$output->{'data'},
			{
				field => 'value',
			},
			'Called update() with the correct data (excluding the primary key).',
		);
	}
);


# Test subclass with enough information to insert/update rows.
package DBIx::NinjaORM::Test;

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use base 'DBIx::NinjaORM';


sub static_class_info
{
	my ( $class ) = @_;

	my $info = $class->SUPER::static_class_info();

	$info->set(
		{
			default_dbh      => LocalTest::get_database_handle(),
			table_name       => 'tests',
			primary_key_name => 'test_id',
		}
	);

	return $info;
}

sub insert
{
	my ( $self, $data ) = @_;

	return
	{
		action => 'insert',
		data   => $data,
	};
}

sub update
{
	my ( $self, $data ) = @_;

	return
	{
		action => 'update',
		data   => $data,
	};
}

1;

