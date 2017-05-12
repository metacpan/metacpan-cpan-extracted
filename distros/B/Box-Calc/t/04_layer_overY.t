use Test::More;
use Test::Deep;

use lib '../lib';
use 5.010;

use Box::Calc::Layer;
use Box::Calc::Item;

my $layer = Box::Calc::Layer->new(max_x => 4, max_y => 2);
my $unit  = Box::Calc::Item->new(x => 1, y => 1, z => 1, name => 'Unit',  weight => 3);
my $chunk = Box::Calc::Item->new(x => 3, y => 3, z => 1, name => 'Chunk', weight => 3);
ok $layer->pack_item($unit), 'Added unit to layer';
ok ! $layer->pack_item($chunk), 'Unable to add a chunk to the layer';

done_testing;
