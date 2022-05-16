use Test2::V0;
use Test2::Plugin::Times;
use Test2::Plugin::ExitSummary;
use Test2::Plugin::NoWarnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib 't/lib';

plan(6);

use Test::DBIx::Class { schema_class => 'TestSchema' }, 'Human', 'Contraption';

fixtures_ok [
   Human =>
       [ [ 'id', 'name' ], [ '1', 'D Ruth Holloway' ], [ '2', 'Henry Hound-Dog Holloway' ], ],
   Contraption => [
      [ 'id', 'purchased_by', 'purchase_dt',         'color', 'height', 'where_purchased' ],
      [ '1',  '1',            '2021-01-12 15:30:00', 'Brown', '12',     'Contrapto-Mart' ],
      [ '2',  '2',            '2021-01-12 15:40:00', 'White', '12',     'Contrapto-Mart' ],
      [ '3',  '1',            '2021-01-13 13:00:00', 'Black', '16',     'Shop.Contrapts.Com' ],
   ],
   Doodad => [
      [ 'id', 'description',    'created_dt', 'created_by', 'modified_dt', 'modified_by' ],
      [ '1',  'This Doodad',    '2021-01-11 13:00:00', '1', '2021-01-14 09:30:00', '1' ],
      [ '2',  'That Doodad',    '2021-01-11 13:06:00', '1', undef,                 undef ],
      [ '3',  'Another Doodad', '2021-01-13 08:00:00', '2', '2021-01-14 08:00:00', '1' ],
   ],
   Doohickey => [
      [ 'id', 'model', 'make', 'purchased_by', 'purchase_dt',   'modified_by', 'modified_dt' ],
      [ '1',  'DoohickeyCo', 'One', '1', '2021-01-12 16:30:00', '2',   '2021-01-14 08:20:00' ],
      [ '2',  'DoohickeyCo', 'Two', '2', '2021-01-14 08:15:00', undef, undef ],
   ],
    ],
    'Installed fixtures';

subtest 'Created via direct injection' => sub {
   plan(2);
   subtest 'Test temporal relation via ResultSet' => sub {
      plan(3);
      my $human        = Human->find(1);
      my $contraptions = $human->contraptions_purchased;
      is( ref $contraptions, 'DBIx::Class::ResultSet',
         'ResultSet is returned in scalar mode.' );
      is( $contraptions->count(),      2,       'Test returns correct number of results' );
      is( $contraptions->first->color, 'Brown', 'Results are in correct order' );
   };

   subtest 'Test temporal relation via array' => sub {
      plan(3);
      my $human        = Human->find(1);
      my @contraptions = $human->contraptions_purchased;
      is( scalar @contraptions, 2, 'Test returns correct number of results' );
      is(
         ref $contraptions[0],
         'TestSchema::Result::Contraption',
         'Array contains Row objects'
      );
      is( $contraptions[0]->color, 'Brown', 'Results are in correct order' );
   };
};

subtest 'Created via single insert' => sub {
   plan(2);
   subtest 'Test temporal relation via ResultSet' => sub {
      plan(3);
      my $human   = Human->find(1);
      my $doodads = $human->doodads_created;
      is( ref $doodads, 'DBIx::Class::ResultSet', 'ResultSet is returned in scalar mode.' );
      is( $doodads->count(),            2,        'Test returns correct number of results' );
      is( $doodads->first->description, 'This Doodad', 'Results are in correct order' );
   };

   subtest 'Test temporal relation via array' => sub {
      plan(3);
      my $human   = Human->find(1);
      my @doodads = $human->doodads_created;
      is( scalar @doodads, 2, 'Test returns correct number of results' );
      is( ref $doodads[0], 'TestSchema::Result::Doodad', 'Array contains Row objects' );
      is( $doodads[0]->description, 'This Doodad',       'Results are in correct order' );
   };
};

subtest 'Created via group insert, no overrides' => sub {
   plan(2);
   subtest 'Test temporal relation via ResultSet' => sub {
      plan(3);
      my $human   = Human->find(1);
      my $doodads = $human->doodads_modified;
      is( ref $doodads, 'DBIx::Class::ResultSet', 'ResultSet is returned in scalar mode.' );
      is( $doodads->count(),            2,        'Test returns correct number of results' );
      is( $doodads->first->description, 'Another Doodad', 'Result is correct' );
   };

   subtest 'Test temporal relation via array' => sub {
      plan(3);
      my $human   = Human->find(1);
      my @doodads = $human->doodads_modified;
      is( scalar @doodads, 2, 'Test returns correct number of results' );
      is( ref $doodads[0], 'TestSchema::Result::Doodad', 'Array contains Row objects' );
      is( $doodads[0]->description, 'Another Doodad',    'Result is correct' );
   };
};

subtest 'Created via group insert, singular noun override' => sub {
   plan(2);
   subtest 'Test temporal relation via ResultSet' => sub {
      plan(3);
      my $human   = Human->find(2);
      my $doohickies = $human->doohickies_modified;
      is( ref $doohickies, 'DBIx::Class::ResultSet', 'ResultSet is returned in scalar mode.' );
      is( $doohickies->count(),            1,        'Test returns correct number of results' );
      is( $doohickies->first->make, 'One', 'Result is correct' );
   };

   subtest 'Test temporal relation via array' => sub {
      plan(3);
      my $human   = Human->find(2);
      my @doohickies = $human->doohickies_modified;
      is( scalar @doohickies, 1, 'Test returns correct number of results' );
      is( ref $doohickies[0], 'TestSchema::Result::Doohickey', 'Array contains Row objects' );
      is( $doohickies[0]->make, 'One',    'Result is correct' );
   };
};

subtest 'Created via group insert, singular & plural noun override' => sub {
   plan(2);
   subtest 'Test temporal relation via ResultSet' => sub {
      plan(3);
      my $human   = Human->find(2);
      my $doohickies = $human->doohickees_purchased;
      is( ref $doohickies, 'DBIx::Class::ResultSet', 'ResultSet is returned in scalar mode.' );
      is( $doohickies->count(),            1,        'Test returns correct number of results' );
      is( $doohickies->first->make, 'Two', 'Result is correct' );
   };

   subtest 'Test temporal relation via array' => sub {
      plan(3);
      my $human   = Human->find(2);
      my @doohickies = $human->doohickees_purchased;
      is( scalar @doohickies, 1, 'Test returns correct number of results' );
      is( ref $doohickies[0], 'TestSchema::Result::Doohickey', 'Array contains Row objects' );
      is( $doohickies[0]->make, 'Two',    'Result is correct' );
   };
};

exit;

