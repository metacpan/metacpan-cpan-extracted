use Test::More tests => 26;

use lib qw(t/lib);

use Schema;
my $schema = Schema->connect;

my $item = $schema->resultset('Item')->new_result({});

for(1..3) {
  ok($item->can('status'.$_), 'accessor status'.$_);
  ok($item->can('status_status'.$_), 'accessor with prefix status'.$_);
}

ok($item->can('_bitfield'), 'private accessor');
ok($item->can('__bitfield2'), 'private accessor');
ok($item->can('bitfield'), 'public accessor');
ok($item->can('bitfield2'), 'public accessor');


is_deeply($item->bitfield, [], 'stringified empty bitfield');

ok($item->status1(1), 'set status1');

is($item->status1, 1, 'status1 is set');

is($item->_bitfield, 1, 'bitfield has value 1');

ok($item->status2(1), 'set status2');

is($item->status2, 1, 'status2 is set');

is($item->_bitfield, 3, 'bitfield has value 3');

ok($item->status3(1), 'set status3');

is($item->status3, 1, 'status3 is set');

is($item->_bitfield, 7, 'bitfield has value 7');

ok(!$item->status2(0), 'unset status2');

is($item->status2, 0, 'status2 is unset');

is($item->_bitfield, 5, 'bitfield has value 5');

is_deeply($item->bitfield, [qw(status1 status3)], 'stringified bitfield');

ok($item->insert);

$item->get_from_storage;

is($item->_bitfield, 5);


