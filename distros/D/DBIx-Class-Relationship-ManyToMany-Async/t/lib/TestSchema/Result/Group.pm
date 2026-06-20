package TestSchema::Result::Group;
use base 'DBIx::Class::Core';
use DBIx::Class::Relationship::ManyToMany::Async;

__PACKAGE__->table('groups');
__PACKAGE__->add_columns(
    id   => { data_type => 'integer', is_auto_increment => 1 },
    name => { data_type => 'varchar', size => 255 },
);
__PACKAGE__->set_primary_key('id');

__PACKAGE__->has_many(
    'user_group',
    'TestSchema::Result::UserGroup',
    'group_id',
);

__PACKAGE__->many_to_many_async('users', 'user_group', 'user');

1;
