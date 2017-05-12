#!perl

use strict;
use warnings;
use lib 't/tlib';
use Test::More;
use Test::Deep;

use My::Schema;

my $schema = My::Schema->connect;
my $source = $schema->source('Table');

cmp_deeply(
  $source->column_info('table_id'),
  { data_type         => 'integer',
    is_nullable       => 0,
    is_auto_increment => 1,
  },
  "Field 'table_id' expanded correctly"
);

cmp_deeply(
  $source->column_info('name'),
  { data_type   => 'varchar',
    is_nullable => 1,
    size        => 100,
  },
  "Field 'name' expanded correctly"
);

done_testing();
