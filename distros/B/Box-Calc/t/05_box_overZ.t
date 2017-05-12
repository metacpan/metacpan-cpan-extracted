use Test::More;
use Test::Deep;

use lib '../lib';
use 5.010;
use Box::Calc::Box;
use strict;

use_ok 'Box::Calc::Box';

my $box = Box::Calc::Box->new(x => 4, y => 4, z => 2, weight => 20, name => 'test');
my $unit  = Box::Calc::Item->new(x => 1, y => 1, z => 1, name => 'Unit',  weight => 3);
my $chunk = Box::Calc::Item->new(x => 3, y => 3, z => 3, name => 'Chunk', weight => 3);
ok $box->pack_item($unit), 'Added unit to box';
ok ! $box->pack_item($chunk), 'Unable to add a chunk to the box';

done_testing;

