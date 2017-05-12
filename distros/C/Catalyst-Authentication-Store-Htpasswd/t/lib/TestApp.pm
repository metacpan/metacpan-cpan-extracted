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
                    password_type  => 'self_check',
                },
                store => {
                    class => 'Htpasswd',
                    file => 'htpasswd',
                },
            },
        },
    },   
);

__PACKAGE__->setup;

1;
