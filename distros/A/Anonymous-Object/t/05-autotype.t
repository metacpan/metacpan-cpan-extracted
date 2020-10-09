use Test::More;

use Anonymous::Object;

ok(my $an = Anonymous::Object->new({}));

ok(my $obj = $an->hash_to_nested_object({
	room => {
		bed => {
			duvet => 1,
			mat => 'blue',
		}
	},
	rooms => [
		{
			info => {
				name => 'kitchen'
			}
		},
		{
			info => {
				name => 'living',
				array => [qw/1 2 3/]
			}
		}
	]
}, autotype => 1, set => 1, merge => 1 ));

is($obj->room->bed->duvet, 1);

is($obj->room->bed->mat, 'blue');
is($obj->rooms->[0]->info->name, 'kitchen');
is($obj->rooms->[1]->info->name, 'living');
is($obj->rooms->[1]->info->array->[1], 2);

eval {
	$obj->set_room('abc');
};
like($@, qr/did not pass type constraint/);

eval {
	$obj->room->set_bed('abc');
};
like($@, qr/did not pass type constraint/);

eval {
	$obj->room->bed->set_duvet('abc');
};
like($@, qr/did not pass type constraint/);

is($obj->room->bed->set_duvet(2), 2);

is_deeply($obj->room->set_bed({ duvet => 5 }), { duvet => 5, mat => 'blue' });
is($obj->room->bed->duvet, 5);
my $rooms = [
	{
		info => {
			name => 'living'
		}
	},
	{
		info => {
			name => 'kitchen',
			array => [qw/1 2 3/]
		}
	}
];

is_deeply($obj->set_rooms($rooms), $rooms);

is($obj->rooms->[0]->info->name, 'living');
is($obj->rooms->[1]->info->name, 'kitchen');
is($obj->rooms->[1]->info->array->[1], 2);

done_testing;
