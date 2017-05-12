use utf8;

package AproJo::DB::Schema::Result::Contact;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('contacts');

__PACKAGE__->add_columns(
  'contact_id',
  {data_type => 'integer', is_auto_increment => 1, is_nullable => 0},
  'firstname',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'lastname',
  {data_type => 'varchar', default_value => '', is_nullable => 0, size => 50},
  'title',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'gender',
  {
    data_type     => 'varchar',
    default_value => 'male',
    is_nullable   => 0,
    size          => 10
  },
  'politeness',
  {
    data_type     => 'varchar',
    default_value => 'Sie',
    is_nullable   => 0,
    size          => 10
  },
  'phone',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'fax',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 50},
  'email',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 100},
  'url',
  {data_type => 'varchar', default_value => '', is_nullable => 1, size => 100},
);

__PACKAGE__->set_primary_key('contact_id');

1;
