package Schema2::Result::MyuserRole;
use Modern::Perl;
use base qw/DBIx::Class::Core/;
__PACKAGE__->table('myuser_role');
__PACKAGE__->add_columns(
    user_id  => { data_type => 'integer' },
    role_id  => { data_type => 'integer' },
);
__PACKAGE__->set_primary_key('user_id', 'role_id');
__PACKAGE__->belongs_to(myuser => 'Schema2::Result::Myuser', 'user_id');
__PACKAGE__->belongs_to(myrole => 'Schema2::Result::Myrole', 'role_id');
1;
