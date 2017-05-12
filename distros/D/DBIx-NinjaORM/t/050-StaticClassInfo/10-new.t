#!perl -T

=head1 PURPOSE

Test creating a new L<DBIx::NinjaORM::StaticClassInfo> object.

=cut

use DBIx::NinjaORM::StaticClassInfo;
use Test::Exception;
use Test::FailWarnings -allow_deps => 1;
use Test::More tests => 4;


can_ok(
	'DBIx::NinjaORM::StaticClassInfo',
	'new',
);

my $static_class_info;
lives_ok(
	sub
	{
		$static_class_info = DBIx::NinjaORM::StaticClassInfo->new();
	},
	'Instantiate a new object.',
);

isa_ok(
	$static_class_info,
	'DBIx::NinjaORM::StaticClassInfo',
);

isnt(
	scalar( keys %$static_class_info ),
	0,
	'The object has keys defined.',
) || diag( explain( $static_class_info ) );
