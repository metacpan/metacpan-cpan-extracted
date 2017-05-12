#!perl -T

=head1 PURPOSE

Make sure that static_class_info() and cached_static_class_info() return the
same results.

=cut

use strict;
use warnings;

use DBIx::NinjaORM;
use Test::Deep;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;
use Test::Type;


# Make sure that cached_static_class_info() is supported by DBIx::NinjaORM.
can_ok(
	'DBIx::NinjaORM',
	'cached_static_class_info',
);

# Retrieve the non-cached version.
my $info;
lives_ok(
	sub
	{
		$info = DBIx::NinjaORM->static_class_info();
	},
	'Retrieve the static class info.',
);

# Retrieve the cached version.
my $cached_info;
lives_ok(
	sub
	{
		$cached_info = DBIx::NinjaORM->cached_static_class_info();
	},
	'Retrieve the cached static class info.',
);

# Compare the cached and non-cached versions.
cmp_deeply(
	$cached_info,
	$info,
	'Cached info matches info.',
);
