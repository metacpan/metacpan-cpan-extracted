use Test2::V0;
use Test2::Plugin::Times;
use Test2::Plugin::ExitSummary;
use Test2::Plugin::NoWarnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib 't/lib';

plan(2);

use Test::DBIx::Class { schema_class => 'TestSchema' }, 'Contraption', 'Doodad', 'Doohickey';

subtest 'insert for pseudo-enum created via direct injection' => sub {
   plan(5);
   my $contraption_rs;
   like(
      lives {
         $contraption_rs = Contraption->create( { id => 1, color => 'blue', status => 'Sold' } )
      },
      1,
      'Able to create with a valid value'
   );
   my $contraption = Contraption->find(1);
   is( $contraption->status, 'Sold', 'properly round-tripped an insert.' );

   like(
      dies {
         $contraption_rs =
             Contraption->create( { id => 2, color => 'blue', status => 'Junked' } )
      },
      qr/You have attempted to assign a value to status that is not valid:/,
      'Unable to create with an invalid value'
   );

   like(
      lives {
         $contraption_rs = Contraption->create( { id => 3, color => 'blue', status => undef } )
      },
      1,
      'Able to create with a null value'
   );
   $contraption = Contraption->find(3);
   is( $contraption->status, undef, 'properly round-tripped an insert with null status.' );

};

subtest 'insert for pseudo-enum created via enumerate' => sub {
   plan(4);
   my $doodad_rs;
   like(
      lives {
         $doodad_rs = Doodad->create( { id => 1, color => 'Blue', status => 'In-Stock' } )
      },
      1,
      'Able to create with a valid value'
   );
   my $doodad = Doodad->find(1);
   is( $doodad->status, 'In-Stock', 'properly round-tripped an insert.' );

   like(
      dies {
         $doodad_rs =
             Doodad->create( { id => 2, color => 'blue', status => 'In-Stock' } )
      },
      qr/You have attempted to assign a value to color that is not valid:/,
      'Unable to create with an invalid value'
   );

   like(
      dies {
         $doodad_rs = Doodad->create( { id => 3, color => 'Blue', status => undef } )
      },
      qr/NOT NULL constraint failed/,
      'Unable to create with a null value in a non-nullable field'
   );
};

exit;

