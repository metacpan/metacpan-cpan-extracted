package t::lib::Schema2::Result::Myrole;
use base qw/DBIx::Class::Core/;
__PACKAGE__->table('myrole');
__PACKAGE__->add_columns(
    id   => { data_type => 'integer' },
    rolename => { data_type => 'varchar', size => 32 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->has_many(
    myuser_roles => "t::lib::Schema2::Result::MyuserRole",
    "role_id"
);
1;
