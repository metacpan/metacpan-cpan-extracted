#!perl -T

=head1 PURPOSE

When retrieving objects, the code can subclass retrieve_list() to specify more
fields to retrieve than just the fields that exist on the underlying table.

This is a very powerful way to not have to do a lot of costly lazy-loading,
however those extra fields need to be properly set aside in the object to
prevent confusion.

Test here that reorganize_non_native_fields() correctly creates internal
data structures for those non-native fields.

=cut

use strict;
use warnings;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 7;
use Test::Type;


# Verify that the main class supports the method.
can_ok(
	'DBIx::NinjaORM',
	'reorganize_non_native_fields',
);

# Verify inheritance.
can_ok(
	'DBIx::NinjaORM::Test',
	'reorganize_non_native_fields',
);

ok(
	defined(
		my $test = DBIx::NinjaORM::Test->new()
	),
	'Create a new Test object.',
);

# Set up test fields.
note( 'Set up fields inside the object.' );
$test->{'_account_account_id'} = 1;
$test->{'_table_field'} = 'value';
$test->{'name'} = 'Guillaume';
note( explain( $test ) );

# Reorganize fields.
lives_ok(
	sub
	{
		$test->reorganize_non_native_fields();
	},
	'Reorganize non-native fields in the object.',
);

# Test that joined fields (which are not native to the underlying table) are
# reorganized properly.
subtest(
	'Joined field.',
	sub
	{
		plan( tests => 3 );

		ok(
			exists(
				$test->{'_table'}->{'field'}
			),
			'"_table->field" exists.',
		);

		is(
			$test->{'_table'}->{'field'},
			'value',
			'The value matches.',
		);

		ok(
			!exists(
				$test->{'_table_field'}
			),
			'"_table_field" does not exist anymore.',
		);
	}
);

# Same test, but with an extra underscore in the field name.
subtest(
	'Joined field with an underscore in the field name.',
	sub
	{
		plan( tests => 3 );

		ok(
			exists(
				$test->{'_account'}->{'account_id'}
			),
			'"_account->account_id" exists.',
		);

		is(
			$test->{'_account'}->{'account_id'},
			1,
			'The value matches.',
		);

		ok(
			!exists(
				$test->{'_account_account_id'}
			),
			'"_account_account_id" does not exist anymore.',
		);
	}
);

is(
	$test->{'name'},
	'Guillaume',
	'Fields not starting with an underscore have been left intact.',
);


# Test subclass. We just need a valid subclass, but we don't interact with the
# database here so we don't need the full-fledged version.
package DBIx::NinjaORM::Test;

use strict;
use warnings;

use base 'DBIx::NinjaORM';

1;

