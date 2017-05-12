#!perl -T

=head1 PURPOSE

Make sure that has_created_field() returns the value specified in the static
class information.

=cut

use strict;
use warnings;

use DBIx::NinjaORM;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 8;
use Test::Warn;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'has_created_field',
);

# Verify inheritance.
can_ok(
	'DBIx::NinjaORM::TestCreated',
	'has_created_field',
);
can_ok(
	'DBIx::NinjaORM::TestNoCreated',
	'has_created_field',
);

# Tests.
my $tests =
[
	{
		name     => 'Test calling has_created_field() on DBIx::NinjaORM.',
		ref      => 'DBIx::NinjaORM',
		expected => 1,
	},
	{
		name     => 'Test calling has_created_field() on DBIx::NinjaORM::TestCreated.',
		ref      => 'DBIx::NinjaORM::TestCreated',
		expected => 1,
	},
	{
		name     => 'Test calling has_created_field() on a DBIx::NinjaORM::TestCreated object.',
		ref      => bless( {}, 'DBIx::NinjaORM::TestCreated' ),
		expected => 1,
	},
	{
		name     => 'Test calling has_created_field() on DBIx::NinjaORM::TestNoCreated.',
		ref      => 'DBIx::NinjaORM::TestNoCreated',
		expected => 0,
	},
	{
		name     => 'Test calling has_created_field() on a DBIx::NinjaORM::TestNoCreated object.',
		ref      => bless( {}, 'DBIx::NinjaORM::TestNoCreated' ),
		expected => 0,
	},
];

# Run tests.
foreach my $test ( @$tests )
{
	subtest(
		$test->{'name'},
		sub
		{
			plan( tests => 2 );

			my $created_field;
			warning_like(
				sub
				{
					$created_field = $test->{'ref'}->has_created_field();
				},
				{ carped => qr/has been deprecated/ },
				'The method is deprecated.',
			);

			is(
				$created_field,
				$test->{'expected'},
				'has_created_field() returns the value set up in static_class_info().',
			);
		}
	);
}


# Test subclass with a 'created' field.
package DBIx::NinjaORM::TestCreated;

use strict;
use warnings;

use base 'DBIx::NinjaORM';


sub static_class_info
{
	my ( $class ) = @_;

	my $info = $class->SUPER::static_class_info();

	$info->set(
		{
			'has_created_field' => 1,
		}
	);

	return $info;
}

1;


# Test subclass without a 'created' field.
package DBIx::NinjaORM::TestNoCreated;

use strict;
use warnings;

use base 'DBIx::NinjaORM';


sub static_class_info
{
	my ( $class ) = @_;

	my $info = $class->SUPER::static_class_info();

	$info->set(
		{
			'has_created_field' => 0,
		}
	);

	return $info;
}

1;
