package Test::Schema::Result::User;

use parent qw/DBIx::Class::Core/;

__PACKAGE__->table("users");

__PACKAGE__->add_columns(
    id => {
        data_type         => "integer",
        is_auto_increment => 1,
        is_nullable       => 0,
    },
    user_name => {
        accessor    => 'userName',
        data_type   => "varchar",
        is_nullable => 1,
        size        => 255
    },
    pass_word => {
        accessor    => 'passWord',
        data_type   => "varchar",
        is_nullable => 1,
        size        => 255
    },
);

__PACKAGE__->set_primary_key("id");

1;
