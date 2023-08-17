use Test2::V0;
use Test2::Plugin::Times;
use Test2::Plugin::ExitSummary;
use Test2::Plugin::NoWarnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib 't/lib';

plan(3);

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


subtest 'update for pseudo-enum created via direct injection' => sub {
   plan(6);
   my $contraption = Contraption->find(1);
   like(
      lives {
         $contraption->update( { status => 'Packaged' } );
      },
      1,
      'Able to update with a valid value'
   );
   is( $contraption->status, 'Packaged', 'properly round-tripped an update.' );

   like(
      dies {
         $contraption->update( { status => 'nothing'} );
      },
      qr/You have attempted to assign a value to status that is not valid:/,
      'Unable to update with an invalid value'
   );

   like(
      lives {
         $contraption->update( { status => undef } );
      },
      1,
      'Able to update with a null value'
   );
   $contraption = Contraption->find(1);
   is( $contraption->status, undef, 'properly round-tripped an update with null status.' );

   like(
      lives {
         $contraption->update( { note => 'This is a note' });
      },
      1,
      'Able to update non-enumerated field correctly.'
   )
};

subtest 'update for pseudo-enum created via enumerate' => sub {
   plan(5);
   my $doodad = Doodad->find(1);
   like(
      lives {
         $doodad->update( { status => 'Ordered' } )
      },
      1,
      'Able to update with a valid value'
   );
   $doodad = Doodad->find(1);
   is( $doodad->status, 'Ordered', 'properly round-tripped an insert.' );

   like(
      dies {
         $doodad->update( {  status => 'BOGUS!' } )
      },
      qr/You have attempted to assign a value to status that is not valid:/,
      'Unable to update with an invalid value'
   );

   like(
      dies {
         $doodad->update( {  status => undef } )
      },
      qr/NOT NULL constraint failed/,
      'Unable to update with a null value in a non-nullable field'
   );
   $doodad->discard_changes;

   like(
      lives {
         $doodad->update( { note => 'This is a note' });
      },
      1,
      'Able to update non-enumerated field correctly.'
   );
};

exit;

