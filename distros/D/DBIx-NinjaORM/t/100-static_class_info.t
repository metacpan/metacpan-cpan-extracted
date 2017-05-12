#!perl -T

=head1 PURPOSE

Test the default values of static_class_info().

=cut

use strict;
use warnings;

use DBIx::NinjaORM;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 5;
use Test::Type;


# Make sure that static_class_info() is supported by DBIx::NinjaORM.
can_ok(
	'DBIx::NinjaORM',
	'static_class_info',
);

# Retrieve the static class information.
my $info;
lives_ok(
	sub
	{
		$info = DBIx::NinjaORM->static_class_info();
	},
	'Retrieve the static class info.',
);

ok_hashref(
	$info,
	name => 'Static class info',
);

# List of mandatory static class info keys.
my $mandatory_keys =
[
	qw(
		default_dbh
		memcache
		table_name
		primary_key_name
		list_cache_time
		object_cache_time
		unique_fields
		filtering_fields
		readonly_fields
		has_created_field
		has_modified_field
		cache_key_field
		verbose
		verbose_cache_operations
	)
];

# Make sure we have all the mandatory keys.
subtest(
	'Verify the mandatory information.',
	sub
	{
		plan( tests => scalar( @$mandatory_keys ) );

		foreach my $key ( @$mandatory_keys )
		{
			ok(
				exists( $info->{ $key } ),
				"The mandatory key '$key' exists.",
			);
			# Delete the valid key, so that we can make sure at
			# the end that we don't have unknown keys.
			delete( $info->{ $key } );
		}
	}
);

# Make sure we don't have unknown keys left.
is(
	scalar( keys %$info ),
	0,
	'No unknown static class info keys found.',
);
