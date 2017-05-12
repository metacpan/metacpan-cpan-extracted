package Awesome::DB::Password;
use base 'DBIx::Class::Bootstrap::Simple';
use strict;

__PACKAGE__->init(
    table       => 'passwords',
    primary_key => 'password_id',
    definition  => [
        {
            key     => 'password_id',
            type    => 'INT(11)',
            special => 'AUTO_INCREMENT',
            null    => 0,
            primary => 1,
        },
        {
            key     => 'user_id',
            type    => 'INT(11)',
        },
        {
            key     => 'password',
            type    => 'VARCHAR(255)',
        },
    ],
    references  => {
        user => {
            class  => 'Awesome::DB::User',
            column => 'user_id',
        },
    }
);


1;
