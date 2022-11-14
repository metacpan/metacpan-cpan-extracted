use Test2::V0;
use Test2::Plugin::Times;
use Test2::Plugin::ExitSummary;
use Test2::Plugin::NoWarnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib 't/lib';

plan(4);

use Test::DBIx::Class { schema_class => 'TestSchema' }, 'Contraption', 'Doodad', 'Doohickey';

fixtures_ok [
   Contraption => [
      [ 'id', 'color',   'status' ],
      [ '1',  'blue',    'Sold' ],
      [ '2',  'brown',   'Sold' ],
      [ '3',  'purple',  'Packaged' ],
      [ '4',  'green',   'Shipped' ],
      [ '5',  'magenta', 'Packaged' ],
      [ '6',  'black',   'Shipped' ],
      [ '7',  'fuscia',  undef ],
   ],
   Doodad => [
      [ 'id', 'status',       'color' ],
      [ '1',  'Ordered',      'Blue' ],
      [ '2',  'Ordered',      'Black' ],
      [ '3',  'In-Stock',     'Black' ],
      [ '4',  'In-Stock',     'Green' ],
      [ '5',  'Out-Of-Stock', 'Red' ],
      [ '6',  'In-Stock',     'Blue' ],
      [ '7',  'Ordered',      'Red' ],
      [ '8',  'Ordered',      'Green' ],
   ],
   Doohickey => [
      [ 'id', 'field1', 'field2' ],
      [ '1',  'One',    'RED' ],
      [ '2',  'Two',    'BLUE' ],
      [ '3',  'Three',  'BLUE' ],
      [ '4',  'Four',   'BLUE' ],
      [ '5',  'Blue',   'BLUE' ],
   ],
    ],
    'Installed fixtures';

subtest 'is_ results created via direct injection' => sub {
   plan(6);
   my $contraption = Contraption->find(1);
   ok( $contraption->is_sold,      'Correctly detected status' );
   ok( !$contraption->is_packaged, 'Correctly detected non-status' );
   ok( !$contraption->is_shipped,  'Correctly detected non-status' );
   $contraption = Contraption->find(7);
   ok( !$contraption->is_sold,     'Correctly detected non-status on undef' );
   ok( !$contraption->is_packaged, 'Correctly detected non-status on undef' );
   ok( !$contraption->is_shipped,  'Correctly detected non-status on undef' );
};

subtest 'non-colliding is_ results created with enumerate' => sub {
   plan(7);
   my $doodad = Doodad->find(1);
   ok( $doodad->is_ordered,       'Correctly detected status' );
   ok( !$doodad->is_in_stock,     'Correctly detected non-status' );
   ok( !$doodad->is_out_of_stock, 'Correctly detected non-status' );
   ok( $doodad->is_blue,          'Correctly detected color' );
   ok( !$doodad->is_black,        'Correctly detected non-color' );
   ok( !$doodad->is_green,        'Correctly detected non-color' );
   ok( !$doodad->is_red,          'Correctly detected non-color' );
};

subtest 'Colliding is_ results created with enumerate' => sub {
   plan(8);
   my $doohickey = Doohickey->find(5);
   ok( !$doohickey->field1_is_one,   'Correctly detected non-field1' );
   ok( !$doohickey->field1_is_two,   'Correctly detected non-field1' );
   ok( !$doohickey->field1_is_three, 'Correctly detected non-field1' );
   ok( !$doohickey->field1_is_four,  'Correctly detected non-field1' );
   ok( $doohickey->field1_is_blue,   'Correctly detected field1' );
   ok( !$doohickey->field2_is_red,   'Correctly detected non-field2' );
   ok( !$doohickey->field2_is_green, 'Correctly detected non-field2' );
   ok( $doohickey->field2_is_blue,   'Correctly detected field2' );
};
exit;

