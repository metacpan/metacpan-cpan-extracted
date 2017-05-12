#!perl -T

=head1 PURPOSE

Test creating a new L<DBIx::NinjaORM::StaticClassInfo> object.

=cut

use DBIx::NinjaORM::StaticClassInfo;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 7;


can_ok(
	'DBIx::NinjaORM::StaticClassInfo',
	'get',
);

my $static_class_info;
lives_ok(
	sub
	{
		$static_class_info = DBIx::NinjaORM::StaticClassInfo->new();
	},
	'Instantiate a new object.',
);

throws_ok(
	sub
	{
		$static_class_info->get();
	},
	qr/\QThe key name must be defined\E/,
	'The key name must be defined.',
);

throws_ok(
	sub
	{
		$static_class_info->get('invalid');
	},
	qr/\QThe key 'invalid' is not valid\E/,
	'The key name must be valid.',
);

ok(
	$static_class_info->{'test_key'} = 42,
	'Set test value.',
);

my $value;
lives_ok(
	sub
	{
		$value = $static_class_info->get('test_key');
	},
	'Retrieve test value.',
);

is(
	$value,
	42,
	'The test key returned the correct value.',
);
