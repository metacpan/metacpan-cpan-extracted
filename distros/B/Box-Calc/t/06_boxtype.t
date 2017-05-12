use Test::More;
use Test::Deep;

use lib '../lib';
use 5.010;

use_ok 'Box::Calc::BoxType';

my $container = Box::Calc::BoxType->new(x => 3, y => 7, z => 2, weight => 20, name => 'big, big box', category => 'USPS Priority');

isa_ok $container, 'Box::Calc::BoxType';
ok $container->does('Box::Calc::Role::Dimensional'), 'BoxType consumes the Dimensional role';

is $container->x, 7, 'x defaults to largest';
is $container->y, 3, 'y defaults to 3';
is $container->z, 2, 'z defaults to smallest';
is $container->name, 'big, big box', 'took name';
cmp_deeply $container->category, 'USPS Priority', 'took category';

is $container->volume, 3*7*2, 'volume';

cmp_deeply $container->dimensions, [7,3,2], 'dimensions';

done_testing;

