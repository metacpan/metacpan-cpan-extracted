use Test2::V0;
use Test2::Plugin::Times;
use Test2::Plugin::ExitSummary;
use Test2::Plugin::NoWarnings;
use FindBin qw($Bin);
use lib "$Bin/../lib";
use lib 't/lib';

plan(3);

use TestSchema;
my $schema = TestSchema->connect();
my $info   = $schema->source('Contraption')->source_info;
is(
   $info->{enumerations},
   { 'status' => [qw/Sold Packaged Shipped/] },
   'Enuemeration properly established via source_info injection'
);

$info = $schema->source('Doodad')->source_info;
is(
   $info->{enumerations},
   {
      'status' => [qw/Ordered In-Stock Out-Of-Stock/],
      'color'  => [qw/Black Blue Green Red/],
   },
   'Non-colliding enuemerations properly established using enumerate'
);

$info = $schema->source('Doohickey')->source_info;
is(
   $info->{enumerations},
   {
      'field1'             => [qw/One Two Three Four Blue/],
      'field2'             => [qw/BLUE RED GREEN/],
      '__use_column_names' => 1,
   },
   'Colliding enuemerations properly established using enumerate'
);

exit;
