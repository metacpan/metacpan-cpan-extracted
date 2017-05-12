package AproJo::DB::Schema::Result::Article;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('articles');

__PACKAGE__->add_columns(
  'article_id',
  {data_type => 'integer', is_auto_increment => 1, is_nullable => 0},
  'description_short',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 50},
  'description_long',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 255},
  'unit_id',
  {
    data_type      => 'integer',
    default_value  => 1,
    is_nullable    => 0,
    is_foreign_key => 1
  },
  'price',
  {
    data_type     => 'decimal',
    default_value => '0.00',
    is_nullable   => 0,
    size          => [10, 2],
  },
  'timeable',
  {data_type => 'tinyint', default_value => 0, is_nullable => 1},
);

__PACKAGE__->set_primary_key('article_id');

__PACKAGE__->belongs_to(
  'unit' => 'AproJo::DB::Schema::Result::Unit',
  'unit_id'
);

1;
