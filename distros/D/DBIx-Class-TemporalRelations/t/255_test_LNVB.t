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
   plan(1);
   subtest 'Test temporal relation to get single result' => sub {
      plan(2);
      my $human        = Human->find(1);
      my $contraption = $human->last_contraption_purchased_before('2022-01-01 00:00:00');
      is( ref $contraption, 'TestSchema::Result::Contraption',
         'ResultSet is returned in scalar mode.' );
      is( $contraption->color, 'Black', 'Correct result was fetched' );
   };
};

subtest 'Created via single insert' => sub {
   plan(1);
   subtest 'Test temporal relation to get single result' => sub {
      plan(2);
      my $human   = Human->find(1);
      my $doodad = $human->last_doodad_created_before('2022-01-01 00:00:00');
      is( ref $doodad, 'TestSchema::Result::Doodad', 'ResultSet is returned in scalar mode.' );
      is( $doodad->description, 'That Doodad', 'Correct result was fetched' );
   };
};

subtest 'Created via group insert, no overrides' => sub {
   plan(1);
   subtest 'Test temporal relation to get single result' => sub {
      plan(2);
      my $human   = Human->find(1);
      my $doodad = $human->last_doodad_modified_before('2022-01-01 00:00:00');
      is( ref $doodad, 'TestSchema::Result::Doodad', 'ResultSet is returned in scalar mode.' );
      is( $doodad->description, 'This Doodad', 'Correct result was fetched' );
   };
};

subtest 'Created via group insert, singular noun override' => sub {
   plan(1);
   subtest 'Test temporal relation to get single result' => sub {
      plan(2);
      my $human   = Human->find(2);
      my $doohickey = $human->last_doohickey_modified_before('2022-01-01 00:00:00');
      is( ref $doohickey, 'TestSchema::Result::Doohickey', 'ResultSet is returned in scalar mode.' );
      is( $doohickey->make, 'One', 'Result is correct' );
   };
};

subtest 'Created via group insert, singular & plural noun override' => sub {
   plan(1);
   subtest 'Test temporal relation via ResultSet' => sub {
      plan(2);
      my $human   = Human->find(2);
      my $doohickey = $human->last_doohickey_purchased_before('2022-01-01 00:00:00');
      is( ref $doohickey, 'TestSchema::Result::Doohickey', 'ResultSet is returned in scalar mode.' );
      is( $doohickey->make, 'Two', 'Result is correct' );
   };
};

exit;

