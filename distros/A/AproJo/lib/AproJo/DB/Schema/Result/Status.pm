package AproJo::DB::Schema::Result::Status;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('statuses');

__PACKAGE__->add_columns(
  'status_id',
  {data_type => 'tinyint', is_auto_increment => 1, is_nullable => 0},
  'status',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 200},
);

__PACKAGE__->set_primary_key('status_id');

1;
