use strict;
use warnings;

use Test::More;
use Adapter::Async::Model;

{
	package Local::Model::Item;
	use Adapter::Async::Model {
		id => 'int',
	}, defer_methods => 0;
}
can_ok('Local::Model::Item', qw(new id));
my $item = new_ok('Local::Model::Item' => [
	id => 123
]);
is($item->id, 123, 'ID is correct');

{
	package Local::Model::CustomMethod;
	use Adapter::Async::Model {
		id => 'int',
		name => 'string',
	}, defer_methods => 0;

	no warnings 'redefine';
	sub name {
		my $self = shift;
		return '' . reverse $self->{name} unless @_;
		$self->{name} = shift;
		$self
	}
}
can_ok('Local::Model::CustomMethod', qw(new id name));
{
	my $custom = new_ok('Local::Model::CustomMethod' => [
		id => 456
	]);
	is($custom->id, 456, 'ID is correct');
	is($custom->name('input'), $custom, 'can set name');
	is($custom->name, 'tupni', 'name was mangled as expected');
}

{
	package Local::Model::ListCollection;
	use Adapter::Async::Model {
		item => {
			collection => 'OrderedList',
			type => '::Item',
		}
	}, defer_methods => 0;
}
can_ok('Local::Model::ListCollection', qw(new item));
my $list = new_ok('Local::Model::ListCollection' => [
]);
is($list->item->count->get, 0, 'no item yet');
$list->item->push([ $item ])->get;
is($list->item->count->get, 1, 'now have an item');

{
	package Local::Model::MapCollection;
	use Adapter::Async::Model {
		item => {
			collection => 'UnorderedMap',
			type => '::Item',
			key => 'int',
		}
	}, defer_methods => 0;
}
can_ok('Local::Model::MapCollection', qw(new item));
my $map = new_ok('Local::Model::MapCollection' => [
]);
is($map->item->count->get, 0, 'no item yet');
$map->item->set_key($item->id => $item)->get;
is($map->item->get_key($item->id)->get, $item, 'now have an item');

done_testing;


