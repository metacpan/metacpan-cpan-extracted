package My::Schema::DataDictionary;
our $VERSION = '0.002';

use strict;
use warnings;
use DBICx::DataDictionary;

add_type PK => {
  data_type         => 'integer',
  is_nullable       => 0,
  is_auto_increment => 1,
};

add_type NAME => {
  data_type   => 'varchar',
  is_nullable => 0,
  size        => 100,
};

add_type SHORT_NAME => NAME(size => 40);

1;
