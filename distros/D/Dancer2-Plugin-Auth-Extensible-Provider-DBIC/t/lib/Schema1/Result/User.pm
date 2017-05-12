package t::lib::Schema1::Result::User;
use base qw/DBIx::Class::Core/;
__PACKAGE__->table('user');
__PACKAGE__->add_columns(
    id       => { data_type => 'integer' },
    username => { data_type => 'varchar', size => 32 },
    password => { data_type => 'varchar', size => 40, is_nullable => 1 },
    name     => { data_type => 'varchar', size => 128, is_nullable => 1 },
    email    => { data_type => 'varchar', size => 255, is_nullable => 1 },
    deleted  => { data_type => 'boolean', default_value => 0 },
    lastlogin => { data_type => 'datetime', is_nullable => 1 },
    pw_changed => { data_type => 'datetime', is_nullable => 1 },
    pw_reset_code => { data_type => 'varchar', size => 255, is_nullable => 1 },
);
__PACKAGE__->set_primary_key('id');
__PACKAGE__->add_unique_constraint(['username']);
__PACKAGE__->has_many(
    user_roles => "t::lib::Schema1::Result::UserRole",
    "user_id"
);
1;
