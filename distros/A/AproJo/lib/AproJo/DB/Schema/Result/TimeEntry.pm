use utf8;

package AproJo::DB::Schema::Result::TimeEntry;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('time_entries');

__PACKAGE__->add_columns(
  'time_entry_id',
  {data_type => 'integer', is_auto_increment => 1, is_nullable => 0},
  'start',
  {
    data_type                 => 'datetime',
    datetime_undef_if_invalid => 1,
    default_value             => '1900-01-01 00:00:00',
    is_nullable               => 0,
  },
  'end',
  {
    data_type                 => 'datetime',
    datetime_undef_if_invalid => 1,
    default_value             => '1900-01-01 00:00:00',
    is_nullable               => 0,
  },
  'duration',
  {data_type => 'integer', default_value => 0, is_nullable => 0},
  'user_id',
  {data_type => 'integer', is_nullable => 0, is_foreign_key => 1},
  'order_id',
  {data_type => 'integer', is_nullable => 0, is_foreign_key => 1},
  'orderitem_id',
  {data_type => 'integer', is_nullable => 0, is_foreign_key => 1},
  'description',
  {data_type => 'text', default_value => '', is_nullable => 1},
  'comment',
  {data_type => 'text', default_value => '', is_nullable => 1},
  'comment_type',
  {data_type => 'tinyint', default_value => 0, is_nullable => 0},
  'cleared',
  {data_type => 'tinyint', default_value => 0, is_nullable => 0},
  'location',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'approved',
  {data_type => 'decimal', is_nullable => 1, size => [10, 2]},
  'status_id',
  {data_type => 'smallint', default_value => 0, is_nullable => 0, is_foreign_key => 1},
  'billable',
  {data_type => 'tinyint', default_value => 1, is_nullable => 1},
);

__PACKAGE__->set_primary_key('time_entry_id');

__PACKAGE__->has_one('orderitem', 'AproJo::DB::Schema::Result::Orderitem',
  'orderitem_id');

1;
