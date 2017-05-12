package AproJo::DB::Schema::Result::UserRole;

use strict;
use warnings;

use base 'DBIx::Class::Core';

__PACKAGE__->table('users_roles');

__PACKAGE__->add_columns(
  'user_id',
  {data_type => 'integer', is_nullable => 0, is_foreign_key => 1},
  'role_id',
  {data_type => 'integer', is_nullable => 0, is_foreign_key => 1},

);

__PACKAGE__->set_primary_key('user_id', 'role_id');

__PACKAGE__->belongs_to(
  'role_id',
  'AproJo::DB::Schema::Result::Role',
  {role_id       => 'role_id'},
  {is_deferrable => 1, on_delete => 'CASCADE', on_update => 'CASCADE'},
);

__PACKAGE__->belongs_to(
  'user_id',
  'AproJo::DB::Schema::Result::User',
  {user_id       => 'user_id'},
  {is_deferrable => 1, on_delete => 'CASCADE', on_update => 'CASCADE'},
);

1;
