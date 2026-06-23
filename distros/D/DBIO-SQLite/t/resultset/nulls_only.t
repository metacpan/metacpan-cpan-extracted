use strict;
use warnings;

use Test::More;
use DBIO::SQLite::Test;
my $schema = DBIO::SQLite::Test->init_schema();


my $cd_rs = $schema->resultset('CD')->search ({ genreid => undef }, { columns => [ 'genreid' ]} );
my $count = $cd_rs->count;
cmp_ok ( $count, '>', 1, 'several CDs with no genre');

my @objects = $cd_rs->all;
is (scalar @objects, $count, 'Correct amount of objects without limit');
isa_ok ($_, 'DBIO::Test::CD') for @objects;

is_deeply (
  [ map { values %{{$_->get_columns}} } (@objects) ],
  [ (undef) x $count ],
  'All values are indeed undef'
);


isa_ok ($cd_rs->search ({}, { rows => 1 })->single, 'DBIO::Test::CD');

done_testing;
