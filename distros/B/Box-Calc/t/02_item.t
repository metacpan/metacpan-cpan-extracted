use Test::More;
use Test::Deep;

use lib '../lib';
use 5.010;

use_ok 'Box::Calc::Item';

my $item = Box::Calc::Item->new(x => 3, y => 7, z => 2, name => 'test', weight => 14);

isa_ok $item, 'Box::Calc::Item';

is $item->x, 7, 'x defaults to largest';
is $item->y, 3, 'y defaults to 3';
is $item->z, 2, 'z defaults to smallest';
is $item->name, 'test', 'took name';
is $item->weight, 14, 'took weight';

is $item->volume, 3*7*2, 'volume';

cmp_deeply $item->dimensions, [7,3,2], 'dimensions';

done_testing;

