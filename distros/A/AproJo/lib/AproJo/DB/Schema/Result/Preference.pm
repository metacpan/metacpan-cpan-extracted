use utf8;

package AproJo::DB::Schema::Result::Preference;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('preferences');

__PACKAGE__->add_columns(
  'user_id',
  {data_type => 'integer', is_nullable => 0,is_foreign_key => 1},
  'name',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 255},
  'value',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 255},
);

__PACKAGE__->set_primary_key('user_id', 'name');

1;
