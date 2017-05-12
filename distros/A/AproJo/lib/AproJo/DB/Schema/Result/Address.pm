package AproJo::DB::Schema::Result::Address;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('addresses');

__PACKAGE__->add_columns(
  'address_id',
  {data_type => 'integer', is_auto_increment => 1, is_nullable => 0},
  'name',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 50},
  'name2',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'name3',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'department',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'contact_id',
  {data_type => 'integer', is_nullable => 0, is_foreign_key => 1},
  'street',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'zip',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 20},
  'boxno',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 20},
  'zipbox',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 20},
  'city',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 50},
  'state',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'country',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 6},
  'vat_id',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'phone',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'fax',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'email',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 100},
  'url',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 100},
);

__PACKAGE__->set_primary_key('address_id');

1;
