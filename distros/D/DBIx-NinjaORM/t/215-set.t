#!perl -T

=head1 PURPOSE

Test setting fields and corresponding values with set().

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
	'set',
);

# Verify inheritance.
can_ok(
	'DBIx::NinjaORM::Test',
	'set',
);

ok(
	my $object = DBIx::NinjaORM::Test->new(),
	'Create new object.',
);

dies_ok(
	sub
	{
		$object->set(
			field => 'value',
		)
	},
	'The first argument must be a hashref.',
);

# Make sure that read-only fields cannot be set via set() by default.
subtest(
	'Set a read-only field without the "force" argument.',
	sub
	{
		plan( tests => 2 );

		ok(
			!exists( $object->{'readonly_field'} ),
			'"readonly_field" does not exist on the object.',
		);

		dies_ok(
			sub
			{
				$object->set(
					{
						readonly_field => 'value',
					}
				);
			},
			'Set value fails.',
		);
	}
);

# Make sure that read-only fields cannot be set via set() without 'force'.
subtest(
	'Set a read-only field with force=0.',
	sub
	{
		plan( tests => 2 );

		ok(
			!exists( $object->{'readonly_field'} ),
			'"readonly_field" does not exist on the object.',
		);

		dies_ok(
			sub
			{
				$object->set(
					{
						readonly_field => 'value',
					},
					force => 0,
				);
			},
			'Set value fails.',
		);
	}
);

# Make sure that readonly fields can be set via set() when the 'force' argument
# is specified and set to 1.
subtest(
	'Set a read-only field with force=1.',
	sub
	{
		plan( tests => 3 );

		ok(
			!exists( $object->{'readonly_field'} ),
			'"readonly_field" does not exist on the object.',
		);

		lives_ok(
			sub
			{
				$object->set(
					{
						readonly_field => 'value',
					},
					force => 1,
				);
			},
			'Set value.',
		);

		is(
			$object->{'readonly_field'},
			'value',
			'The read-only field is set.',
		);
	}
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
