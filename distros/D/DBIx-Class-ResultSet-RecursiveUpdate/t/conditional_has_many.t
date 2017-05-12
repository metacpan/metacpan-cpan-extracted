use strict;
use warnings;

use lib 't/lib';
use Test::More;
use Test::Exception;

use_ok 'AnotherTestDB::OnePK::Schema';

my $schema = AnotherTestDB::OnePK::Schema->connect('dbi:SQLite:dbname=:memory:');

isa_ok $schema, 'DBIx::Class::Schema';

lives_ok( sub{
	#$schema->deploy({add_drop_table => 1});
	$schema->deploy();
	$schema->populate('Item', [
		[ qw/idcol/ ],
		[ 1 ],
	]);
	$schema->populate('RelatedItem', [
		[ qw/idcol item_id/ ],
		[ 1, 1 ],
		[ 2, 1 ],
	]);
	$schema->populate('ConditionItem', [
		[ qw/idcol rel_item_id condition/ ],
		[ 1, 1, 'false' ],
		[ 2, 1, 'true' ],
		[ 3, 2, 'true' ],
		[ 4, 2, 'false' ],
	]);
}, 'creating and populating test database'
);

is($schema->resultset('Item')->find(1)->relateditems->count, 2);
is($schema->resultset('Item')->find(1)->true_relateditems->count, 2);

lives_ok(sub{
	$schema->resultset('Item')->recursive_update({
		idcol => 1,
		true_relateditems => [{ idcol => 1}],
	});
});

is($schema->resultset('Item')->find(1)->relateditems->count, 1);
is($schema->resultset('Item')->find(1)->true_relateditems->count, 1);

use_ok 'AnotherTestDB::TwoPK::Schema';

$schema = AnotherTestDB::TwoPK::Schema->connect('dbi:SQLite:dbname=:memory:');

isa_ok $schema, 'DBIx::Class::Schema';

lives_ok( sub{
	#$schema->deploy({add_drop_table => 1});
	$schema->deploy();
	$schema->populate('Item', [
		[ qw/idcol/ ],
		[ 1 ],
	]);
	$schema->populate('RelatedItem', [
		[ qw/idcol item_id/ ],
		[ 1, 1 ],
		[ 2, 1 ],
	]);
	$schema->populate('ConditionItem', [
		[ qw/idcol rel_item_id condition/ ],
		[ 1, 1, 'false' ],
		[ 2, 1, 'true' ],
		[ 3, 2, 'true' ],
		[ 4, 2, 'false' ],
	]);
}, 'creating and populating test database'
);

is($schema->resultset('Item')->find({idcol => 1})->relateditems->count, 2);
is($schema->resultset('Item')->find({idcol => 1})->true_relateditems->count, 2);

lives_ok(sub{
	$schema->resultset('Item')->recursive_update({
		idcol => 1,
		true_relateditems => [{
			idcol => 1,
			item_id => 1,
		}],
	});
});


is($schema->resultset('Item')->find({idcol => 1})->relateditems->count, 1);
is($schema->resultset('Item')->find({idcol => 1})->true_relateditems->count, 1);

done_testing;
