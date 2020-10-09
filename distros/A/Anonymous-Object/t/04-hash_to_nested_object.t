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
}));

is($obj->room->bed->duvet, 1);
is($obj->room->bed->mat, 'blue');
is($obj->rooms->[0]->info->name, 'kitchen');
is($obj->rooms->[1]->info->name, 'living');
is($obj->rooms->[1]->info->array->[1], 2);

done_testing;
