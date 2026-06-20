package TestSchema::Result::User;
use base 'DBIx::Class::Core';
use DBIx::Class::Relationship::ManyToMany::Async;

__PACKAGE__->table('users');
__PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 255 },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    'user_group',
    'TestSchema::Result::UserGroup',
    'user_id',
);

__PACKAGE__->many_to_many_async('groups', 'user_group', 'grp');

1;
