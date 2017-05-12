use Test::More;
use Test::Deep;

use lib '../lib';
use 5.010;

use_ok 'Box::Calc::Layer';

my $layer = Box::Calc::Layer->new(max_x => 12, max_y => 12);

isa_ok $layer, 'Box::Calc::Layer';
##Fill commands really return strings, not numbers
is $layer->fill_y, '0.0000', '... y';
is $layer->fill_z, '0.0000', '... z';
is $layer->fill_x, '0.0000', '... x';
is $layer->max_x, 12, 'maximum x';
is $layer->max_y, 12, '... y';
is $layer->calculate_weight, 0, '... weight';
is $layer->count_rows, 1, 'A new layer has a row created automatically';

use Box::Calc::Item;
my $deck = Box::Calc::Item->new(x => 3.5, y => 2.5, z => 1, name => 'Deck', weight => 3);
my $tarot_deck = Box::Calc::Item->new(x => 4.75, y => 2.75, z => 1.25, name => 'Tarot Deck', weight => 4);
my $pawn = Box::Calc::Item->new(x => 1, y => 0.5, z => 0.5, name => 'Pawn', weight => 0.1);
my $die  = Box::Calc::Item->new(x => 0.75, y => 0.75, z => 0.75, name => 'Die', weight => 0.1);
my $mgbox = Box::Calc::Item->new(x => 8.75, y => 6.5, z => 1.25, name => 'Medium Game Box', weight => 6);
my $lgbox = Box::Calc::Item->new(x => 10.75, y => 10.75, z => 1.5, name => 'Large Game Box', weight => 12);

##First add
$layer->pack_item($deck);

is $layer->count_rows, 1, 'adding an item does not add a row';
is $layer->calculate_weight, 3, '... weight'; 
is $layer->fill_y, '2.5000', '... y';
is $layer->fill_z, '1.0000', '... z';
is $layer->fill_x, '3.5000', '... x';
cmp_deeply simplify_layer($layer), [['Deck'] ], 'One item in one row';

##Add two more decks
$layer->pack_item($deck);
$layer->pack_item($deck);
is $layer->count_rows, 1, 'adding two items does not add a row';
is $layer->calculate_weight, 9, '... weight'; 
is $layer->fill_y, '2.5000', '... y';
is $layer->fill_z, '1.0000', '... z';
is $layer->fill_x, '10.5000', '... x';
cmp_deeply simplify_layer($layer), [[('Deck')x3] ], 'Three items in one row';

##Add the fourth deck, expecting a new row to be created
$layer->pack_item($deck);
is $layer->count_rows, 2, 'ran over the y, added a new row';
is $layer->calculate_weight, 12, '... weight'; 
is $layer->fill_y, '5.0000', '... y';
is $layer->fill_z, '1.0000', '... z';
is $layer->fill_x, '10.5000', '... x';
cmp_deeply simplify_layer($layer), [[('Deck')x3],['Deck'] ], 'Three items in one row, and one in a new row';

$layer->pack_item($tarot_deck);
is $layer->count_rows, 2, 'added it to the current row, #2';
is $layer->calculate_weight, 16, '... weight'; 
is $layer->fill_y, '5.2500', '... y';
is $layer->fill_z, '1.2500', '... z';
is $layer->fill_x, '10.5000', '... x';
cmp_deeply simplify_layer($layer), [[('Deck')x3],['Deck', 'Tarot Deck'] ], '5 items, 2 rows';

ok !$layer->pack_item($lgbox), 'Caught Y too big exception';
is $layer->count_rows, 2, 'no change in rows';
is $layer->calculate_weight, 16, '... weight'; 
is $layer->fill_y, '5.2500', '... y';
is $layer->fill_z, '1.2500', '... z';
is $layer->fill_x, '10.5000', '... x';
cmp_deeply simplify_layer($layer), [[('Deck')x3],['Deck', 'Tarot Deck'] ], '... packing list';
my $weight = 0;
my $list = {};
$layer->packing_list(\$weight, $list);
is $weight, 16, 'packing list weight correlates to calculated weight';
cmp_deeply $list, {Deck => 4, 'Tarot Deck' => 1}, 'packing list correlates to packing instructions';

my $grid = Box::Calc::Layer->new(max_x => 2, max_y => 2);
my $unit = Box::Calc::Item->new(x => 1, y => 1, z => 1, name => 'Unit', weight => 3);

$grid->pack_item($unit);
$grid->pack_item($unit);

ok $grid->pack_item($unit), 'no exceptions thrown';
cmp_deeply simplify_layer($grid), [[('Unit')x2],['Unit'] ], '... packing list, 2x1';

done_testing;

#Extract the name from each row in a layer with one arrayref of names per row;
sub simplify_layer {
    my $layer = shift;
    my @rows = ();
    foreach my $row (@{ $layer->rows} ) {
        my @row = map { $_->name } @{ $row->items };
        push @rows, [ @row ];
    }
    return [ @rows ];
}
