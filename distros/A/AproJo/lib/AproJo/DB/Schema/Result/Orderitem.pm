package AproJo::DB::Schema::Result::Orderitem;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('orderitems');

__PACKAGE__->add_columns(
  'orderitem_id',
  {data_type => 'integer', is_auto_increment => 1, is_nullable => 0},
  'order_id',
  {data_type => 'integer', is_nullable => 0, is_foreign_key => 1},
  'line_item_id',
  {data_type => 'integer', is_nullable => 0},
  'article_id',
  {data_type => 'integer', is_nullable => 0, is_foreign_key => 1},
  'quantity',
  {
    data_type     => 'decimal',
    default_value => '1.00',
    is_nullable   => 0,
    size          => [10, 2],
  },
  'unit_id',
  {
    data_type      => 'integer',
    default_value  => 1,
    is_nullable    => 0,
    is_foreign_key => 1
  },
  'article_price',
  {
    data_type     => 'decimal',
    default_value => '0.00',
    is_nullable   => 0,
    size          => [10, 2],
  },
  'delivery_date',
  {
    data_type                 => 'date',
    datetime_undef_if_invalid => 1,
    default_value             => '1900-01-01',
    is_nullable               => 0,
  },
  'partial_shipment_allowed',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 255},
  'transport',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 255},
  'remark',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 255},
);

__PACKAGE__->set_primary_key('orderitem_id');

__PACKAGE__->belongs_to('order', 'AproJo::DB::Schema::Result::Order',
  'order_id');
__PACKAGE__->belongs_to('article', 'AproJo::DB::Schema::Result::Article',
  'article_id');
__PACKAGE__->belongs_to('unit', 'AproJo::DB::Schema::Result::Unit', 'unit_id');

1;
