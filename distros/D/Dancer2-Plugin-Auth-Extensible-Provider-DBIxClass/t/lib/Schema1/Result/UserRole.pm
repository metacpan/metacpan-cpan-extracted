package Schema1::Result::UserRole;
use Modern::Perl;
use base qw/DBIx::Class::Core/;
__PACKAGE__->table('user_role');
__PACKAGE__->add_columns(
    user_id  => { data_type => 'integer' },
    role_id  => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key('user_id', 'role_id');
__PACKAGE__->belongs_to(user => 'Schema1::Result::User', 'user_id');
__PACKAGE__->belongs_to(role => 'Schema1::Result::Role', 'role_id');
1;
