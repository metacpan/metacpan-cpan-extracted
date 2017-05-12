package TestApp;
use strict;
use warnings;

use Catalyst qw/
    Authentication
/;

__PACKAGE__->config(
    authentication => {
        default_realm => 'test',
        realms => {
            test => {
                credential => {
                    class          => 'Password',
                    password_field => 'password',
                    password_type  => 'clear',
                },
                store => {
                    class => 'Tangram',
                    tangram_user_class => 'Users',
                    use_roles => 1,
                    role_relation => 'groups',
                    role_name_field => 'name',
                },
            },
        },
    },   
);

__PACKAGE__->setup;

1;
