#!perl -T

=head1 PURPOSE

Make sure that has_modified_field() returns the value specified in the static
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
	'has_modified_field',
);

# Verify inheritance.
can_ok(
	'DBIx::NinjaORM::TestModified',
	'has_modified_field',
);
can_ok(
	'DBIx::NinjaORM::TestNoModified',
	'has_modified_field',
);

# Tests.
my $tests =
[
	{
		name     => 'Test calling has_modified_field() on DBIx::NinjaORM.',
		ref      => 'DBIx::NinjaORM',
		expected => 1,
	},
	{
		name     => 'Test calling has_modified_field() on DBIx::NinjaORM::TestModified.',
		ref      => 'DBIx::NinjaORM::TestModified',
		expected => 1,
	},
	{
		name     => 'Test calling has_modified_field() on a DBIx::NinjaORM::TestModified object.',
		ref      => bless( {}, 'DBIx::NinjaORM::TestModified' ),
		expected => 1,
	},
	{
		name     => 'Test calling has_modified_field() on DBIx::NinjaORM::TestNoModified.',
		ref      => 'DBIx::NinjaORM::TestNoModified',
		expected => 0,
	},
	{
		name     => 'Test calling has_modified_field() on a DBIx::NinjaORM::TestNoModified object.',
		ref      => bless( {}, 'DBIx::NinjaORM::TestNoModified' ),
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

			my $modified_field;
			warning_like(
				sub
				{
					$modified_field = $test->{'ref'}->has_modified_field();
				},
				qr/has been deprecated/,
				'The method is deprecated.',
			);

			is(
				$modified_field,
				$test->{'expected'},
				'has_modified_field() returns the value set up in static_class_info().',
			);
		}
	);
}


# Test subclass with a 'modified' field.
package DBIx::NinjaORM::TestModified;

use strict;
use warnings;

use base 'DBIx::NinjaORM';


sub static_class_info
{
	my ( $class ) = @_;

	my $info = $class->SUPER::static_class_info();

	$info->set(
		{
			'has_modified_field' => 1,
		}
	);

	return $info;
}

1;


# Test subclass without a 'modified' field.
package DBIx::NinjaORM::TestNoModified;

use strict;
use warnings;

use base 'DBIx::NinjaORM';


sub static_class_info
{
	my ( $class ) = @_;

	my $info = $class->SUPER::static_class_info();

	$info->set(
		{
			'has_modified_field' => 0,
		}
	);

	return $info;
}

1;
