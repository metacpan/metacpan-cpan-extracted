#!perl -T

=head1 PURPOSE

Make sure that new() returns an empty blessed object.

=cut

use strict;
use warnings;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;
use Test::Type;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'new',
);

# Verify inheritance.
can_ok(
	'DBIx::NinjaORM::Test',
	'new',
);

# Make sure that new() returns an empty object.
my $object;
lives_ok(
	sub
	{
		$object = DBIx::NinjaORM::Test->new();
	},
	'Instantiate an empty object.',
);

isa_ok(
	$object,
	'DBIx::NinjaORM::Test',
);

is(
	scalar( keys %$object),
	0,
	'The object is empty.',
);


# Test subclass with the bare minimum needed by new().
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
			'unique_fields'    => [],
			'primary_key_name' => 'test_pk',
		}
	);

	return $info;
}

1;
