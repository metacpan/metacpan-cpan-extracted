use strict;
use warnings;

use lib 't/lib';
use Test::More;
use Test::Exception;


use_ok 'TwoPkHasManyDB::Schema';

my $schema = TwoPkHasManyDB::Schema->connect('dbi:SQLite:dbname=:memory:');

isa_ok $schema, 'DBIx::Class::Schema';

lives_ok( sub{
	$schema->deploy();
	$schema->populate('Item', [
		[ qw/id/ ],
		[ 1 ],
	]);
	$schema->populate('RelatedItem', [
		[ qw/id item_id/ ],
		[ 1, 1 ],
		[ 2, 1 ],
	]);
	$schema->populate('RelatedItem2', [
		[ qw/idcol item_id/ ],
		[ 1, 1 ],
		[ 2, 1 ],
	]);
}, 'creating and populating test database'
);

is($schema->resultset('Item')->find({ id =>1})->relateditems->count, 2);
is($schema->resultset('Item')->find({ id =>1})->relateditems2->count, 2);

# this one will fail for unpatched RecursiveUpdate
lives_ok(sub{
	$schema->resultset('Item')->recursive_update({
		id => 1,
		relateditems => [{
			id => 1,
			item_id => 1,
		}],
	});
}, "updating two_pk relation with colname id");

# this works fine, even with unpatched RecursiveUpdate
lives_ok(sub{
	$schema->resultset('Item')->recursive_update({
		id => 1,
		relateditems2 => [{
			idcol => 1,
			item_id => 1,
		}],
	});
}, "updating two_pk relation without colname id");

is($schema->resultset('Item')->find({ id =>1})->relateditems->count, 1);
is($schema->resultset('Item')->find({ id =>1})->relateditems2->count, 1);

done_testing;
