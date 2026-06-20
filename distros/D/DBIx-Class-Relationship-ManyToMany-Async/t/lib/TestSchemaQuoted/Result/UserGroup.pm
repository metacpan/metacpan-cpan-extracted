package TestSchemaQuoted::Result::UserGroup;
use base 'DBIx::Class::Core';
__PACKAGE__->table('user_group');
__PACKAGE__->add_columns(
    id       => { data_type => 'integer', is_auto_increment => 1 },
    user_id  => { data_type => 'integer' },
    group_id => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->belongs_to('user', 'TestSchemaQuoted::Result::User', { 'foreign.id' => 'self.user_id' });
__PACKAGE__->belongs_to('group', 'TestSchemaQuoted::Result::Group', { 'foreign.id' => 'self.group_id' });
1;
