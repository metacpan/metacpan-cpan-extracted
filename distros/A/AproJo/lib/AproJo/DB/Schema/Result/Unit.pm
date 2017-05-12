package AproJo::DB::Schema::Result::Unit;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('units');

__PACKAGE__->add_columns(
  'unit_id',
  {data_type => 'integer', is_auto_increment => 1, is_nullable => 0},
  'description_short',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 50},
  'description_long',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 255},
);

__PACKAGE__->set_primary_key('unit_id');

__PACKAGE__->has_many(
  'articles' => 'AproJo::DB::Schema::Result::Article',
  'unit_id'
);
__PACKAGE__->has_many(
  'orderitems' => 'AproJo::DB::Schema::Result::Orderitem',
  'unit_id'
);

1;
