package AproJo::DB::Schema::Result::Group;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('groups');

__PACKAGE__->add_columns(
  'group_id',
  {data_type => 'integer', is_auto_increment => 1, is_nullable => 0},
  'name',
  {data_type => 'varchar', is_nullable => 0, size => 160},
  'trash',
  {data_type => 'tinyint', default_value => 0, is_nullable => 0},
);

__PACKAGE__->set_primary_key('group_id');

__PACKAGE__->has_many(
  'user_groups',
  'AproJo::DB::Schema::Result::UserGroup',
  {'foreign.group_id' => 'self.group_id'},
  {cascade_copy       => 0, cascade_delete => 0},
);

__PACKAGE__->many_to_many('user_ids', 'user_groups', 'user_id');

1;
