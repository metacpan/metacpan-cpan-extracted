package AproJo::DB::Schema::Result::Usertime;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('usertimes');

__PACKAGE__->add_columns(
  'usertimes_id',
  {data_type => 'integer', is_auto_increment => 1, is_nullable => 0},
  'user_id',
  {data_type => 'integer', is_nullable => 0, is_foreign_key => 1},
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
);

__PACKAGE__->set_primary_key('usertimes_id');

1;
