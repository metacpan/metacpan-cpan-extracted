#!perl -T

=head1 PURPOSE

Test that validate_data() rejects incorrect/protected fields.

=cut

use strict;
use warnings;

use DBIx::NinjaORM;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 7;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'validate_data',
);

# Verify inheritance.
can_ok(
	'DBIx::NinjaORM::Test',
	'validate_data',
);

ok(
	my $object = DBIx::NinjaORM::Test->new(),
	'Create new object.',
);

# Test setting the primary key value when it's not set on the object.
subtest(
	'Set primary key value.',
	sub
	{
		plan( tests => 2 );

		my $validated_data;
		lives_ok(
			sub
			{
				$validated_data = $object->validate_data(
					{
						test_pk => 1,
					}
				);
			},
			'Validate data.',
		);

		my $expected =
		{
			test_pk => 1,
		};

		is_deeply(
			$validated_data,
			$expected,
			'Setting the primary key on an object without one is valid.',
		) || diag( explain( 'Retrieved: ', $validated_data, 'Expected: ', $expected ) );
	}
);

# Test setting the primary key value when it's already set on the object.
subtest(
	'Fail to override primary key value.',
	sub
	{
		plan( tests => 2 );

		ok(
			$object->{'test_pk'} = 2,
			'Set primary key value internally.',
		);

		my $validated_data;
		dies_ok(
			sub
			{
				$validated_data = $object->validate_data(
					{
						test_pk => 1,
					}
				);
			},
			'Validate data.',
		);
	}
);

# Make sure that the code using this module cannot set fields starting with
# an underscore, as those are reserved for fields non-native to the underlying
# table.
subtest(
	'Fields starting with an underscore are ignored.',
	sub
	{
		plan( tests => 2 );

		my $validated_data;
		lives_ok(
			sub
			{
				$validated_data = $object->validate_data(
					{
						'field1' => 'value1',
						'_field' => 'value2',
					}
				);
			},
			'Validate data.',
		);

		my $expected =
		{
			field1 => 'value1',
		};

		is_deeply(
			$validated_data,
			$expected,
			'The field with a leading underscore got dropped.',
		) || diag( explain( 'Retrieved: ', $validated_data, 'Expected: ', $expected ) );
	}
);

# Make sure that read-only fields are protected.
my $validated_data;
dies_ok(
	sub
	{
		$validated_data = $object->validate_data(
			{
				'field1'        => 'value1',
				'readonly_field' => 'value2',
			}
		);
	},
	'Read-only fields are protected.',
);


# Test subclass with read-only fields and a primary key name set.
package DBIx::NinjaORM::Test;

use strict;
use warnings;

use base 'DBIx::NinjaORM';


sub static_class_info
{
	my ( $class ) = @_;

	my $info = $class->SUPER::static_class_info();

	$info->set(
		{
			'readonly_fields'  => [ 'readonly_field' ],
			'primary_key_name' => 'test_pk',
		}
	);

	return $info;
}

1;
