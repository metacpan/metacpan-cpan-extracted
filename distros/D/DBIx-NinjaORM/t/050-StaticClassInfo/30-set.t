#!perl -T

=head1 PURPOSE

Test creating a new L<DBIx::NinjaORM::StaticClassInfo> object.

=cut

use DBIx::NinjaORM::StaticClassInfo;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 6;


can_ok(
	'DBIx::NinjaORM::StaticClassInfo',
	'set',
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
		$static_class_info->set();
	},
	qr/\QThe first argument passed must be a hashref\E/,
	'The first argument is mandatory.',
);

throws_ok(
	sub
	{
		$static_class_info->set('test');
	},
	qr/\QThe first argument passed must be a hashref\E/,
	'The first argument must be a hashref.',
);

throws_ok(
	sub
	{
		$static_class_info->set(
			{
				'invalid' => 'value',
			}
		);
	},
	qr/\QThe key 'invalid' is not valid\E/,
	'The key name must be valid.',
);

lives_ok(
	sub
	{
		$static_class_info->set(
			{
				'default_dbh' => 'test',
			}
		);
	},
	'Set test value.',
);
