use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;
require DBIO::Test::DynamicForeignCols::TestComputer;

is_deeply (
  [ DBIO::Test::DynamicForeignCols::TestComputer->columns ],
  [qw( test_id computer_id )],
  'All columns properly defined from DBIO::Test::DynamicForeignCols::Computer parentclass'
);

done_testing;
