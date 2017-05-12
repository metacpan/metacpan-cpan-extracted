#!perl -T

=head1 PURPOSE

Test retrieving field values on objects using get().

Some fields are protected and should not be retrieved directly.

=cut

use strict;
use warnings;

use DBIx::NinjaORM;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 10;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'get',
);

# Verify inheritance.
can_ok(
	'DBIx::NinjaORM::Test',
	'get',
);

ok(
	defined(
		my $test = DBIx::NinjaORM::Test->new(),
	),
	'Create a new Test object.',
);

# Make sure we require a field name.
dies_ok(
	sub
	{
		$test->get();
	},
	'A field name is mandatory.',
);

dies_ok(
	sub
	{
		$test->get('');
	},
	'An empty field name is not valid.',
);

# Make sure that fields names starting with an underscore are not directly
# accessible.
ok(
	defined( $test->{'_field'} = 1 ),
	'Set up field starting with an underscore.',
);

dies_ok(
	sub
	{
		$test->get('_field');
	},
	'Fields starting with an underscore cannot be retrieved via get().',
);

# Make sure that normal fields are accessible.
ok(
	defined( $test->{'field'} = 10 ),
	'Set up a normal field.',
);

my $value;
lives_ok(
	sub
	{
		$value = $test->get('field');
	},
	"Retrieve the field's value.",
);

is(
	$value,
	10,
	'The value retrieved matches the value set up.',
);


# Test subclass.
# We don't actually need to interact with the database to test get(), so we
# just need the barebones here.
package DBIx::NinjaORM::Test;

use strict;
use warnings;

use lib 't/lib';
use LocalTest;

use base 'DBIx::NinjaORM';

1;

