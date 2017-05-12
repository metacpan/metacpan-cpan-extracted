use utf8;

package AproJo::DB::Schema::Result::Order;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('orders');

__PACKAGE__->add_columns(
  'order_id',
  {data_type => 'integer', is_auto_increment => 1, is_nullable => 0},
  'type',
  {data_type => 'varchar', is_nullable => 0, size => 30},
  'customer_order_id',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'order_date',
  {
    data_type                 => 'date',
    datetime_undef_if_invalid => 1,
    default_value             => '1900-01-01',
    is_nullable               => 0,
  },
  'delivery_date',
  {
    data_type                 => 'date',
    datetime_undef_if_invalid => 1,
    default_value             => '1900-01-01',
    is_nullable               => 0,
  },
  'currency',
  {
    data_type     => 'varchar',
    default_value => 'EUR',
    is_nullable   => 0,
    size          => 10
  },
  'payment',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 255},
  'terms_and_conditions',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 255},
  'partial_shipment_allowed',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 255},
  'transport',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 255},
  'remark',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 255},
);

__PACKAGE__->set_primary_key('order_id');

__PACKAGE__->has_many('orderitems', 'AproJo::DB::Schema::Result::Orderitem',
  'order_id');

1;
