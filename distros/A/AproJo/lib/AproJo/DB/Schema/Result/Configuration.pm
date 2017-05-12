use utf8;

package AproJo::DB::Schema::Result::Configuration;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('configuration');

__PACKAGE__->add_columns(
  'name',
  {data_type => 'varchar', is_nullable => 0, size => 255},
  'value',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 255},
);

__PACKAGE__->set_primary_key('name');

1;
