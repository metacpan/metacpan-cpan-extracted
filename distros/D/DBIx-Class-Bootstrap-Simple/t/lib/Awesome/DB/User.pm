package Awesome::DB::User;
use base 'DBIx::Class::Bootstrap::Simple';
use strict;

__PACKAGE__->init(
    table       => 'users',
    primary_key => 'user_id',
    definition  => [
        {
            key     => 'user_id',
            type    => 'INT(11)',
            special => 'AUTO_INCREMENT',
            null    => 0,
            primary => 1,
        },
        {
            key     => 'password_id',
            type    => 'INT(11)',
        },
        {
            key     => 'name',
            type    => 'VARHCAR(255)',
        },
    ],
    references  => {
        password => {
            class  => 'Awesome::DB::Password',
            column => 'password_id',
        },
    },
);

1;
